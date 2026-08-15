#!/bin/sh
set -eu

REPO="kingaiwork/kingaiopsfree"
PREFIX="${KINGAI_PREFIX:-/usr/local}"
CONFIG_DIR="/etc/kingaiops"
DATA_DIR="/var/lib/kingaiops"
LOG_DIR="/var/log/kingaiops"
PREVIOUS_DIR="$DATA_DIR/previous"
TMP="${TMPDIR:-/tmp}/kingaiops-install-$$"
SKIP_SERVICE="${KINGAI_SKIP_SERVICE:-0}"

say(){ printf '%s\n' "[KINGAI OPS] $*"; }
warn(){ printf '%s\n' "[KINGAI OPS] WARNING: $*" >&2; }
die(){ printf '%s\n' "[KINGAI OPS] ERROR: $*" >&2; exit 1; }
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

[ "$(uname -s)" = "Linux" ] || die "Linux is required"
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"
umask 027
mkdir -p "$TMP"

fetch(){
  url="$1"; out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 --connect-timeout 15 --max-time 180 -fsSL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --timeout=30 "$url" -O "$out"
  else
    die "curl or wget is required"
  fi
}

hash_file(){
  file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$file" | awk '{print $NF}'
  else
    die "SHA-256 tool required: install sha256sum, shasum, or openssl"
  fi
}

healthcheck(){
  i=0
  while [ "$i" -lt 20 ]; do
    if command -v curl >/dev/null 2>&1; then
      if curl -fsS --max-time 2 http://127.0.0.1:17888/healthz >/dev/null 2>&1; then return 0; fi
    else
      if wget -q -T 2 -O - http://127.0.0.1:17888/healthz >/dev/null 2>&1; then return 0; fi
    fi
    i=$((i+1)); sleep 1
  done
  return 1
}

machine=$(uname -m)
case "$machine" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  i386|i486|i586|i686) arch="386" ;;
  armv7l|armv7*) arch="armv7" ;;
  ppc64le) arch="ppc64le" ;;
  s390x) arch="s390x" ;;
  riscv64) arch="riscv64" ;;
  *) die "no official KINGAI OPS binary is published for architecture: $machine" ;;
esac

asset="kingai-linux-${arch}"
base="https://github.com/${REPO}/releases/latest/download"

say "Downloading verified KINGAI OPS binary for ${arch}"
fetch "$base/$asset" "$TMP/$asset" || die "no published KINGAI OPS release is currently available for ${arch}"
fetch "$base/SHA256SUMS" "$TMP/SHA256SUMS" || die "release checksum manifest is unavailable"
expected=$(awk -v f="$asset" '$2==f {print $1}' "$TMP/SHA256SUMS" | head -n 1)
[ -n "$expected" ] || die "release checksum does not contain $asset"
actual=$(hash_file "$TMP/$asset")
[ "$expected" = "$actual" ] || die "SHA-256 verification failed; refusing installation"
chmod 0755 "$TMP/$asset"
"$TMP/$asset" version >/dev/null 2>&1 || die "downloaded binary failed self-check"

mkdir -p "$PREFIX/bin" "$CONFIG_DIR" "$DATA_DIR" "$DATA_DIR/backups" "$DATA_DIR/reports" "$PREVIOUS_DIR" "$LOG_DIR"
chmod 0750 "$CONFIG_DIR" "$DATA_DIR" "$DATA_DIR/backups" "$DATA_DIR/reports" "$PREVIOUS_DIR" "$LOG_DIR"

if [ ! -f "$CONFIG_DIR/config.json" ]; then
  cat > "$CONFIG_DIR/config.json" <<'JSON'
{
  "listen": "127.0.0.1:17888",
  "dataDir": "/var/lib/kingaiops",
  "auditLog": "/var/log/kingaiops/audit.jsonl",
  "backupDir": "/var/lib/kingaiops/backups",
  "adminFile": "/etc/kingaiops/admin.json",
  "sessionMinutes": 480,
  "pollSeconds": 30,
  "allowServiceRestart": false,
  "allowedServices": ["nginx", "caddy", "docker", "podman", "sshd", "ssh"],
  "allowContainerRestart": false,
  "allowedContainers": [],
  "allowLocalBackup": false
}
JSON
fi
chmod 0640 "$CONFIG_DIR/config.json"

had_previous=0
if [ -x "$PREFIX/bin/kingai" ]; then
  cp -f "$PREFIX/bin/kingai" "$PREVIOUS_DIR/kingai"
  chmod 0755 "$PREVIOUS_DIR/kingai"
  had_previous=1
fi
cp -f "$TMP/$asset" "$PREFIX/bin/.kingai.new.$$"
chmod 0755 "$PREFIX/bin/.kingai.new.$$"
mv -f "$PREFIX/bin/.kingai.new.$$" "$PREFIX/bin/kingai"
ln -sfn "$PREFIX/bin/kingai" "$PREFIX/bin/kai"

say "Creating or preserving the local administrator"
"$PREFIX/bin/kingai" admin bootstrap || {
  [ "$had_previous" -eq 1 ] && cp -f "$PREVIOUS_DIR/kingai" "$PREFIX/bin/kingai" && chmod 0755 "$PREFIX/bin/kingai"
  die "local administrator bootstrap failed"
}
[ ! -f "$CONFIG_DIR/admin.json" ] || chmod 0600 "$CONFIG_DIR/admin.json"

