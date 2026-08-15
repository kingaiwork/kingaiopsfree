#!/bin/sh
set -eu

[ "$(uname -s)" = "Linux" ] || { echo "Linux is required" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)" >&2; exit 1; }

if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/kingaid.service ]; then
  systemctl disable --now kingaid.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/kingaid.service
  systemctl daemon-reload >/dev/null 2>&1 || true
fi

rm -f /usr/local/bin/kingai /usr/local/bin/kai /usr/local/bin/kingai.previous

cat <<'EOF'
KINGAI OPS binary/service removed.

Configuration, audit history and backups were intentionally preserved:
  /etc/kingaiops
  /var/lib/kingaiops
  /var/log/kingaiops

Delete those directories manually only after confirming the data is no longer required.
EOF
