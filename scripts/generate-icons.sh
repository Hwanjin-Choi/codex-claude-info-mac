#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."
OUTPUT_DIR="$PWD/.build/icon-assets"
ICONSET="$OUTPUT_DIR/AppIcon.iconset"
PREVIEW_DIR="$(mktemp -d)"
trap 'rm -rf "$PREVIEW_DIR"' EXIT

mkdir -p "$OUTPUT_DIR"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

qlmanage -t -s 1024 -o "$PREVIEW_DIR" "Resources/AppIcon.svg" >/dev/null
MASTER="$PREVIEW_DIR/AppIcon.svg.png"

sips -z 16 16 "$MASTER" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$MASTER" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$OUTPUT_DIR/AppIcon.icns"
