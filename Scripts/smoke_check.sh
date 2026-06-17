#!/usr/bin/env bash
set -euo pipefail
APP="/Applications/NODAYSIDLE Control Room.app"
[ -d "$APP" ] || { echo "missing app: $APP"; exit 1; }
codesign --verify --deep --strict --verbose=2 "$APP"
open -n "$APP"
sleep 3
pgrep -fl "NODAYSIDLEControlRoom" >/tmp/nodaysidle-control-room-smoke.txt
cat /tmp/nodaysidle-control-room-smoke.txt
