#!/bin/sh
set -eu

REPO="kingaiwork/kingaiopsfree"
TMP="${TMPDIR:-/tmp}/kingaiops-update-$$"
BIN="/usr/local/bin/kingai"
BACKUP="/usr/local/bin/kingai.previous"

say(){ printf '%s\n' "[KINGAI OPS] $*"; }
die(){ printf '%s\n' "[KINGAI OPS] ERROR: $*" >&2; exit 1; }
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

[ "$(uname -s)" = "Linux" ] || die "Linux is required"
[ "$(id -u)" -eq 0 ] || die "run as root (sudo)"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required"
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

case "$(uname -m)" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  i386|i486|i586|i686) arch="386" ;;
  armv7l|armv7*) arch="armv7" ;;
  ppc64le) arch="ppc64le" ;;
  s390x) arch="s390x" ;;
  riscv64) arch="riscv64" ;;
  *) die "unsupported release architecture" ;;
esac

asset="kingai-linux-${arch}"
base="https://github.com/${REPO}/releases/latest/download"
fetch "$base/$asset" "$TMP/$asset" || die "latest official binary is unavailable"
fetch "$base/SHA256SUMS" "$TMP/SHA256SUMS" || die "checksum manifest is unavailable"
expected=$(awk -v f="$asset" '$2==f {print $1}' "$TMP/SHA256SUMS" | head -n 1)
actual=$(sha256sum "$TMP/$asset" | awk '{print $1}')
[ -n "$expected" ] && [ "$expected" = "$actual" ] || die "SHA-256 verification failed"
chmod 0755 "$TMP/$asset"

if [ -x "$BIN" ]; then
  cp -p "$BIN" "$BACKUP"
fi
install -m 0755 "$TMP/$asset" "$BIN"

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files kingaid.service >/dev/null 2>&1; then
  if ! systemctl restart kingaid.service; then
    say "new binary failed to restart; restoring previous binary"
    [ -x "$BACKUP" ] && install -m 0755 "$BACKUP" "$BIN"
    systemctl restart kingaid.service >/dev/null 2>&1 || true
    die "update rolled back"
  fi
fi

if ! "$BIN" version >/dev/null 2>&1; then
  say "new binary health check failed; restoring previous binary"
  [ -x "$BACKUP" ] && install -m 0755 "$BACKUP" "$BIN"
  die "update rolled back"
fi

say "Update completed and verified"
"$BIN" version
