#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."
for ARCH in arm64 x86_64; do
  swift build -c release --triple "$ARCH-apple-macosx14.0"
done
zsh scripts/generate-icons.sh

APP_DIR="$PWD/dist/Codex & Claude Info.app"
CONTENTS="$APP_DIR/Contents"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"
for EXECUTABLE in CodexInfo ClaudeInfoBridge; do
  lipo -create ".build/arm64-apple-macosx/release/$EXECUTABLE" \
    ".build/x86_64-apple-macosx/release/$EXECUTABLE" \
    -output "$CONTENTS/MacOS/$EXECUTABLE"
  lipo "$CONTENTS/MacOS/$EXECUTABLE" -verify_arch arm64 x86_64
done
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
cp "windows/public/pet.webp" "$CONTENTS/Resources/jjanggu-codi.webp"
cp ".build/icon-assets/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
cp "Resources/THIRD_PARTY_NOTICES.txt" "$CONTENTS/Resources/THIRD_PARTY_NOTICES.txt"
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
echo "$APP_DIR"
