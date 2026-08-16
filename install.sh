#!/bin/sh
set -eu

REPO="${KINGAI_REPO:-kingaiwork/kingaiopsfree}"
PREFIX="${KINGAI_PREFIX:-/usr/local}"
CONFIG_DIR="${KINGAI_CONFIG_DIR:-/etc/kingaiops}"
DATA_DIR="${KINGAI_DATA_DIR:-/var/lib/kingaiops}"
LOG_DIR="${KINGAI_LOG_DIR:-/var/log/kingaiops}"
PREVIOUS_DIR="$DATA_DIR/previous"
TMP="${TMPDIR:-/tmp}/kingaiops-install-$$"

PROFILE="${KINGAI_PROFILE:-auto}"
CHANNEL="${KINGAI_CHANNEL:-stable}"
VERSION="${KINGAI_VERSION:-latest}"
FLEET_API="${KINGAI_FLEET_API:-https://api.kingai.work}"
ENROLL_TOKEN_FILE="${KINGAI_ENROLL_TOKEN_FILE:-}"
NODE_NAME="${KINGAI_NODE_NAME:-}"
NODE_ENV="${KINGAI_NODE_ENV:-production}"
NODE_PROVIDER="${KINGAI_NODE_PROVIDER:-}"
NODE_REGION="${KINGAI_NODE_REGION:-}"
SKIP_SERVICE="${KINGAI_SKIP_SERVICE:-0}"
FIRST_CHECK="${KINGAI_FIRST_CHECK:-1}"
DRY_RUN=0

say(){ printf '%s\n' "[KINGAI OPS] $*"; }
warn(){ printf '%s\n' "[KINGAI OPS] WARNING: $*" >&2; }
die(){ printf '%s\n' "[KINGAI OPS] ERROR: $*" >&2; exit 1; }
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

usage(){
  cat <<'USAGE'
KINGAI OPS Universal Bootstrap v2

Usage:
  curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh
  curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile edge
  curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile iot --version v0.9.1

Options:
  --profile auto|server|edge|iot|minimal
  --channel stable
  --version latest|vX.Y.Z
  --api https://api.kingai.work
  --enroll-token-file /root/kops-enroll.token
  --name NODE_NAME
  --environment production|staging|development|test|custom
  --provider PROVIDER
  --region REGION
  --no-service
  --no-first-check
  --dry-run
  -h, --help

Security:
  Fleet enrollment tokens are accepted only from a root-controlled file.
  The local console remains loopback-only by default.
  Host mutations remain disabled until explicitly approved by policy.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile) [ "$#" -ge 2 ] || die "--profile requires a value"; PROFILE="$2"; shift 2 ;;
    --channel) [ "$#" -ge 2 ] || die "--channel requires a value"; CHANNEL="$2"; shift 2 ;;
    --version) [ "$#" -ge 2 ] || die "--version requires a value"; VERSION="$2"; shift 2 ;;
    --api) [ "$#" -ge 2 ] || die "--api requires a value"; FLEET_API="$2"; shift 2 ;;
    --enroll-token-file) [ "$#" -ge 2 ] || die "--enroll-token-file requires a value"; ENROLL_TOKEN_FILE="$2"; shift 2 ;;
    --name) [ "$#" -ge 2 ] || die "--name requires a value"; NODE_NAME="$2"; shift 2 ;;
    --environment) [ "$#" -ge 2 ] || die "--environment requires a value"; NODE_ENV="$2"; shift 2 ;;
    --provider) [ "$#" -ge 2 ] || die "--provider requires a value"; NODE_PROVIDER="$2"; shift 2 ;;
    --region) [ "$#" -ge 2 ] || die "--region requires a value"; NODE_REGION="$2"; shift 2 ;;
    --no-service) SKIP_SERVICE=1; shift ;;
    --no-first-check) FIRST_CHECK=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

case "$CHANNEL" in stable) ;; *) die "unsupported release channel: $CHANNEL (supported: stable)" ;; esac
if [ "$VERSION" != "latest" ]; then printf '%s\n' "$VERSION" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$' || die "invalid --version: $VERSION"; fi
case "$NODE_ENV" in production|staging|development|test|custom) ;; *) die "invalid --environment: $NODE_ENV" ;; esac

[ "$(uname -s)" = "Linux" ] || die "Linux is required"

