# KINGAI OPS Free/Core — Installation & Deployment

KINGAI OPS Free/Core is distributed as a **prebuilt proprietary Linux binary**. This public repository contains the installer, updater, documentation and binary-release metadata, but not the proprietary core source.

## One-command install

When an official binary Release is available in this repository:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh
```

The installer fails closed if it cannot download and verify a matching official binary and checksum.

## What the first deployment does

A normal first install performs these steps in order:

```text
Detect Linux/architecture
  ↓
Download binary + SHA256SUMS
  ↓
Verify SHA-256 + binary self-check
  ↓
Create protected local state/config directories
  ↓
Install kingai / kai atomically
  ↓
Create local administrator if one does not already exist
  ↓
Save first configuration baseline
  ↓
Run first VPS security assessment
  ↓
Install systemd / OpenRC / runit integration when available
  ↓
Start kingaid
  ↓
Verify http://127.0.0.1:17888/healthz
  ↓
Rollback previous binary if managed startup/health verification fails
```

Existing installations are treated idempotently: an existing administrator password is **not** silently changed.

## Local administrator and login information

The first local account defaults to:

```text
Username: admin
Password: cryptographically random, generated during installation
```

On an interactive SSH/terminal install, the generated password is printed **once**. Save it at that time.

The persistent administrator file is:

```text
/etc/kingaiops/admin.json
```

It is mode `0600` and contains only a salted password verifier, not the plaintext password. KINGAI OPS rejects symbolic-link credential files and credential files with group/world permissions.

For non-interactive installs such as cloud-init, where printing a one-time password to a human terminal is not reliable, the handoff is written temporarily to:

```text
/var/lib/kingaiops/initial-admin.txt
```

The file is mode `0600`, root-only, and is automatically removed after the first successful Console login. Read it with:

```bash
sudo cat /var/lib/kingaiops/initial-admin.txt
```

Administrator status:

```bash
sudo kingai admin status
```

Reset the local password:

```bash
sudo kingai admin reset-password --approve
```

A password reset invalidates existing in-memory Console sessions.

## First VPS security assessment

The installer runs:

```bash
sudo kingai first-check
```

and saves the first local report at:

```text
/var/lib/kingaiops/reports/first-security-check.json
```

The assessment combines the available host signals, including:

- Linux/kernel/architecture and node inventory;
- CPU, memory, load and disk health;
- init/service readiness;
- SSH/access posture;
- firewall state;
- listening-port exposure;
- package/update visibility;
- web configuration validation when Nginx/Caddy is present;
- local Security Center posture;
- baseline/drift state;
- audit/filesystem readiness;
- optional runtime-security sensor discovery.

The report is intentionally local and may include hostnames, private IP addresses, service names and exposed ports. Review it before sharing.

The local Overview also surfaces the first-check status and scores after authentication.

## Local Console

Default:

```text
http://127.0.0.1:17888
```

The Console is **authenticated and loopback-only by default**. Direct requests to `/api/v1/*` also require a valid local administrator session; hiding the UI is not the security boundary.

For remote-safe local administration, create an SSH tunnel:

```bash
ssh -L 17888:127.0.0.1:17888 user@server
```

Then open on your own computer:

```text
http://127.0.0.1:17888
```

No generic public management port is required.

## Authentication safeguards

The current local authority baseline includes:

- random initial administrator password;
- salted PBKDF2-HMAC-SHA256 password verifier;
- protected `0600` credential file;
- rejection of symlink/broad-permission credential files;
- `HttpOnly` local session cookie;
- `SameSite=Strict` session policy;
- random 256-bit session tokens with only token digests kept in daemon memory;
- brute-force lockout after repeated failed logins;
- sessions invalidated by daemon restart or password reset;
- login/logout audit events without password contents;
- request-size and content-type checks on login;
- loopback Host and source-address enforcement.

The local Console uses HTTP because it is bound to loopback and is intended to be carried through SSH tunneling for remote access. Deployments that add their own local TLS termination can use Secure cookies automatically when HTTPS reaches `kingaid` directly.

## Supported release architectures

The production build currently validates these primary release architectures:

```text
kingai-linux-amd64
kingai-linux-arm64
kingai-linux-386
kingai-linux-armv7
kingai-linux-ppc64le
kingai-linux-s390x
kingai-linux-riscv64
```

Additional architectures can be added when they pass the same static-build and runtime qualification gates. Architecture availability is separate from Linux-distribution compatibility.

## Linux compatibility model

KINGAI OPS uses capability detection rather than a narrow distro-version allowlist. Primary automatic paths cover:

- Debian / Ubuntu and derivatives;
- Fedora / RHEL / Rocky / Alma and derivatives;
- openSUSE / SUSE;
- Arch / Manjaro;
- Alpine;
- Void;
- other Linux systems when the required kernel/procfs capabilities are present.

Automatic service integration currently covers:

```text
systemd
OpenRC
runit
```

If another/custom init system is detected, installation can still complete without opening a public port; run the daemon manually or provide the platform-native service wrapper:

```bash
KINGAI_CONFIG=/etc/kingaiops/config.json /usr/local/bin/kingai daemon
```

Immutable/atomic distributions, NixOS, embedded appliances and heavily customized systems may require platform-native integration. KINGAI OPS should degrade safely rather than claim identical mutation support on every Linux variant.

## Verification model

The installer downloads:

```text
kingai-linux-<arch>
SHA256SUMS
```

and verifies SHA-256 before installation. It also performs a binary self-check before replacing the active executable.

Future supply-chain hardening should add publisher signatures, SBOMs and provenance. SHA-256 provides integrity verification but is not, by itself, publisher-identity signing.

## Default local paths

```text
/usr/local/bin/kingai
/usr/local/bin/kai
/etc/kingaiops/config.json
/etc/kingaiops/admin.json
/var/lib/kingaiops/baseline.json
/var/lib/kingaiops/reports/first-security-check.json
/var/lib/kingaiops/backups/
/var/log/kingaiops/audit.jsonl
```

## Safe mutation defaults

State-changing host operations remain disabled unless explicitly enabled in policy/configuration:

```json
{
  "listen": "127.0.0.1:17888",
  "adminFile": "/etc/kingaiops/admin.json",
  "sessionMinutes": 480,
  "allowServiceRestart": false,
  "allowContainerRestart": false,
  "allowLocalBackup": false
}
```

The local HTTP API remains read-only. Approved mutations are currently performed through typed CLI operations rather than a generic remote shell endpoint.

## Service-manager integration

### systemd

The installer applies a hardened service baseline including `NoNewPrivileges`, a private temporary directory, protected kernel/control-group settings and restricted writable paths for KINGAI OPS state/logs.

### OpenRC

The installer creates `/etc/init.d/kingaid`, enables it for the default runlevel and verifies service status.

### runit

The installer creates `/etc/sv/kingaid/run`, links it into the active service directory when present and verifies `sv status`.

## Updates

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/update.sh | sudo sh
```

The update flow is:

```text
Download → verify → stage → preserve old binary → migrate/admin-bootstrap if needed
→ first-check if missing → restart → health verify → rollback on failure
```

An older node that predates local Console authentication receives a new local administrator before the authenticated daemon is restarted. Existing administrators keep their current password.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/uninstall.sh | sudo sh
```

The uninstaller removes managed service definitions and binaries but deliberately preserves configuration, the local administrator hash, baseline, security report, audit history and backups until the operator explicitly deletes them.

## Production guidance

Before using any preview release on a critical server:

- confirm an independent backup/recovery path;
- keep provider/console access available;
- review firewall/SSH effects before changing access controls;
- validate application/database restore procedures;
- test upgrades on a non-critical node first.

Product/support contact: **vip@kingai.work**
