#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NODAYSIDLE Control Room"
EXEC_NAME="NODAYSIDLEControlRoom"
APP="$ROOT/$APP_NAME.app"
VERSION="0.1.2"
BUILD="1"
cd "$ROOT"
swift build -c release
EXEC_PATH=".build/release/$EXEC_NAME"
if [ ! -f "$EXEC_PATH" ]; then
  echo "ERROR: release binary not found at $EXEC_PATH" >&2
  exit 1
fi
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/$EXEC_NAME" "$APP/Contents/MacOS/$EXEC_NAME"
cp "Assets/Logo/nodaysidle-control-room.svg" "$APP/Contents/Resources/nodaysidle-control-room.svg"
ICONSET="$ROOT/.build/Icon.iconset"
SVG_SOURCE="$ROOT/Assets/Logo/nodaysidle-control-room.svg"
SVG_RENDER_DIR="$ROOT/.build/svg-render"
SVG_RENDER="$SVG_RENDER_DIR/nodaysidle-control-room.svg.png"
rm -rf "$ICONSET" "$SVG_RENDER_DIR"
mkdir -p "$ICONSET" "$SVG_RENDER_DIR"
qlmanage -t -s 1024 -o "$SVG_RENDER_DIR" "$SVG_SOURCE" >/dev/null 2>&1
if [ ! -f "$SVG_RENDER" ]; then
  echo "failed to render SVG icon source: $SVG_SOURCE" >&2
  exit 1
fi
for spec in 16:1 16:2 32:1 32:2 128:1 128:2 256:1 256:2 512:1 512:2; do
  size="${spec%%:*}"
  scale="${spec##*:}"
  px=$((size * scale))
  suffix="${size}x${size}"
  if [ "$scale" != "1" ]; then suffix="${suffix}@${scale}x"; fi
  cp "$SVG_RENDER" "$ICONSET/icon_${suffix}.png"
  sips -z "$px" "$px" "$ICONSET/icon_${suffix}.png" >/dev/null
 done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleExecutable</key><string>$EXEC_NAME</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIdentifier</key><string>com.nodaysidle.controlroom</string>
<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$BUILD</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
printf 'APPL????' > "$APP/Contents/PkgInfo"
codesign --force --deep --sign - "$APP" >/dev/null
codesign --verify --deep --strict --verbose=2 "$APP"
echo "$APP"
