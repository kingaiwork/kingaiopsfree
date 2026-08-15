#!/bin/sh
set -eu

REPO="kingaiwork/kingaiopsfree"
PREFIX="${KINGAI_PREFIX:-/usr/local}"
CONFIG_DIR="/etc/kingaiops"
DATA_DIR="/var/lib/kingaiops"
LOG_DIR="/var/log/kingaiops"
TMP="${TMPDIR:-/tmp}/kingaiops-install-$$"

say(){ printf '%s\n' "[KINGAI OPS] $*"; }
die(){ printf '%s\n' "[KINGAI OPS] ERROR: $*" >&2; exit 1; }
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

[ "$(uname -s)" = "Linux" ] || die "Linux is required"
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"

mkdir -p "$TMP"

fetch(){
  url="$1"; out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$out"
  else
    die "curl or wget is required"
  fi
}

command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required for verified installation"

machine=$(uname -m)
case "$machine" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  i386|i486|i586|i686) arch="386" ;;
  armv7l|armv7*) arch="armv7" ;;
  ppc64le) arch="ppc64le" ;;
  s390x) arch="s390x" ;;
  riscv64) arch="riscv64" ;;
  *) die "no official KINGAI OPS Free binary is published for architecture: $machine" ;;
esac

asset="kingai-linux-${arch}"
base="https://github.com/${REPO}/releases/latest/download"

say "Downloading official KINGAI OPS Free binary for ${arch}"
fetch "$base/$asset" "$TMP/$asset" || die "no published release is available yet for ${arch}"
fetch "$base/SHA256SUMS" "$TMP/SHA256SUMS" || die "release checksum manifest is unavailable"

expected=$(awk -v f="$asset" '$2==f {print $1}' "$TMP/SHA256SUMS" | head -n 1)
[ -n "$expected" ] || die "release checksum does not contain $asset"
actual=$(sha256sum "$TMP/$asset" | awk '{print $1}')
[ "$expected" = "$actual" ] || die "SHA-256 verification failed; refusing installation"

chmod 0755 "$TMP/$asset"
install -m 0755 "$TMP/$asset" "$PREFIX/bin/kingai"
ln -sf "$PREFIX/bin/kingai" "$PREFIX/bin/kai"

mkdir -p "$CONFIG_DIR" "$DATA_DIR/backups" "$LOG_DIR"
chmod 0750 "$CONFIG_DIR" "$DATA_DIR" "$DATA_DIR/backups" "$LOG_DIR"

if [ ! -f "$CONFIG_DIR/config.json" ]; then
  cat > "$CONFIG_DIR/config.json" <<'JSON'
{
  "listen": "127.0.0.1:17888",
  "dataDir": "/var/lib/kingaiops",
  "auditLog": "/var/log/kingaiops/audit.jsonl",
  "backupDir": "/var/lib/kingaiops/backups",
  "pollSeconds": 30,
  "allowServiceRestart": false,
  "allowedServices": [],
  "allowContainerRestart": false,
  "allowedContainers": [],
  "allowLocalBackup": false
}
JSON
  chmod 0640 "$CONFIG_DIR/config.json"
fi

init="manual"
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
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
  systemctl daemon-reload
  systemctl enable --now kingaid.service
  init="systemd"
elif command -v rc-service >/dev/null 2>&1; then
  say "OpenRC detected. Follow docs/INSTALL.md for the current OpenRC service file."
  init="openrc-manual"
elif command -v sv >/dev/null 2>&1; then
  say "runit detected. Follow docs/INSTALL.md for the current runit service file."
  init="runit-manual"
fi

say "Installation complete"
say "Binary: $PREFIX/bin/kingai"
say "Config: $CONFIG_DIR/config.json"
say "Service integration: $init"
say "Run: kingai doctor"
say "Local Console: http://127.0.0.1:17888"
say "Remote-safe access: ssh -L 17888:127.0.0.1:17888 user@server"
