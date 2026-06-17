#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NODAYSIDLE Control Room"
EXEC_NAME="NODAYSIDLEControlRoom"
APP="$ROOT/$APP_NAME.app"
VERSION="0.1.0"
BUILD="1"
cd "$ROOT"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/$EXEC_NAME" "$APP/Contents/MacOS/$EXEC_NAME"
cp "Assets/Logo/nodaysidle-control-room.svg" "$APP/Contents/Resources/nodaysidle-control-room.svg"
ICONSET="$ROOT/.build/Icon.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root = Path.cwd(); iconset = root/'.build/Icon.iconset'
for size, scale in [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)]:
    px=size*scale; img=Image.new('RGBA',(px,px),(5,6,4,255)); d=ImageDraw.Draw(img)
    d.rounded_rectangle([int(px*.07),int(px*.07),int(px*.93),int(px*.93)], radius=int(px*.20), outline=(200,255,0,255), width=max(2,px//36))
    d.ellipse([int(px*.22),int(px*.22),int(px*.78),int(px*.78)], outline=(200,255,0,96), width=max(1,px//64))
    try: font=ImageFont.truetype('/System/Library/Fonts/SFNSMono.ttf', int(px*.20))
    except Exception: font=ImageFont.load_default()
    box=d.textbbox((0,0),'NDI',font=font); d.text(((px-(box[2]-box[0]))/2,(px-(box[3]-box[1]))/2),'NDI',fill=(200,255,0,255),font=font)
    suffix=f'{size}x{size}' + (f'@{scale}x' if scale>1 else '')
    img.save(iconset/f'icon_{suffix}.png')
PY
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
