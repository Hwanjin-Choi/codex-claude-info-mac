#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."
swift build -c release
zsh scripts/generate-icons.sh

APP_DIR="$PWD/dist/Codex Info.app"
CONTENTS="$APP_DIR/Contents"
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"
cp ".build/release/CodexInfo" "$CONTENTS/MacOS/CodexInfo"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
PET_SOURCE="$HOME/.codex/pets/jjanggu-codi/spritesheet.webp"
if [[ -f "$PET_SOURCE" ]]; then
  cp "$PET_SOURCE" "$CONTENTS/Resources/jjanggu-codi.webp"
fi
cp ".build/icon-assets/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
cp "Resources/THIRD_PARTY_NOTICES.txt" "$CONTENTS/Resources/THIRD_PARTY_NOTICES.txt"
codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
