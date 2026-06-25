# NODAYSIDLE Control Room

Premium native macOS control surface for local NODAYSIDLE agent work.

It shows real local status for:
- Hermes / Codex / CodexPro / tunnel / local dev processes
- watched NODAYSIDLE repos and dirty state
- local bridges and likely service ports
- recent receipt files when present

No cloud backend. No fake data. No destructive controls in v0.1. The v0.1 app is read-only: it observes local process, bridge, repo, and receipt state, then provides safe copy/open/refresh actions.

## Build

```bash
swift test
swift build -c release
Scripts/package_app.sh
Scripts/install_app.sh
Scripts/capture_screenshot.sh
```

## Install path

```text
/Applications/NODAYSIDLE Control Room.app
```

## Configuration (optional)

Place a JSON config file at `~/.config/nodaysidle-control-room/config.json` to override the default watched repos and receipt roots:

```json
{
  "repoPaths": [
    "/path/to/your/repo1",
    "/path/to/your/repo2"
  ],
  "receiptRoots": [
    "/path/to/your/receipts"
  ]
}
```

If the file is missing or invalid, the app falls back to local NODAYSIDLE defaults.

`Scripts/capture_screenshot.sh` writes to `${TMPDIR:-/tmp}/nodaysidle-control-room-screenshots` unless an output directory is passed explicitly.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on macOS 15:
- `swift test`
- `swift build -c release`
- `Scripts/package_app.sh`
- codesign verification
- SHA-256 checksums of release and bundle binaries

## NODAYSIDLE standard

This repo follows the local 9.7/10 gate: specs, tests, repeatable package script, real app launch proof, screenshots, and no invented integrations.
