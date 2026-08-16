# KINGAI OPS Universal Bootstrap v2

This guide describes the public one-command deployment path for KINGAI OPS on conventional Linux servers, lightweight edge nodes and IoT/OpenWrt-class systems.

## 1. Default install

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh
```

The bootstrap detects the host and chooses a profile automatically. It does not enable service restart, container restart, backup or restore mutation permissions by default.

## 2. Deployment profiles

```bash
# Server / VPS / cloud Linux
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile server

# Edge
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile edge

# IoT / OpenWrt-class host
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile iot

# Conservative/minimal integration
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sudo sh -s -- --profile minimal
```

`auto` currently selects IoT for OpenWrt/LEDE and small MIPS/ARM classes, Edge for selected Alpine ARM/RISC-V environments, and Server for conventional Linux servers.

## 3. Dry-run preflight

Dry-run performs OS, architecture, profile and init-system detection without downloading a binary or changing host files:

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh | sh -s -- --profile auto --dry-run
```

Use this before mass deployment to unfamiliar appliance images.

## 4. Release pinning

Latest stable release:

```bash
sudo sh install.sh --version latest
```

Pinned release:

```bash
sudo sh install.sh --version v0.9.1
```

The bootstrap downloads the architecture-specific binary and `SHA256SUMS`, verifies SHA-256, then runs the binary self-check before installation. A missing asset or checksum mismatch fails closed.

## 5. Current and next architecture sets

Currently published v0.9.1 assets:

- amd64
- arm64
- 386
- armv7
- armv6
- ppc64
- ppc64le
- mips64le
- s390x
- riscv64
- loong64

The next private release pipeline additionally builds:

- armv5
- mips
- mipsle
- mips64

The installer recognizes all 15 target names, but an architecture is not considered publicly available until the corresponding binary exists in an actual public release.

## 6. Init/service integration

Universal Bootstrap v2 detects these managed service paths:

- `systemd`
- OpenWrt `procd`
- OpenRC
- runit
- SysV init
- manual fallback

The daemon remains a local node agent; the management HTTP endpoint binds to `127.0.0.1:17888` by default.

### OpenWrt / procd

On an OpenWrt/LEDE host, the installer creates `/etc/init.d/kingaid` using `procd`, enables it and verifies the local health endpoint when the platform provides the required userspace/kernel capabilities.

OpenWrt images vary substantially. Binary architecture compatibility does not guarantee that every optional inventory/security adapter exists on every router image. Missing capabilities degrade without enabling guessed mutations.

## 7. One-step Fleet enrollment

Create a short-lived enrollment token in the KINGAI OPS hosted control plane and place it in a root-only file on the node. Then install and enroll in one command:

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

The bootstrap intentionally uses a token file instead of a plain `--token VALUE` parameter so the enrollment secret is not encouraged into shell history or process arguments.

The node core creates an Ed25519 identity and uses signed Fleet enrollment/heartbeat messages. Node-local authorization remains authoritative for local mutations.

## 8. Cloud-init / provider user-data

A simple first-boot example:

```yaml
#cloud-config
runcmd:
  - curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/install.sh -o /tmp/kingai-install.sh
  - chmod 0700 /tmp/kingai-install.sh
  - /tmp/kingai-install.sh --profile server
  - rm -f /tmp/kingai-install.sh
```

For fleet enrollment, provision the short-lived token through the provider's secret/user-data mechanism into a root-only temporary file, pass `--enroll-token-file`, and remove the token file after successful enrollment.

Do not bake reusable enrollment credentials into machine images.

## 9. Local-first access

The default Console is not exposed to the public network:

```text
http://127.0.0.1:17888
```

For an administrator workstation:

```bash
ssh -L 17888:127.0.0.1:17888 user@server
```

Then open `http://127.0.0.1:17888` locally.

## 10. First-deploy state

Default paths:

```text
/usr/local/bin/kingai
/usr/local/bin/kai
/etc/kingaiops/config.json
/etc/kingaiops/install-meta.json
/etc/kingaiops/admin.json
/var/lib/kingaiops/
/var/log/kingaiops/
```

The installer preserves existing configuration/admin state on an upgrade-style reinstall. It records the detected profile/architecture/init system in `install-meta.json`.

## 11. First security assessment

Unless `--no-first-check` is selected, installation runs:

```bash
sudo kingai first-check
```

and stores the report at:

```text
/var/lib/kingaiops/reports/first-security-check.json
```

## 12. Failure recovery

When replacing an existing KINGAI OPS binary, the bootstrap saves the prior executable. If the new managed service does not start or the local health check fails, the installer restores the previous binary and attempts to restart the previous service state.

This rollback protects the KINGAI OPS agent binary. It is not a general operating-system rollback mechanism.

## 13. Updating

```bash
curl -fsSL https://raw.githubusercontent.com/kingaiwork/kingaiopsfree/main/update.sh | sudo sh
```

The update channel preserves node configuration and validates the new binary before considering the update healthy.

## 14. Air-gapped and fully offline deployments

The current public one-command bootstrap is **online-first** because it retrieves signed/checksummed release assets from GitHub Releases. The node runtime itself is local-first and can continue core local operation without the hosted control plane.

A fully packaged air-gap installer/bundle with offline release manifest import is a separate deployment mode and should not be inferred from the online installer. Enterprise/offline packaging will remain explicitly labeled until it is released.

## 15. Production rollout recommendations

For commercial fleets:

1. Pin a release version during staged rollout.
2. Run `--dry-run` against representative hardware/images.
3. Deploy to a canary group first.
4. Verify `kingai health`, `kingai readiness`, `kingai security` and `kingai fleet status`.
5. Keep mutating permissions disabled until the policy/approval model for that fleet is configured.
6. Roll out by environment/region/device class rather than all nodes simultaneously.
7. Preserve the local Console and node-local control boundary even when hosted Fleet is enabled.

Copyright © 2026 KINGAI / USDX TECH LLC. All rights reserved.
