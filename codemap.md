# codemap.md

## Responsibility
Native macOS Control Room app for local NODAYSIDLE agent/process/repo status.

## Entry Points
- `Sources/ControlRoom/main.swift` — SwiftUI app entry.
- `Sources/ControlRoomCore/SystemScanner.swift` — aggregate scanner.
- `Scripts/package_app.sh` — release app bundle assembly.

## Directory Map
- `Sources/ControlRoomCore/` — models, parser logic, read-only scanners.
- `Sources/ControlRoom/` — SwiftUI UI and app lifecycle.
- `Tests/ControlRoomCoreTests/` — parser/scanner policy tests.
- `Assets/Logo/` — SVG logo source.
- `Scripts/` — packaging/install/smoke commands.
