#!/bin/sh
set -eu

REPO="kingaiwork/kingaiopsfree"
TMP="${TMPDIR:-/tmp}/kingaiops-update-$$"
BIN="/usr/local/bin/kingai"
BACKUP="/var/lib/kingaiops/previous/kingai"
DATA_DIR="/var/lib/kingaiops"
CONFIG_DIR="/etc/kingaiops"

say(){ printf '%s\n' "[KINGAI OPS] $*"; }
warn(){ printf '%s\n' "[KINGAI OPS] WARNING: $*" >&2; }
die(){ printf '%s\n' "[KINGAI OPS] ERROR: $*" >&2; exit 1; }
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

[ "$(uname -s)" = "Linux" ] || die "Linux is required"
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"
umask 027
mkdir -p "$TMP" "$DATA_DIR/previous" "$DATA_DIR/reports" "$CONFIG_DIR"
chmod 0750 "$DATA_DIR" "$DATA_DIR/previous" "$DATA_DIR/reports" "$CONFIG_DIR" 2>/dev/null || true

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
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 "$file" | awk '{print $NF}'
  else die "SHA-256 tool required: install sha256sum, shasum, or openssl"; fi
}

healthcheck(){
  i=0
  while [ "$i" -lt 20 ]; do
    if command -v curl >/dev/null 2>&1; then
      curl -fsS --max-time 2 http://127.0.0.1:17888/healthz >/dev/null 2>&1 && return 0
    else
      wget -q -T 2 -O - http://127.0.0.1:17888/healthz >/dev/null 2>&1 && return 0
    fi
    i=$((i+1)); sleep 1
  done
  return 1
}

case "$(uname -m)" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  i386|i486|i586|i686) arch="386" ;;
  armv7l|armv7*) arch="armv7" ;;
  ppc64le) arch="ppc64le" ;;
  s390x) arch="s390x" ;;
  riscv64) arch="riscv64" ;;
  *) die "no official release is published for this architecture" ;;
esac

asset="kingai-linux-${arch}"
base="https://github.com/${REPO}/releases/latest/download"
fetch "$base/$asset" "$TMP/$asset" || die "latest official KINGAI OPS binary is unavailable"
fetch "$base/SHA256SUMS" "$TMP/SHA256SUMS" || die "checksum manifest is unavailable"
expected=$(awk -v f="$asset" '$2==f {print $1}' "$TMP/SHA256SUMS" | head -n 1)
[ -n "$expected" ] || die "checksum manifest does not contain $asset"
actual=$(hash_file "$TMP/$asset")
[ "$expected" = "$actual" ] || die "SHA-256 verification failed"
chmod 0755 "$TMP/$asset"
"$TMP/$asset" version >/dev/null 2>&1 || die "downloaded binary failed self-check"

had_previous=0
if [ -x "$BIN" ]; then
  cp -f "$BIN" "$BACKUP"
  chmod 0755 "$BACKUP"
  had_previous=1
fi

cp -f "$TMP/$asset" "$BIN.new.$$"
chmod 0755 "$BIN.new.$$"
mv -f "$BIN.new.$$" "$BIN"
ln -sfn "$BIN" /usr/local/bin/kai

# This is intentionally idempotent: existing local administrators keep their
# current password; older installations without an administrator get one before
# the new daemon is restarted.
if ! "$BIN" admin bootstrap; then
  if [ "$had_previous" -eq 1 ]; then cp -f "$BACKUP" "$BIN"; chmod 0755 "$BIN"; fi
  die "administrator migration failed; previous binary restored"
fi
[ ! -f "$CONFIG_DIR/admin.json" ] || chmod 0600 "$CONFIG_DIR/admin.json"

if [ ! -f "$DATA_DIR/baseline.json" ]; then
  "$BIN" baseline save --approve >/dev/null 2>&1 || warn "initial baseline could not be saved"
fi
if [ ! -f "$DATA_DIR/reports/first-security-check.json" ]; then
  "$BIN" first-check || warn "first VPS security check will be retried by kingaid"
fi

manager="manual"
restart_ok=1
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ] && systemctl list-unit-files kingaid.service >/dev/null 2>&1; then
  manager="systemd"
  systemctl restart kingaid.service || restart_ok=0
elif command -v rc-service >/dev/null 2>&1 && [ -x /etc/init.d/kingaid ]; then
  manager="openrc"
  rc-service kingaid restart || restart_ok=0
elif command -v sv >/dev/null 2>&1 && { [ -e /var/service/kingaid ] || [ -e /etc/service/kingaid ] || [ -d /etc/sv/kingaid ]; }; then
  manager="runit"
  sv restart kingaid >/dev/null 2>&1 || restart_ok=0
else
  warn "no managed kingaid service was detected; restart the daemon manually"
fi

if [ "$restart_ok" -eq 1 ] && [ "$manager" != "manual" ]; then
  healthcheck || restart_ok=0
fi

if [ "$restart_ok" -ne 1 ]; then
  say "New binary failed service or health verification"
  if [ "$had_previous" -eq 1 ] && [ -x "$BACKUP" ]; then
    cp -f "$BACKUP" "$BIN.rollback.$$"
    chmod 0755 "$BIN.rollback.$$"
    mv -f "$BIN.rollback.$$" "$BIN"
    case "$manager" in
      systemd) systemctl restart kingaid.service >/dev/null 2>&1 || true ;;
      openrc) rc-service kingaid restart >/dev/null 2>&1 || true ;;
      runit) sv restart kingaid >/dev/null 2>&1 || true ;;
    esac
    die "update rolled back to the previous binary"
  fi
  die "update failed and no previous binary was available"
fi

say "Update completed and verified"
"$BIN" version
say "Administrator status: sudo kingai admin status"
if [ -f "$DATA_DIR/initial-admin.txt" ]; then
  say "A local administrator was created for this upgraded node."
  say "Read the one-time handoff: sudo cat $DATA_DIR/initial-admin.txt"
fi
say "Local Console: http://127.0.0.1:17888"
say "First security report: $DATA_DIR/reports/first-security-check.json"