os_id="linux"
os_version=""
if [ -r /etc/os-release ]; then
  os_id=$(sed -n 's/^ID=//p' /etc/os-release | head -n1 | tr -d '"')
  os_version=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | head -n1 | tr -d '"')
elif [ -r /etc/openwrt_release ]; then
  os_id="openwrt"
fi
[ -n "$os_id" ] || os_id="linux"

machine=$(uname -m)
case "$machine" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  i386|i486|i586|i686) arch="386" ;;
  armv7l|armv7*) arch="armv7" ;;
  armv6l|armv6*) arch="armv6" ;;
  armv5l|armv5*) arch="armv5" ;;
  ppc64le) arch="ppc64le" ;;
  ppc64) arch="ppc64" ;;
  mips64el|mips64le) arch="mips64le" ;;
  mips64) arch="mips64" ;;
  mipsel|mipsle) arch="mipsle" ;;
  mips) arch="mips" ;;
  s390x) arch="s390x" ;;
  riscv64) arch="riscv64" ;;
  loongarch64|loong64) arch="loong64" ;;
  *) die "no official KINGAI OPS binary is published for architecture: $machine" ;;
esac

if [ "$PROFILE" = "auto" ]; then
  case "$os_id:$arch" in
    openwrt:*|lede:*|*:mips|*:mipsle|*:mips64|*:mips64le|*:armv5|*:armv6) PROFILE="iot" ;;
    alpine:arm*|alpine:riscv64) PROFILE="edge" ;;
    *) PROFILE="server" ;;
  esac
fi
case "$PROFILE" in server|edge|iot|minimal) ;; *) die "invalid --profile: $PROFILE" ;; esac

init="manual"
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
  init="systemd"
elif [ "$os_id" = "openwrt" ] || [ "$os_id" = "lede" ] || { [ -x /sbin/procd ] && [ -f /etc/rc.common ]; }; then
  init="procd"
elif command -v rc-service >/dev/null 2>&1 && command -v rc-update >/dev/null 2>&1; then
  init="openrc"
elif command -v sv >/dev/null 2>&1 && [ -d /etc/sv ]; then
  init="runit"
elif [ -d /etc/init.d ] && { command -v service >/dev/null 2>&1 || command -v update-rc.d >/dev/null 2>&1 || command -v chkconfig >/dev/null 2>&1; }; then
  init="sysvinit"
fi

say "Detected OS=${os_id}${os_version:+/$os_version} ARCH=$arch PROFILE=$PROFILE INIT=$init"
if [ "$DRY_RUN" = "1" ]; then say "Dry run complete; no files were changed."; exit 0; fi

[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"
umask 027
mkdir -p "$TMP"

fetch(){
  url="$1"; out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 --connect-timeout 15 --max-time 240 -fsSL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --timeout=45 "$url" -O "$out"
  else
    die "curl or wget is required"
  fi
}

hash_file(){
  file="$1"
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 "$file" | awk '{print $NF}'
  else die "SHA-256 tool required: install sha256sum, shasum, or openssl"
  fi
}

healthcheck(){
  i=0
  while [ "$i" -lt 30 ]; do
    if command -v curl >/dev/null 2>&1; then curl -fsS --max-time 2 http://127.0.0.1:17888/healthz >/dev/null 2>&1 && return 0
    elif command -v wget >/dev/null 2>&1; then wget -q -T 2 -O - http://127.0.0.1:17888/healthz >/dev/null 2>&1 && return 0
    else return 0
    fi
    i=$((i+1)); sleep 1
  done
  return 1
}

asset="kingai-linux-${arch}"
if [ "$VERSION" = "latest" ]; then base="https://github.com/${REPO}/releases/latest/download"; else base="https://github.com/${REPO}/releases/download/${VERSION}"; fi

say "Downloading verified KINGAI OPS ${VERSION} for linux/${arch}"
fetch "$base/$asset" "$TMP/$asset" || die "release binary unavailable for linux/${arch}"
fetch "$base/SHA256SUMS" "$TMP/SHA256SUMS" || die "release checksum manifest is unavailable"
expected=$(awk -v f="$asset" '$2==f {print $1}' "$TMP/SHA256SUMS" | head -n1)
[ -n "$expected" ] || die "release checksum does not contain $asset"
actual=$(hash_file "$TMP/$asset")
[ "$expected" = "$actual" ] || die "SHA-256 verification failed; refusing installation"
chmod 0755 "$TMP/$asset"
"$TMP/$asset" version >/dev/null 2>&1 || die "downloaded binary failed self-check"

install -d -m 0750 "$CONFIG_DIR" "$DATA_DIR" "$DATA_DIR/backups" "$DATA_DIR/reports" "$PREVIOUS_DIR" "$LOG_DIR"
mkdir -p "$PREFIX/bin"

if [ ! -f "$CONFIG_DIR/config.json" ]; then
  case "$PROFILE" in
    server) poll=30; session=480; services='"nginx", "caddy", "docker", "podman", "sshd", "ssh", "mariadb", "mysql", "postgresql", "redis"' ;;
    edge) poll=60; session=360; services='"nginx", "caddy", "docker", "podman", "sshd", "ssh"' ;;
    iot) poll=120; session=240; services='"docker", "podman", "dropbear", "sshd", "ssh"' ;;
    minimal) poll=120; session=240; services='"sshd", "ssh", "dropbear"' ;;
  esac
  cat > "$CONFIG_DIR/config.json" <<JSON
{
  "listen": "127.0.0.1:17888",
  "dataDir": "$DATA_DIR",
  "auditLog": "$LOG_DIR/audit.jsonl",
  "backupDir": "$DATA_DIR/backups",
  "adminFile": "$CONFIG_DIR/admin.json",
  "sessionMinutes": $session,
  "pollSeconds": $poll,
  "allowServiceRestart": false,
  "allowedServices": [$services],
  "allowContainerRestart": false,
  "allowedContainers": [],
  "allowLocalBackup": false,
  "allowLocalRestore": false,
  "allowedRestoreRoots": []
}
JSON
fi
chmod 0640 "$CONFIG_DIR/config.json"

