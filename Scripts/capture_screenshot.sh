#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="/Applications/NODAYSIDLE Control Room.app"
OUTDIR="${1:-${TMPDIR:-/tmp}/nodaysidle-control-room-screenshots}"
OUT="$OUTDIR/control-room-self-render-1280x820.png"
mkdir -p "$OUTDIR"
if [ ! -d "$APP" ]; then
  "$ROOT/Scripts/install_app.sh" >/dev/null
fi
rm -f "$OUT"
CONTROL_ROOM_SCREENSHOT_PATH="$OUT" CONTROL_ROOM_SCREENSHOT_EXIT=1 "$APP/Contents/MacOS/NODAYSIDLEControlRoom"
file "$OUT"
stat -f 'size=%z' "$OUT"
echo "$OUT"
