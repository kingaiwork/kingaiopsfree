# ✦ KINGAI OPS Free

## Autonomous Infrastructure Operations & Defense

**KINGAI OPS** is a proprietary Linux infrastructure operations platform for VPS, cloud servers, containers, websites, databases, backup, monitoring, security and progressively autonomous operations.

**KINGAI OPS Core is free to use. The source code is proprietary and is not open source.**

- Product: https://ops.kingai.work
- KINGAI account/API: https://kingai.work
- Commercial / MSP / enterprise / partnership: **vip@kingai.work**

---

## Repository purpose

This public repository is the official distribution and product-information channel for KINGAI OPS Free/Core.

It contains:

- product introduction;
- Free/Core feature documentation;
- installation and upgrade instructions;
- binary release information;
- checksums and release notes;
- commercial edition comparison;
- deployment architecture documentation;
- security and responsible-disclosure information.

It **does not contain the KINGAI OPS core source code**.

The proprietary implementation—including `kingaid`, the local Console implementation, Sentinel internals, policy/execution/rollback engines, Fleet control-plane code and commercial modules—is maintained in private repositories.

---

## KINGAI OPS Core — Free

The free edition is intended for individual developers, VPS owners, homelab users and small teams.

Core product direction includes:

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
- firewall posture;
- package/update visibility;
- scheduled-job visibility;
- local backups;
- baseline and drift detection;
- audit trail;
- Security Center foundation;
- local responsive Console;
- deterministic Core Mode without an external AI API key.

Capabilities are shipped progressively. See [`docs/FEATURES.md`](docs/FEATURES.md) for the public status model.

---

## Install model

KINGAI OPS Free is distributed as **prebuilt proprietary Linux binaries**.

The public installer must:

1. detect Linux architecture;
2. download the matching official release binary;
3. download the published checksum manifest;
4. verify SHA-256 before installation;
5. install the service integration;
6. keep the local management Console on loopback by default.

There is **no public source-build fallback**.

When the first closed-source release is published, the standard installation entry will be:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh
```

Until a signed/verified binary release is published in this repository, the installer will fail closed rather than build from public source.

---

## Local-first security model

KINGAI OPS is designed so that a server can continue core local operations even when a cloud control plane or AI provider is unavailable.

Default local Console target:

```text
127.0.0.1:17888
```

Recommended remote access during local-only operation:

```bash
ssh -L 17888:127.0.0.1:17888 user@server
```

The product does not require a generic public `:8888`-style management port.

---

## Free vs commercial editions

| Edition | Direction |
|---|---|
| **Core / Free** | local-first single-node management and security foundation |
| **Pro** | developers and small fleets, cloud coordination, advanced automation |
| **Business** | teams, approvals, policies, staged multi-node operations |
| **Security** | advanced Sentinel correlation/runtime-defense integrations |
| **Enterprise** | private control plane, SSO/RBAC, SIEM, governance and support |

See [`docs/COMMERCIAL.md`](docs/COMMERCIAL.md).

---

## Account and API

KINGAI OPS uses the wider **KINGAI account and API system** rather than creating a separate user identity silo.

Commercial/cloud capabilities are designed to reuse KINGAI identity, subscription/license and API entitlements while keeping the local Free/Core edition useful without constant cloud connectivity.

---

## Source-code policy

KINGAI OPS is **free-to-use proprietary software**, not open-source software.

Public distribution does not grant access to or rights over the private source code. See [`LICENSE-EULA.md`](LICENSE-EULA.md).

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