cat > "$CONFIG_DIR/install-meta.json" <<JSON
{
  "schemaVersion": 2,
  "profile": "$PROFILE",
  "channel": "$CHANNEL",
  "requestedVersion": "$VERSION",
  "os": "$os_id",
  "osVersion": "$os_version",
  "architecture": "$arch",
  "init": "$init"
}
JSON
chmod 0640 "$CONFIG_DIR/install-meta.json"

had_previous=0
if [ -x "$PREFIX/bin/kingai" ]; then cp -f "$PREFIX/bin/kingai" "$PREVIOUS_DIR/kingai"; chmod 0755 "$PREVIOUS_DIR/kingai"; had_previous=1; fi
cp -f "$TMP/$asset" "$PREFIX/bin/.kingai.new.$$"
chmod 0755 "$PREFIX/bin/.kingai.new.$$"
mv -f "$PREFIX/bin/.kingai.new.$$" "$PREFIX/bin/kingai"
ln -sfn "$PREFIX/bin/kingai" "$PREFIX/bin/kai"

say "Creating or preserving the local administrator"
"$PREFIX/bin/kingai" admin bootstrap || {
  if [ "$had_previous" -eq 1 ]; then cp -f "$PREVIOUS_DIR/kingai" "$PREFIX/bin/kingai"; chmod 0755 "$PREFIX/bin/kingai"; fi
  die "local administrator bootstrap failed"
}
[ ! -f "$CONFIG_DIR/admin.json" ] || chmod 0600 "$CONFIG_DIR/admin.json"

if [ ! -f "$DATA_DIR/baseline.json" ]; then say "Saving the first local configuration baseline"; "$PREFIX/bin/kingai" baseline save --approve >/dev/null 2>&1 || warn "initial baseline could not be saved"; fi

if [ "$FIRST_CHECK" = "1" ]; then
  say "Running the first security assessment"
  if "$PREFIX/bin/kingai" first-check; then say "First security report saved: $DATA_DIR/reports/first-security-check.json"; else warn "first security assessment did not complete; kingaid will retry after start"; fi
fi

if [ -n "$ENROLL_TOKEN_FILE" ]; then
  [ -f "$ENROLL_TOKEN_FILE" ] || die "fleet enrollment token file not found: $ENROLL_TOKEN_FILE"
  say "Enrolling this node into the signed KINGAI OPS Fleet control plane"
  set -- fleet enroll --token-file "$ENROLL_TOKEN_FILE" --api "$FLEET_API" --environment "$NODE_ENV"
  [ -z "$NODE_NAME" ] || set -- "$@" --name "$NODE_NAME"
  [ -z "$NODE_PROVIDER" ] || set -- "$@" --provider "$NODE_PROVIDER"
  [ -z "$NODE_REGION" ] || set -- "$@" --region "$NODE_REGION"
  set -- "$@" --approve
  "$PREFIX/bin/kingai" "$@" || die "fleet enrollment failed; local installation remains available"
