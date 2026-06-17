# NODAYSIDLE Control Room

Premium native macOS control surface for local NODAYSIDLE agent work.

It shows real local status for:
- Hermes / Codex / CodexPro / tunnel / local dev processes
- watched NODAYSIDLE repos and dirty state
- local bridges and likely service ports
- recent receipt files when present

No cloud backend. No fake data. No destructive controls in v0.1.

## Build

```bash
swift test
swift build -c release
Scripts/package_app.sh
Scripts/install_app.sh
```

## Install path

```text
/Applications/NODAYSIDLE Control Room.app
```

## NODAYSIDLE standard

This repo follows the local 9.7/10 gate: specs, tests, repeatable package script, real app launch proof, screenshots, and no invented integrations.
