#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."
zsh scripts/build-app.sh

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
RELEASE_NAME="Codex-Claude-Info-$VERSION-macos-universal"
DMG_PATH="$PWD/dist/$RELEASE_NAME.dmg"
ZIP_PATH="$PWD/dist/$RELEASE_NAME.zip"
STAGE_DIR="$(mktemp -d)"
trap '[[ "$STAGE_DIR" == */tmp.* ]] && rm -rf -- "$STAGE_DIR"' EXIT

cp -R "dist/Codex & Claude Info.app" "$STAGE_DIR/Codex & Claude Info.app"
cp "Resources/설치 안내.txt" "$STAGE_DIR/설치 안내.txt"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "Codex & Claude Info" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

ditto -c -k --sequesterRsrc --keepParent \
  "dist/Codex & Claude Info.app" \
  "$ZIP_PATH"

codesign --verify --deep --strict "dist/Codex & Claude Info.app"
(cd dist && shasum -a 256 "$RELEASE_NAME.dmg" "$RELEASE_NAME.zip" > SHA256SUMS-macos.txt)
echo "$DMG_PATH"
echo "$ZIP_PATH"
