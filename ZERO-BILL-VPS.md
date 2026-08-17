# KINGAI OPS Free Distribution — Zero-Bill VPS

This public repository distributes installer/update/uninstall scripts and validates already-published public binaries. The proprietary core remains in `kingaiwork/kingai-ops`.

## Zero-bill execution

All automatic checks run on the owned VPS self-hosted runner. Real install smoke runs inside a disposable Ubuntu container so it cannot modify the host VPS. Evidence is stored under `/srv/kingai/qa/kingaiopsfree/<sha>`.

Automatic release upload/publication is forbidden. New proprietary binaries are built in the private `kingai-ops` repository and retained on the VPS first. Any public release publication is a separate operator-approved step after checksums and distribution-path billing are reviewed.

## VPS prerequisites

```bash
docker --version
sudo mkdir -p /srv/kingai/qa/kingaiopsfree
sudo chown -R "$USER":"$USER" /srv/kingai
```

## OpenClaw / Codex instruction

```text
Operate kingaiwork/kingaiopsfree under .kingai/zero-bill.json. Keep proprietary core source private in kingaiwork/kingai-ops. Run install smoke in disposable local Docker containers on the owned VPS and store evidence under /srv/kingai/qa/kingaiopsfree. Do not mutate the host during tests. Do not enable hosted runners, Actions artifacts, paid cloud resources, paid AI APIs or automatic GitHub release uploads. Treat existing public release downloads as read-only verification. Any new public binary publication requires explicit operator approval after SHA-256 verification.
```

No cloud data migration is required for this repository.
