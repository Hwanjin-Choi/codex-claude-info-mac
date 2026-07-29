#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."
zsh scripts/build-app.sh

RELEASE_NAME="Codex-Info-0.2.0"
DMG_PATH="$PWD/dist/$RELEASE_NAME.dmg"
ZIP_PATH="$PWD/dist/$RELEASE_NAME.zip"
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT

cp -R "dist/Codex Info.app" "$STAGE_DIR/Codex Info.app"
cp "Resources/설치 안내.txt" "$STAGE_DIR/설치 안내.txt"
ln -s /Applications "$STAGE_DIR/Applications"

rm -f "$DMG_PATH" "$ZIP_PATH"
hdiutil create \
  -volname "Codex Info" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

ditto -c -k --sequesterRsrc --keepParent \
  "dist/Codex Info.app" \
  "$ZIP_PATH"

codesign --verify --deep --strict "dist/Codex Info.app"
shasum -a 256 "$DMG_PATH" "$ZIP_PATH"
echo "$DMG_PATH"
echo "$ZIP_PATH"
