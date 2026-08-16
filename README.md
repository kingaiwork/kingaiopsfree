# KINGAI OPS

## Governed Operations for Server · Edge · IoT

**KINGAI OPS** is a proprietary, free-to-use Linux operations platform that combines a lightweight node agent, local management console, signed fleet connectivity, security posture, infrastructure discovery and policy-controlled operations.

The product is designed for the same real-world problem space as modern server panels, application platforms and fleet/edge managers, but with a different control model: **observe → understand → approve → act → verify → audit**.

**KINGAI OPS Core is free to use. The source code is proprietary and is not open source.**

- Product: https://ops.kingai.work
- KINGAI account/API: https://kingai.work
- Commercial / MSP / enterprise / partnership: **vip@kingai.work**
- Current published binary release: **v0.9.1**

---

## One command, four deployment profiles

Default auto-detection:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh
```

Server / VPS / cloud host:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile server
```

Edge node:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile edge
```

IoT / OpenWrt-class node:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile iot
```

Minimal / conservative host integration:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile minimal
```

Inspect without changing the host:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sh -s -- --profile edge --dry-run
```

The Universal Bootstrap v2 detects Linux, architecture and service manager, verifies the release checksum, installs or preserves configuration, creates the node-local administrator when missing, saves a baseline, performs a first security assessment, installs a managed service when supported, verifies `/healthz`, and restores the previous binary if managed startup fails.

The local Console stays on `127.0.0.1:17888` by default. KINGAI OPS does not open a generic public management port during installation.

---

## Server · Edge · IoT profiles

| Profile | Intended target | Default posture |
|---|---|---|
| **Server** | VPS, dedicated server, VM, cloud Linux | 30s local polling; broad web/container/database service discovery |
| **Edge** | branch server, gateway, lightweight ARM/RISC-V node | 60s polling; reduced service surface |
| **IoT** | OpenWrt/LEDE-class systems, MIPS and small ARM devices | 120s polling; Dropbear/SSH-aware conservative profile |
| **Minimal** | unknown or highly customized Linux | 120s polling; smallest default service allowlist |

Every profile starts with host mutations disabled:

```text
allowServiceRestart   = false
allowContainerRestart = false
allowLocalBackup      = false
allowLocalRestore     = false
```

A profile changes discovery/polling defaults; it does **not** bypass policy or approval.

Installation metadata is written to `/etc/kingaiops/install-meta.json` so operators can see which profile, architecture, release request and init system were selected.

---

## Signed Fleet enrollment during installation

Commercial/hosted deployments can enroll the node into the KINGAI OPS Fleet control plane during the same bootstrap without exposing a long-lived secret in shell history.

Place a short-lived enrollment token in a root-controlled file, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | \
  sudo sh -s -- \
  --profile server \
  --enroll-token-file /root/kops-enroll.token \
  --name prod-web-01 \
  --environment production \
  --provider aws \
  --region us-west-2
