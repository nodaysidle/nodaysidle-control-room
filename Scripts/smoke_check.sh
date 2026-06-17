#!/usr/bin/env bash
set -euo pipefail
APP="/Applications/NODAYSIDLE Control Room.app"
[ -d "$APP" ] || { echo "missing app: $APP"; exit 1; }
codesign --verify --deep --strict --verbose=2 "$APP"
open -n "$APP"
sleep 3
pgrep -fl "NODAYSIDLEControlRoom" >/tmp/nodaysidle-control-room-smoke.txt
cat /tmp/nodaysidle-control-room-smoke.txt
osascript -e 'tell application "System Events" to tell process "NODAYSIDLEControlRoom" to get {name of windows, position of window 1, size of window 1}'
osascript -e 'tell application "NODAYSIDLE Control Room" to quit' >/dev/null 2>&1 || true
