# ✦ KINGAI OPS Free

## Autonomous Infrastructure Operations & Defense

**KINGAI OPS** is a proprietary Linux infrastructure operations platform for VPS, cloud servers, containers, websites, databases, backup, monitoring, security and progressively autonomous operations.

**KINGAI OPS Core is free to use. The source code is proprietary and is not open source.**

- Product: https://ops.kingai.work
- KINGAI account/API: https://kingai.work
- Commercial / MSP / enterprise / partnership: **vip@kingai.work**
- Current binary release: **v0.9.1**

---

## One-command install

The current authenticated first-deployment release is available now:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh
```

The installer fails closed if it cannot download and verify the official binary and `SHA256SUMS` for the detected architecture.

A normal first deployment performs:

```text
Detect Linux + architecture
  ↓
Download binary + SHA256SUMS
  ↓
Verify SHA-256 + binary self-check
  ↓
Install / preserve local configuration
  ↓
Create local administrator when missing
  ↓
Save first configuration baseline
  ↓
Run first VPS security assessment
  ↓
Start systemd / OpenRC / runit / SysV integration when supported
  ↓
Verify local /healthz
  ↓
Rollback the previous binary if managed startup fails
```

The installed Console remains on `127.0.0.1:17888` by default.

---

## First local administrator

Default username:

```text
admin
```

The password is generated cryptographically during first deployment.

On an interactive terminal it is displayed once. On non-interactive/cloud-init installation, the one-time handoff is stored temporarily at:

```text
/var/lib/kingaiops/initial-admin.txt
```

with mode `0600`. It is automatically removed after the first successful Console login.

Persistent local credentials are stored at:

```text
/etc/kingaiops/admin.json
```

The file contains a salted password verifier, not the plaintext password, and KINGAI OPS refuses unsafe symlink or group/world-readable credential files.

Useful commands:

```bash
sudo kingai admin status
sudo kingai admin reset-password --approve
```

---

## First VPS security assessment

First deployment automatically runs:

```bash
sudo kingai first-check
```

and stores the local report at:

```text
/var/lib/kingaiops/reports/first-security-check.json
```

The assessment combines available signals for:

- Linux/kernel/architecture;
- CPU, memory, load and storage health;
- service/init readiness;
- SSH/access posture;
- firewall state;
- listening ports;
- package/update visibility;
- TLS and web configuration where available;
- Security Center posture;
- configuration baseline/drift;
- audit/filesystem readiness;
- optional runtime-security sensors.

The report stays local and may contain hostnames, private IP addresses, services and exposed ports; review it before sharing.

---

## Current Linux compatibility

KINGAI OPS uses runtime capability detection rather than a narrow distribution-version allowlist.

Primary automatic paths include:

- Debian / Ubuntu and derivatives;
- Fedora / RHEL / Rocky / Alma and derivatives;
- openSUSE / SUSE;
- Arch / Manjaro;
- Alpine;
- Void;
- other Linux environments where the required kernel/procfs capabilities exist.

Service management currently includes:

- systemd;
- OpenRC;
- runit;
- SysV init;
- dinit service control when available.

s6, BusyBox init, immutable/atomic systems, NixOS, embedded appliances and heavily customized environments are detected conservatively and may use read-only/manual integration rather than guessed host mutations.

### Validated binary architectures

The v0.9.1 build pipeline produced and verified static Linux binaries for:

```text
amd64
arm64
386
armv7
armv6
ppc64
ppc64le
mips64le
s390x
riscv64
loong64
```

Architecture availability does not imply that every Linux distribution exposes identical service/package/security facilities. Unsupported capabilities degrade safely.

---

## KINGAI OPS Core — Free

The free edition is intended for individual developers, VPS owners, homelab users and small teams.

Current product foundation includes:

- authenticated local Console;
- server-side protection for local `/api/v1/*` data;
- Linux host inventory and health;
- CPU / memory / disk / load / uptime;
- service and process visibility;
- listening ports and network visibility;
- Docker / Podman visibility;
- Nginx / Caddy and website discovery;
- database/cache discovery;
- TLS certificate inventory;
- storage/mount visibility;
- SSH/access posture;
- nftables / UFW / firewalld / iptables visibility;
- package/update visibility;
- scheduled-job visibility;
- local backups;
- baseline and drift detection;
- first-deploy security report;
- audit trail;
- Security Center foundation;
- deterministic Core Mode without an external AI API key.

Capabilities are shipped progressively. See [`docs/FEATURES.md`](docs/FEATURES.md) for the public status model.

---

## Local-first security model

KINGAI OPS is designed so that a server can continue core local operations even when a cloud control plane or AI provider is unavailable.

Default local Console:

```text
http://127.0.0.1:17888
```

Recommended remote-safe access:

```bash
ssh -L 17888:127.0.0.1:17888 user@server
```

Then open `http://127.0.0.1:17888` on your own computer and sign in with the node-local administrator.

The product does not require a generic public `:8888`-style management port.

Local authentication currently includes random session tokens, HttpOnly cookies, SameSite=Strict, login lockout, local Host/source enforcement and password-reset session invalidation. AI/cloud access does not bypass node-local policy.

---

## Updates

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/update.sh | sudo sh
```

The updater downloads and verifies the latest release, preserves the current binary, migrates older installations by creating a local administrator only when missing, restarts the detected managed service, verifies health and restores the previous binary if the new service fails.

Existing administrator passwords are not silently reset.

---

## Free vs commercial editions

| Edition | Direction |
|---|---|
| **Core / Free** | authenticated local-first single-node management and security foundation |
| **Pro** | developers and small fleets, cloud coordination, advanced automation |
| **Business** | teams, approvals, policies, staged multi-node operations |
| **Security** | advanced Sentinel correlation/runtime-defense integrations |
| **Enterprise** | private control plane, SSO/RBAC, SIEM, governance and support |

See [`docs/COMMERCIAL.md`](docs/COMMERCIAL.md).

---

## Account and API

KINGAI OPS uses the wider **KINGAI account and API system** for hosted/commercial coordination rather than creating a separate cloud identity silo.

The node-local administrator remains separate from cloud SSO by design: cloud identity can coordinate fleets, while the local node can remain operable when the Internet or control plane is unavailable.

---

## Repository purpose and source-code policy

This public repository is the official binary distribution and product-information channel for KINGAI OPS Free/Core.

It contains installers, updater/uninstaller, documentation, release metadata and binary Releases. It **does not contain the KINGAI OPS proprietary core source code**.

KINGAI OPS is **free-to-use proprietary software**, not open-source software. See [`LICENSE-EULA.md`](LICENSE-EULA.md).

---

## Documentation

- [Installation & deployment](docs/INSTALL.md)
- [Feature model](docs/FEATURES.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Commercial editions](docs/COMMERCIAL.md)
- [Security](SECURITY.md)

---

## Contact

Product: https://ops.kingai.work  
KINGAI: https://kingai.work  
Commercial / MSP / hosting / enterprise / strategic partnership: **vip@kingai.work**

Copyright © 2026 KINGAI / USDX TECH LLC. All rights reserved.