fi

service_ok=1
if [ "$SKIP_SERVICE" = "1" ]; then
  say "Automatic service integration skipped"
  init="manual"
elif [ "$init" = "systemd" ]; then
  cat > /etc/systemd/system/kingaid.service <<UNIT
[Unit]
Description=KINGAI OPS governed node agent
Documentation=https://ops.kingai.work/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$PREFIX/bin/kingai daemon
Restart=on-failure
RestartSec=3s
User=root
Group=root
UMask=0027
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=read-only
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
ReadWritePaths=$DATA_DIR $LOG_DIR
Environment=KINGAI_CONFIG=$CONFIG_DIR/config.json

[Install]
WantedBy=multi-user.target
UNIT
  chmod 0644 /etc/systemd/system/kingaid.service
  systemctl daemon-reload
  systemctl enable kingaid.service >/dev/null 2>&1 || true
  systemctl restart kingaid.service && systemctl is-active --quiet kingaid.service || service_ok=0
elif [ "$init" = "procd" ]; then
  cat > /etc/init.d/kingaid <<PROCD
#!/bin/sh /etc/rc.common
START=95
STOP=10
USE_PROCD=1
start_service() {
  procd_open_instance
  procd_set_param command $PREFIX/bin/kingai daemon
  procd_set_param env KINGAI_CONFIG=$CONFIG_DIR/config.json
  procd_set_param respawn 3600 5 5
  procd_set_param stdout 1
  procd_set_param stderr 1
  procd_close_instance
}
PROCD
  chmod 0755 /etc/init.d/kingaid
  /etc/init.d/kingaid enable >/dev/null 2>&1 || true
  /etc/init.d/kingaid restart || service_ok=0
elif [ "$init" = "openrc" ]; then
  cat > /etc/init.d/kingaid <<OPENRC
#!/sbin/openrc-run
name="kingaid"
description="KINGAI OPS governed node agent"
command="$PREFIX/bin/kingai"
command_args="daemon"
command_background="yes"
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="$LOG_DIR/daemon.log"
error_log="$LOG_DIR/daemon.log"
respawn_delay=3
respawn_max=0
export KINGAI_CONFIG="$CONFIG_DIR/config.json"
start_pre(){ checkpath --directory --mode 0750 "$DATA_DIR"; checkpath --directory --mode 0750 "$LOG_DIR"; }
depend(){ need localmount; use net; after firewall; }
OPENRC
  chmod 0755 /etc/init.d/kingaid
  rc-update add kingaid default >/dev/null 2>&1 || true
  (rc-service kingaid restart || rc-service kingaid start) && rc-service kingaid status >/dev/null 2>&1 || service_ok=0
elif [ "$init" = "runit" ]; then
  mkdir -p /etc/sv/kingaid
  cat > /etc/sv/kingaid/run <<RUNIT
#!/bin/sh
exec 2>&1
export KINGAI_CONFIG="$CONFIG_DIR/config.json"
exec "$PREFIX/bin/kingai" daemon
RUNIT
  chmod 0755 /etc/sv/kingaid/run
  if [ -d /var/service ]; then ln -sfn /etc/sv/kingaid /var/service/kingaid; elif [ -d /etc/service ]; then ln -sfn /etc/sv/kingaid /etc/service/kingaid; fi
  sv up kingaid >/dev/null 2>&1 && sv status kingaid >/dev/null 2>&1 || service_ok=0
elif [ "$init" = "sysvinit" ]; then
  cat > /etc/init.d/kingaid <<SYSV
