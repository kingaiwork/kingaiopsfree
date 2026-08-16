#!/bin/sh
set -eu

[ "$(uname -s)" = "Linux" ] || { echo "Linux is required" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)" >&2; exit 1; }

if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/kingaid.service ]; then
  systemctl disable --now kingaid.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/kingaid.service
  systemctl daemon-reload >/dev/null 2>&1 || true
fi

if [ -f /etc/init.d/kingaid ]; then
  if [ -x /sbin/procd ] && [ -f /etc/rc.common ]; then
    /etc/init.d/kingaid stop >/dev/null 2>&1 || true
    /etc/init.d/kingaid disable >/dev/null 2>&1 || true
  elif command -v rc-service >/dev/null 2>&1 && command -v rc-update >/dev/null 2>&1; then
    rc-service kingaid stop >/dev/null 2>&1 || true
    rc-update del kingaid default >/dev/null 2>&1 || true
  else
    if command -v service >/dev/null 2>&1; then service kingaid stop >/dev/null 2>&1 || true; else /etc/init.d/kingaid stop >/dev/null 2>&1 || true; fi
    if command -v update-rc.d >/dev/null 2>&1; then update-rc.d -f kingaid remove >/dev/null 2>&1 || true; fi
    if command -v chkconfig >/dev/null 2>&1; then chkconfig kingaid off >/dev/null 2>&1 || true; chkconfig --del kingaid >/dev/null 2>&1 || true; fi
  fi
  rm -f /etc/init.d/kingaid
fi

if [ -d /etc/sv/kingaid ]; then
  if command -v sv >/dev/null 2>&1; then sv down kingaid >/dev/null 2>&1 || true; fi
  rm -f /var/service/kingaid /etc/service/kingaid 2>/dev/null || true
  rm -rf /etc/sv/kingaid
fi

rm -f /usr/local/bin/kingai /usr/local/bin/kai /usr/local/bin/kingai.previous

cat <<'EOF'
KINGAI OPS binary and managed service were removed.

Configuration and local operational history were intentionally preserved:
  /etc/kingaiops        # includes the local administrator hash and install metadata
  /var/lib/kingaiops    # baseline, first security report, backups, state
  /var/log/kingaiops    # audit and daemon logs

No plaintext password is stored in /etc/kingaiops/admin.json.
Delete these directories manually only after confirming the data is no longer required.
EOF
