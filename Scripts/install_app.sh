#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NODAYSIDLE Control Room.app"
SRC="$ROOT/$APP_NAME"
DEST="/Applications/$APP_NAME"
if [ ! -d "$SRC" ]; then "$ROOT/Scripts/package_app.sh" >/dev/null; fi
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
codesign --verify --deep --strict --verbose=2 "$DEST"
echo "$DEST"
