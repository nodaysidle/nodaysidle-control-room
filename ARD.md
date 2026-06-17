# ARD: NODAYSIDLE Control Room

## Architecture Decision

Use SwiftPM native macOS with SwiftUI and AppKit interop. This fits menu bar status, local process scanning, repo state, packaging, and `/Applications` installation without web runtime overhead.

## Layers

- `ControlRoomCore`: pure models, parsers, scanners, snapshot assembly.
- `ControlRoom`: SwiftUI app shell and views.
- `Scripts`: repeatable packaging/install/smoke helpers.
- `Assets`: SVG logo and generated icon artifacts.

## Data Flow

`SystemScanner` reads allowlisted local state → creates `SystemSnapshot` → `DashboardViewModel` publishes UI state → SwiftUI renders status cards.

## Safety Decisions

- Process/repo scans are read-only.
- Commands are allowlisted: `ps`, `git`, TCP connect checks.
- No kill/restart/process mutation controls in v0.1.
- Unknown states are rendered as unknown, not guessed.

## Packaging Decision

SwiftPM builds the executable. `Scripts/package_app.sh` assembles `.app`, writes Info.plist, copies resources, generates/copies icon, and ad-hoc signs.
