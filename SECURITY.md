# KINGAI OPS Security

KINGAI OPS is infrastructure-management and defensive-security software for systems owned or explicitly authorized by the operator.

## Public distribution security model

The public `kingaiopsfree` repository distributes documentation, installers and release metadata. It does not publish the proprietary core source code.

Official installers are expected to:

- download only official release binaries;
- verify published SHA-256 checksums;
- fail closed when a release or checksum cannot be verified;
- keep the local management Console on loopback by default;
- avoid embedding long-lived secrets in scripts or binaries.

## Local Console

Default local address:

```text
127.0.0.1:17888
```

For remote access during local-only operation, prefer an SSH tunnel:

```bash
ssh -L 17888:127.0.0.1:17888 user@server
```

Do not expose the local management port directly to the public Internet unless a separately authenticated and reviewed access layer has been deliberately configured.

## AI authority boundary

KINGAI OPS is designed so that AI reasoning does not become an unrestricted root authority boundary.

The product direction is:

```text
Model intent
  → typed tool
  → policy
  → risk / approval
  → executor
  → verification
  → rollback / commit
  → audit
```

A generic privileged remote shell is not the intended automation model.

## Responsible disclosure

Do not publish an unpatched vulnerability, working exploit, customer data, private key, credential or production-infrastructure detail in a public issue.

Until a dedicated security address/program is announced, send security-sensitive reports privately to:

**vip@kingai.work**

Suggested subject:

```text
KINGAI OPS Security Report
```

Include affected version, Linux distribution/kernel/architecture, impact, reproducible steps and sanitized evidence when practical.

## Scope and safe research

Only test systems you own or are explicitly authorized to test. Do not access third-party data, disrupt third-party production services, persist unauthorized access, exfiltrate credentials or perform retaliatory intrusion/hack-back activity.

## Supply chain

SHA-256 checksums verify integrity against the published checksum manifest. They are not equivalent to publisher-identity signatures. The commercial release pipeline is expected to progress toward signed artifacts, SBOMs and build provenance.
