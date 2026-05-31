#!/bin/bash
#
# Build TradeTracker as a Release macOS app and install it to /Applications.
# Usage:  ./build-mac.sh
#
set -euo pipefail

# Full Xcode toolchain (not the Command Line Tools default).
XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

PROJECT_DIR="$(cd "$(dirname "$0")/TradeTracker" && pwd)"
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)/.build-mac"
APP_NAME="TradeTracker.app"
DEST="/Applications/$APP_NAME"

echo "▶︎ Building Release (native macOS)…"
"$XCODEBUILD" \
  -project "$PROJECT_DIR/TradeTracker.xcodeproj" \
  -scheme TradeTracker \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  build | tail -5

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME"

# Fallback: locate the product if it isn't where we expect.
if [ ! -d "$BUILT_APP" ]; then
  BUILT_APP="$(find "$BUILD_DIR/Build/Products" -maxdepth 2 -name "$APP_NAME" -type d 2>/dev/null | head -1)"
fi

if [ -z "${BUILT_APP:-}" ] || [ ! -d "$BUILT_APP" ]; then
  echo "✗ Build product not found under $BUILD_DIR/Build/Products"
  exit 1
fi

echo "▶︎ Installing to /Applications…"
rm -rf "$DEST"
cp -R "$BUILT_APP" "$DEST"

echo "✓ Installed: $DEST"
echo "  Launch from Spotlight/Launchpad, or run:  open \"$DEST\""
