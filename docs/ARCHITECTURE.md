# KINGAI OPS — Public Architecture Overview

This document explains the product architecture at a public level. It intentionally does not expose proprietary implementation details.

## Local-first node

Each managed Linux server runs the KINGAI OPS node runtime (`kingaid`). Core local operations remain available without requiring an external AI provider.

Public architecture model:

```text
Operator / Local Console
          │
          ▼
       kingaid
          │
  ┌───────┼────────┐
  │       │        │
Observe  Policy  Controlled Actions
  │       │        │
  └───────┼────────┘
          │
      Verification
          │
       Audit / Recovery
```

The local Console is designed to bind to loopback by default rather than automatically exposing a public management port.

## Cloud/Fleet direction

Commercial Fleet capability is designed around an edge/cloud control plane that coordinates identity, node presence, policy, approvals, audit and asynchronous operations.

```text
                    ops.kingai.work
                           │
                   KINGAI Identity/API
                           │
                  Cloud / Edge Control
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
      Fleet              Policy             Audit
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                   outbound node session
                           │
                        kingaid
                           │
                    local authority
```

## Cloudflare direction

The hosted control-plane design uses Cloudflare-compatible building blocks for web delivery, APIs, durable coordination, relational metadata and asynchronous work.

Publicly described roles include:

- Pages / edge-delivered Console;
- Workers / authenticated APIs;
- D1 or equivalent relational control metadata;
- Durable Objects for node/session coordination;
- Queues for durable asynchronous work;
- R2/object storage for larger artifacts where appropriate;
- AI Gateway/provider routing for optional cloud intelligence.

The cloud coordinates; the node should retain essential local management and defensive capability during connectivity interruptions.

## Authority model

The product direction intentionally separates intelligence from privileged authority:

```text
AI / operator intent
        ↓
structured operation
        ↓
policy / risk / approval
        ↓
executor
        ↓
verification
        ↓
rollback or commit
        ↓
audit
```

This avoids treating a model-generated shell command as the product's trust boundary.

## Security direction

KINGAI Sentinel is the defensive security layer. Public product direction includes:

- SSH/access posture and abuse signals;
- process/runtime context;
- network/egress context;
- file/config drift;
- runtime-security integrations on capable Linux hosts;
- incident correlation;
- policy-governed containment;
- evidence and audit.

Advanced kernel/runtime features depend on the Linux distribution, kernel and host capabilities.

## Account architecture

Hosted/commercial KINGAI OPS capabilities are designed to reuse the wider KINGAI account, license/subscription and API entitlement system rather than creating an isolated second identity silo.

Local Free/Core operation remains designed to function without constant cloud availability.

## Source-code boundary

This repository intentionally publishes only product/distribution documentation and release artifacts. The node implementation, Console source, Sentinel internals, policy/execution/rollback engines and Fleet control-plane implementation are proprietary and maintained privately.
