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
- Validation: `swift test`, `swift build`.

## Phase 3 — Premium Native UI
- [x] Implement menu bar app and control-room window.
- [x] Render mission strip, agents, repos, bridges, receipts.
- [x] Add premium dark NODAYSIDLE visual system.
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
