# KINGAI OPS Free/Core — Installation & Deployment

KINGAI OPS Free/Core is distributed as a **prebuilt proprietary binary**. This public repository does not contain a source-build path.

## Standard install

After the first official closed-source release is published here:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh
```

The installer fails closed if it cannot obtain and verify a matching official binary/checksum.

## Supported release architectures

Planned/target release names:

```text
kingai-linux-amd64
kingai-linux-arm64
kingai-linux-386
kingai-linux-armv7
kingai-linux-ppc64le
kingai-linux-s390x
kingai-linux-riscv64
```

## Verification model

The installer downloads:

```text
kingai-linux-<arch>
SHA256SUMS
```

and verifies SHA-256 before installation. If verification fails, installation stops.

Future supply-chain hardening is expected to add publisher signatures, SBOMs and provenance; checksums alone are integrity checks, not publisher-identity signatures.

## Local Console

Default:

```text
http://127.0.0.1:17888
```

Remote-safe access:

```bash
ssh -L 17888:127.0.0.1:17888 user@server
```

Then open locally:

```text
http://127.0.0.1:17888
```

## Default local paths

```text
/usr/local/bin/kingai
/usr/local/bin/kai
/etc/kingaiops/config.json
/var/lib/kingaiops/
/var/lib/kingaiops/backups/
/var/log/kingaiops/
```

## Safe defaults

The public installer creates a configuration where supported state-changing operations are disabled by default.

```json
{
  "listen": "127.0.0.1:17888",
  "allowServiceRestart": false,
  "allowedServices": [],
  "allowContainerRestart": false,
  "allowedContainers": [],
  "allowLocalBackup": false
}
```

Capabilities should be enabled deliberately and only for explicitly allowed targets.

## systemd

On a normal systemd host, the installer creates and starts `kingaid.service` with a hardened baseline including:

- `NoNewPrivileges=true`
- private temporary directory
- protected system/home/kernel/control-group settings
- restricted writable paths for KINGAI OPS state/logs

Exact sandboxing may evolve between releases and must remain compatible with the features enabled on the node.

## OpenRC / runit

OpenRC and runit service templates will be published in this repository as deployment metadata. Until their closed-source release packaging is finalized, follow the release-specific instructions rather than exposing the local Console publicly.

## Updates

The update model is binary-based:

```text
check release → download → verify → stage → replace → health check → rollback on failure
```

The public channel will not compile proprietary source code on the customer server.

## Uninstall

The uninstall process should remove the service/binary while preserving configuration, audit history and backups unless the operator explicitly requests data deletion.

## Production guidance

Before using any preview release on a critical server:

- confirm an independent backup/recovery path;
- keep provider/console access available;
- review firewall/SSH effects before changing access controls;
- validate application/database restore procedures;
- test upgrades on a non-critical node first.

Product/support contact: **vip@kingai.work**
