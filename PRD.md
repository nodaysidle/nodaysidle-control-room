# PRD: NODAYSIDLE Control Room

## Problem

NODAYSIDLE work spans Hermes, Codex, MCP bridges, tunnels, Vercel/GitHub tasks, and many local repos. The operator needs one trusted Mac-native place to see what is running, what needs attention, and which projects are dirty.

## Product

A premium native macOS menu bar + control-room app that surfaces real local agent/process/repo status and safe quick actions.

## Target User

NDI / local AI builder operating many NODAYSIDLE projects from a Mac.

## Core Jobs

1. Show active agent and bridge processes.
2. Show watched repo git state.
3. Show local service/port status.
4. Show recent receipt files when present.
5. Provide safe open/copy/refresh actions.

## Non-goals

- No destructive process control in v0.1.
- No fake approval inbox.
- No backend or account system.
- No Electron/Tauri/web shell.
- No credential capture.

## UX Standard

Premium, dark, sharp, compact, operator-grade. Volt accent `#C8FF00` is used for live/primary state, not decoration spam.

## Config

Users may optionally override watched repos and receipt roots via `~/.config/nodaysidle-control-room/config.json`. If absent, hardcoded NODAYSIDLE project paths are used as fallback defaults.

## Success Criteria

- Native `.app` installed in `/Applications`.
- Launches and renders real local state.
- Swift tests and release build pass.
- App icon comes from committed SVG source.
- CI (GitHub Actions) validates build, package, and codesign on every push.
- Project Pages presentation is updated after app is verified.
