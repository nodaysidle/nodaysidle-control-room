# TASKS: NODAYSIDLE Control Room

## Phase 1 — Foundation
- [x] Create clean SwiftPM repo.
- [x] Write README, PRD, ARD, TRD, TASKS, AGENTS.
- [x] Add core models and parser tests.
- Validation: `swift test`.

## Phase 2 — Real Scanners
- [x] Implement process scanner.
- [x] Implement git repo scanner.
- [x] Implement bridge scanner.
- [x] Implement receipt scanner.
- [x] Shell.run pipe/timeout hardening (no deadlock on large output).
- [x] RepoScanner git failure handling (return unknown, not dirty).
- [x] Optional user config (~/.config/nodaysidle-control-room/config.json).
- [x] CI: GitHub Actions for swift test, release build, package, codesign.
- [x] Release binary existence check in package_app.sh.
- Validation: `swift test`, `swift build -c release`; CI runs after push/PR.

## Phase 3 — Premium Native UI
- [x] Implement menu bar app and control-room window.
- [x] Render mission strip, agents, repos, bridges, receipts.
- [x] Add premium dark NODAYSIDLE visual system.
- [x] Constrain window layout with ScrollView (default ~1280x820, min 1120x720).
- Validation: `swift build -c release`.

## Phase 4 — Packaging
- [x] Add SVG logo source.
- [x] Generate app icon.
- [x] Package `.app` and ad-hoc sign.
- [x] Install to `/Applications`.
- Validation: codesign and launch smoke.

## Phase 5 — Presentation
- [ ] Add NODAYSIDLE Control Room to Project Pages.
- [ ] Build/check/deploy Project Pages if workflow allows.
- [ ] Capture screenshots.
