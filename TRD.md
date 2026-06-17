# TRD: NODAYSIDLE Control Room

## Stack

- Swift 6.2
- SwiftUI
- AppKit interop for activation/window polish
- SwiftPM package
- JSON/struct models only

## Core Types

- `AgentProcess`: pid, kind, command, detail, status
- `RepoStatus`: path, name, branch, dirty count, remote, last commit
- `BridgeStatus`: name, endpoint, status
- `Receipt`: path, project, timestamp
- `SystemSnapshot`: aggregate view model payload

## Scanner Contracts

`ProcessScanner.scan()` must return only observed processes.
`RepoScanner.scan(paths:)` must not mutate repos.
`BridgeScanner.scan()` must use TCP connect checks only.
`ReceiptScanner.scan(roots:)` must read filenames/metadata only.

## Verification Commands

```bash
swift test
swift build -c release
Scripts/package_app.sh
codesign --verify --deep --strict --verbose=2 "NODAYSIDLE Control Room.app"
Scripts/install_app.sh
Scripts/smoke_check.sh
```