#!/bin/sh
### BEGIN INIT INFO
# Provides: kingaid
# Required-Start: \$local_fs \$network
# Required-Stop: \$local_fs \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: KINGAI OPS governed node agent
### END INIT INFO
DAEMON="$PREFIX/bin/kingai"
PIDFILE=/var/run/kingaid.pid
LOGFILE="$LOG_DIR/daemon.log"
CONFIG="$CONFIG_DIR/config.json"
is_running(){ [ -r "\$PIDFILE" ] || return 1; pid=\$(cat "\$PIDFILE" 2>/dev/null || true); case "\$pid" in ''|*[!0-9]*) return 1;; esac; [ -r "/proc/\$pid/cmdline" ] || return 1; cmd=\$(tr '\\000' ' ' < "/proc/\$pid/cmdline" 2>/dev/null || true); case "\$cmd" in *"kingai daemon"*) return 0;; *) return 1;; esac; }
start_daemon(){ is_running && return 0; mkdir -p "$DATA_DIR" "$LOG_DIR"; chmod 0750 "$DATA_DIR" "$LOG_DIR"; umask 027; KINGAI_CONFIG="\$CONFIG" nohup "\$DAEMON" daemon >>"\$LOGFILE" 2>&1 </dev/null & echo \$! > "\$PIDFILE"; chmod 0600 "\$PIDFILE"; }
stop_daemon(){ if ! is_running; then rm -f "\$PIDFILE"; return 0; fi; pid=\$(cat "\$PIDFILE"); kill "\$pid" 2>/dev/null || true; i=0; while [ "\$i" -lt 10 ]; do if ! kill -0 "\$pid" 2>/dev/null; then rm -f "\$PIDFILE"; return 0; fi; i=\$((i+1)); sleep 1; done; kill -KILL "\$pid" 2>/dev/null || true; rm -f "\$PIDFILE"; }
case "\${1:-}" in start) start_daemon;; stop) stop_daemon;; restart) stop_daemon; start_daemon;; status) if is_running; then echo "kingaid is running"; exit 0; else echo "kingaid is stopped"; exit 3; fi;; *) echo "Usage: \$0 {start|stop|restart|status}" >&2; exit 2;; esac
SYSV
  chmod 0755 /etc/init.d/kingaid
  command -v update-rc.d >/dev/null 2>&1 && update-rc.d kingaid defaults >/dev/null 2>&1 || true
  if command -v chkconfig >/dev/null 2>&1; then chkconfig --add kingaid >/dev/null 2>&1 || true; chkconfig kingaid on >/dev/null 2>&1 || true; fi
  if command -v service >/dev/null 2>&1; then service kingaid restart || service_ok=0; else /etc/init.d/kingaid restart || service_ok=0; fi
else
  say "No supported service manager detected; install completed without auto-start."
  say "Manual: KINGAI_CONFIG=$CONFIG_DIR/config.json $PREFIX/bin/kingai daemon"
fi

if [ "$service_ok" -eq 1 ] && [ "$init" != "manual" ]; then healthcheck || service_ok=0; fi

if [ "$service_ok" -ne 1 ]; then
  warn "new kingaid failed startup or health verification"
  if [ "$had_previous" -eq 1 ] && [ -x "$PREVIOUS_DIR/kingai" ]; then
    say "Rolling back to the previous KINGAI OPS binary"
    cp -f "$PREVIOUS_DIR/kingai" "$PREFIX/bin/.kingai.rollback.$$"
    chmod 0755 "$PREFIX/bin/.kingai.rollback.$$"
    mv -f "$PREFIX/bin/.kingai.rollback.$$" "$PREFIX/bin/kingai"
    case "$init" in systemd) systemctl restart kingaid.service >/dev/null 2>&1 || true ;; procd) /etc/init.d/kingaid restart >/dev/null 2>&1 || true ;; openrc) rc-service kingaid restart >/dev/null 2>&1 || true ;; runit) sv restart kingaid >/dev/null 2>&1 || true ;; sysvinit) /etc/init.d/kingaid restart >/dev/null 2>&1 || true ;; esac
    die "deployment failed; previous binary restored"
  fi
  die "deployment failed to start kingaid"
fi

say "Installation complete"
"$PREFIX/bin/kingai" version
say "Profile: $PROFILE · OS: $os_id · Arch: $arch · Init: $init"
say "Local Console: http://127.0.0.1:17888"
say "Remote-safe access: ssh -L 17888:127.0.0.1:17888 user@server"
say "Fleet status: sudo kingai fleet status"
say "Health: sudo kingai health"
say "Readiness: sudo kingai readiness"
say "Security: sudo kingai security"
say "Update: curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/update.sh | sudo sh"
if [ -f "$DATA_DIR/initial-admin.txt" ]; then say "Initial login handoff: $DATA_DIR/initial-admin.txt (0600; read once)"; fi
