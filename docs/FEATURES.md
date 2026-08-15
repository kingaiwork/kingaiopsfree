# KINGAI OPS — Public Feature Matrix

This document describes the product at a public level without exposing proprietary implementation details.

Status labels:

- **Available** — included in currently published Free/Core releases.
- **Preview** — available to selected/current preview builds but still maturing.
- **Commercial** — paid-plan capability or hosted/commercial service.
- **Planned** — roadmap direction, not yet claimed as shipped.

## Free/Core

| Capability | Status |
|---|---|
| Linux host inventory | Preview |
| CPU / memory / disk / load / uptime | Preview |
| Service visibility | Preview |
| Process and listening-port visibility | Preview |
| Docker / Podman visibility | Preview |
| Network and firewall posture | Preview |
| SSH/access posture | Preview |
| Nginx / Caddy discovery | Preview |
| Database/cache discovery | Preview |
| TLS certificate inventory | Preview |
| Storage/mount visibility | Preview |
| Package/update visibility | Preview |
| Scheduled-job visibility | Preview |
| Local backup foundation | Preview |
| Baseline / drift detection | Preview |
| Local audit trail | Preview |
| Security Center foundation | Preview |
| Local responsive Console | Preview |
| Core Mode without external AI API | Preview |

## Pro / Fleet direction

| Capability | Status |
|---|---|
| KINGAI account integration | Commercial |
| Multi-node Fleet | Commercial / Planned |
| Cloud Console | Commercial / Planned |
| Signed node enrollment | Planned |
| Remote typed operations | Planned |
| Staged/canary operations | Planned |
| Advanced runbooks | Planned |
| Hosted AI-assisted diagnosis | Planned |

## Business direction

| Capability | Status |
|---|---|
| Teams | Planned |
| RBAC | Planned |
| Approval workflows | Planned |
| Policy packs | Planned |
| Multi-tenant/MSP boundaries | Planned |
| Central audit search | Planned |
| Fleet maintenance windows | Planned |

## Security / Sentinel direction

| Capability | Status |
|---|---|
| Local security posture | Preview |
| SSH abuse signals | Planned |
| File-integrity signals | Planned |
| Process ancestry correlation | Planned |
| Runtime security adapters | Planned |
| Falco/eBPF integration | Planned |
| Optional Tetragon integration | Planned |
| Incident correlation | Planned |
| Reversible containment | Planned |
| Evidence timeline | Planned |

## Enterprise direction

| Capability | Status |
|---|---|
| SSO / OIDC / SAML | Planned |
| Advanced RBAC / ABAC | Planned |
| Private control plane | Planned |
| SIEM/SOC integration | Planned |
| Compliance evidence export | Planned |
| Enterprise release channels | Planned |
| SLA/support programs | Planned |

## Product boundary

KINGAI OPS is server/infrastructure management and defensive-security software for systems owned or explicitly authorized by the operator. Offensive intrusion, credential theft, persistence on third-party systems and hack-back functionality are outside the product scope.
