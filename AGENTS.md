## EXECUTION RULES — READ FIRST

- Keep working until the app works, is packaged, installed, launched, visually checked, and tested.
- Do not stop after scaffolding, spec writing, or one passing build.
- Run verification after each meaningful layer: `swift test`, `swift build`, package, codesign, launch smoke.
- Never claim DONE unless `/Applications/NODAYSIDLE Control Room.app` exists, launches, and the repo/build state is reproducible.
- If blocked, say BLOCKED with exact command output and next unblock action.

## Repository Map

If `codemap.md` exists, read it first. If absent, fall back to README.md, PRD.md, ARD.md, TRD.md, TASKS.md, then source files.

## Product Rules

- Native macOS SwiftPM app only for v0.1.
- Premium dark NODAYSIDLE utility: sharp, dense, useful, not a generic AI dashboard.
- Use real local state only. Unknown is acceptable; fake data is forbidden.
- No destructive kill/restart controls in v0.1.
- No cloud account, backend, telemetry, or credential handling.
- Logo source must remain SVG and packaged icon must be generated for the `.app`.

## Verification Gates

Required before completion:
- `swift test`
- `swift build -c release`
- `Scripts/package_app.sh`
- `codesign --verify --deep --strict --verbose=2 "NODAYSIDLE Control Room.app"`
- install to `/Applications`
- launch smoke with `open -n` and process check
- screenshots of packaged app