if [ ! -f "$DATA_DIR/baseline.json" ]; then
  say "Saving the first local configuration baseline"
  "$PREFIX/bin/kingai" baseline save --approve >/dev/null 2>&1 || warn "initial baseline could not be saved"
fi

say "Running the first VPS security assessment"
if "$PREFIX/bin/kingai" first-check; then
  say "First security report saved: $DATA_DIR/reports/first-security-check.json"
else
  warn "first security assessment did not complete; kingaid will retry it on first start"
fi

init="manual"
service_ok=1
if [ "$SKIP_SERVICE" = "1" ]; then
  say "KINGAI_SKIP_SERVICE=1; automatic service integration skipped"
elif command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
  cat > /etc/systemd/system/kingaid.service <<'UNIT'
[Unit]
Description=KINGAI OPS node daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/kingai daemon
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
ReadWritePaths=/var/lib/kingaiops /var/log/kingaiops
Environment=KINGAI_CONFIG=/etc/kingaiops/config.json

[Install]
WantedBy=multi-user.target
UNIT
  chmod 0644 /etc/systemd/system/kingaid.service
  systemctl daemon-reload
  systemctl enable kingaid.service >/dev/null 2>&1 || true
  if systemctl restart kingaid.service && systemctl is-active --quiet kingaid.service; then init="systemd"; else service_ok=0; init="systemd"; fi
elif command -v rc-service >/dev/null 2>&1 && command -v rc-update >/dev/null 2>&1; then
  cat > /etc/init.d/kingaid <<'OPENRC'
#!/sbin/openrc-run
name="kingaid"
description="KINGAI OPS node daemon"
command="/usr/local/bin/kingai"
command_args="daemon"
command_background="yes"
pidfile="/run/${RC_SVCNAME}.pid"
output_log="/var/log/kingaiops/daemon.log"
error_log="/var/log/kingaiops/daemon.log"
respawn_delay=3
respawn_max=0
start_pre(){ checkpath --directory --mode 0750 /var/lib/kingaiops; checkpath --directory --mode 0750 /var/log/kingaiops; }
depend(){ need localmount; use net; after firewall; }
OPENRC
  chmod 0755 /etc/init.d/kingaid
  rc-update add kingaid default >/dev/null 2>&1 || true
  if (rc-service kingaid restart || rc-service kingaid start) && rc-service kingaid status >/dev/null 2>&1; then init="openrc"; else service_ok=0; init="openrc"; fi
elif command -v sv >/dev/null 2>&1 && [ -d /etc/sv ]; then
  mkdir -p /etc/sv/kingaid
  cat > /etc/sv/kingaid/run <<'RUNIT'
#!/bin/sh
exec 2>&1
export KINGAI_CONFIG=/etc/kingaiops/config.json
exec /usr/local/bin/kingai daemon
RUNIT
  chmod 0755 /etc/sv/kingaid/run
  if [ -d /var/service ]; then ln -sfn /etc/sv/kingaid /var/service/kingaid; elif [ -d /etc/service ]; then ln -sfn /etc/sv/kingaid /etc/service/kingaid; fi
  if sv up kingaid >/dev/null 2>&1 && sv status kingaid >/dev/null 2>&1; then init="runit"; else service_ok=0; init="runit"; fi
else
  say "No supported service manager detected. KINGAI OPS is installed but not auto-started."
  say "Manual: KINGAI_CONFIG=/etc/kingaiops/config.json /usr/local/bin/kingai daemon"
fi

if [ "$service_ok" -eq 1 ] && [ "$init" != "manual" ] && [ "$SKIP_SERVICE" != "1" ]; then
  healthcheck || service_ok=0
fi

if [ "$service_ok" -ne 1 ]; then
  warn "new kingaid failed startup or health verification"
  if [ "$had_previous" -eq 1 ] && [ -x "$PREVIOUS_DIR/kingai" ]; then
    say "Rolling back to the previous KINGAI OPS binary"
    cp -f "$PREVIOUS_DIR/kingai" "$PREFIX/bin/.kingai.rollback.$$"
    chmod 0755 "$PREFIX/bin/.kingai.rollback.$$"
    mv -f "$PREFIX/bin/.kingai.rollback.$$" "$PREFIX/bin/kingai"
    case "$init" in
      systemd) systemctl restart kingaid.service >/dev/null 2>&1 || true ;;
      openrc) rc-service kingaid restart >/dev/null 2>&1 || true ;;
      runit) sv restart kingaid >/dev/null 2>&1 || true ;;
    esac
    die "deployment failed; previous binary restored"
  fi
  die "deployment failed to start the authenticated local console"
fi

say "Installation complete"
"$PREFIX/bin/kingai" version
say "Local Console: http://127.0.0.1:17888"
say "Remote-safe access: ssh -L 17888:127.0.0.1:17888 user@server"
say "Administrator hash: $CONFIG_DIR/admin.json (0600; no plaintext password)"
if [ -f "$DATA_DIR/initial-admin.txt" ]; then
  say "Initial login handoff: $DATA_DIR/initial-admin.txt (0600)"
  say "Read once with: sudo cat $DATA_DIR/initial-admin.txt"
fi
say "First security report: $DATA_DIR/reports/first-security-check.json"
say "Admin status: sudo kingai admin status"
say "Reset password: sudo kingai admin reset-password --approve"