```

The installed private core generates an Ed25519 node identity, signs enrollment/heartbeat messages and stores the node private identity locally with restrictive permissions. Fleet coordination does not remove the node-local policy boundary.

---

## Linux and init-system compatibility

KINGAI OPS uses capability detection rather than a narrow distribution-version allowlist.

Primary Linux families include:

- Debian / Ubuntu and derivatives
- Fedora / RHEL / Rocky / Alma and derivatives
- openSUSE / SUSE
- Arch / Manjaro
- Alpine
- Void and other conventional Linux environments
- OpenWrt / LEDE-class embedded Linux through `procd`

Universal Bootstrap v2 understands these service paths:

- systemd
- OpenWrt `procd`
- OpenRC
- runit
- SysV init
- manual fallback when no known service manager can be safely identified

Immutable/atomic systems, NixOS, s6-only appliances and heavily customized embedded systems are handled conservatively; unsupported host mutations are not guessed.

---

## Architecture status: published vs next release

**Currently published v0.9.1 assets** remain the verified 11-architecture set:

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

The private release pipeline has now been expanded for the **next binary release** to 15 architectures by adding:

```text
armv5
mips
mipsle
mips64
```

Those four additional binaries are **not claimed as currently downloadable until a new public release is successfully built and published**. The installer fails closed if a requested asset is absent.

Architecture availability also does not imply identical kernel, package-manager, container or security facilities on every device. Missing capabilities degrade safely.

---

## What one deployment gives you today

### Local node operations

- authenticated local Console
- Linux inventory and health
- CPU / memory / disk / load / uptime
- service/process/port/network visibility
- Docker / Podman discovery
- Nginx / Caddy and website discovery
- database/cache discovery and health context
- TLS certificate inventory
- storage/mount visibility
- SSH/access posture
- nftables / UFW / firewalld / iptables visibility
- package/update visibility
- cron/scheduled-job visibility
- baseline and configuration drift
- first-deploy security report
- local audit trail
- Security Center foundation

### Governed operations

The commercial core already contains typed, bounded operations for areas such as service restart, container restart, backup and verified restore. These are policy-gated, require explicit approval where configured, and produce audit evidence. Broad unattended root automation is intentionally not the default.

### Fleet foundation

The current core includes signed node enrollment and heartbeat to the shared KINGAI account/API plane. Higher-level multi-node orchestration, bulk rollout UX, advanced Edge offline queues and full enterprise governance continue to expand and are not presented as complete where they are still staged.

---

## First local administrator

Default username:

```text
admin
```

The password is generated cryptographically during first deployment. On a non-interactive/cloud-init installation, the one-time handoff is stored temporarily at:

```text
/var/lib/kingaiops/initial-admin.txt
```

with mode `0600`, and is removed after the first successful Console login.

Persistent credentials are stored at:

```text
/etc/kingaiops/admin.json
```

as a salted password verifier rather than plaintext.

Useful commands:

```bash
sudo kingai admin status
sudo kingai admin reset-password --approve
sudo kingai health
sudo kingai readiness
sudo kingai security
sudo kingai fleet status
```

---

## First security assessment

First deployment runs:

```bash
sudo kingai first-check
```

and stores the report at:

```text
/var/lib/kingaiops/reports/first-security-check.json
```

Signals include host/kernel/architecture, resource health, init/service readiness, SSH/access posture, firewall state, listening ports, package/update visibility, TLS/web context, Security Center posture, baseline/drift and filesystem/audit readiness where available.

The report remains local and may contain infrastructure metadata; review it before sharing.

---

## Local-first security model

Core local operations continue even if the hosted control plane or an AI provider is unavailable.

Default Console:

```text
http://127.0.0.1:17888
```

Remote-safe access:

```bash
ssh -L 17888:127.0.0.1:17888 user@server
```

Local authentication includes random session tokens, HttpOnly cookies, SameSite=Strict, login lockout, local source/Host enforcement and password-reset session invalidation. Cloud/AI access does not bypass the node-local policy boundary.

---

## Updates and rollback

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/update.sh | sudo sh
```

The updater verifies the release, preserves the prior binary, keeps existing administrator/configuration state, restarts the managed service when applicable, verifies health and restores the previous binary if the new service fails.

Existing administrator passwords are not silently reset.

---

## Editions

| Edition | Product direction |
|---|---|
| **Core / Free** | local-first single-node management, security and governed-operation foundation |
| **Pro** | developers/small fleets, hosted coordination and advanced automation |
| **Business** | teams, approvals, policies and staged multi-node operations |
| **Security** | advanced Sentinel correlation/runtime-defense integrations |
| **Enterprise** | private control plane, SSO/RBAC, SIEM, governance and support |

See [`docs/COMMERCIAL.md`](docs/COMMERCIAL.md).

---

## Repository and source-code policy

This repository is the official binary distribution and public documentation channel. It contains installers, updater/uninstaller, documentation, release metadata and binary releases. It does **not** contain the proprietary KINGAI OPS core source.

KINGAI OPS is **free-to-use proprietary software**, not open-source software. See [`LICENSE-EULA.md`](LICENSE-EULA.md).

---

## Documentation

- [Universal installation](docs/UNIVERSAL-INSTALL.md)
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
