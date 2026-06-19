#!/bin/bash
set -euo pipefail

# KeyLoom Release Build Script
# Builds, signs, and prepares the app for distribution
#
# Usage:
#   ./scripts/build-release.sh          – Development-signed build
#   DISTRIBUTION=1 ./scripts/build-release.sh – Distribution-signed build

PROJECT="KeyLoom.xcodeproj"
SCHEME="KeyLoom"
CONFIGURATION="Release"
BUILD_DIR="build"

echo "=== KeyLoom Release Build ==="
echo "Scheme: $SCHEME | Configuration: $CONFIGURATION"

# Clean
echo ""
echo "Cleaning..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" clean

# Build
echo ""
echo "Building..."
if [ "${DISTRIBUTION:-0}" = "1" ]; then
    # Distribution build (for notarization)
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$BUILD_DIR" \
        CODE_SIGN_STYLE="Manual" \
        CODE_SIGN_IDENTITY="Developer ID Application" \
        OTHER_CODE_SIGN_FLAGS="--timestamp" \
        build
else
    # Development build
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$BUILD_DIR" \
        build
fi

APP_PATH="$BUILD_DIR/Build/Products/$CONFIGURATION/$SCHEME.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "Build complete: $APP_PATH"
    
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "?")
    echo "Version: $VERSION"
    
    # Create DMG
    echo ""
    echo "Creating DMG..."
    DMG_NAME="KeyLoom-$VERSION.dmg"
    DMG_TEMP="$BUILD_DIR/KeyLoom-$VERSION-tmp.dmg"
    DMG_VOLUME="KeyLoom"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    BG_IMG="$SCRIPT_DIR/dmg-background.png"
    WINDOW_X=200; WINDOW_Y=120; WINDOW_W=600; WINDOW_H=400
    ICON_SIZE=90
    APP_X=150; APP_Y=180
    LINK_X=420; LINK_Y=180

    mkdir -p "$BUILD_DIR/DMG"
    cp -R "$APP_PATH" "$BUILD_DIR/DMG/"
    ln -s /Applications "$BUILD_DIR/DMG/Applications"

    # Create read-write DMG first
    hdiutil create -volname "$DMG_VOLUME" -srcfolder "$BUILD_DIR/DMG" \
        -ov -format UDRW "$DMG_TEMP"
    rm -rf "$BUILD_DIR/DMG"

    # Mount and customize
    MOUNT_DIR="/Volumes/$DMG_VOLUME"
    hdiutil attach "$DMG_TEMP" -readwrite -noverify -noautoopen -quiet

    # Set window appearance via AppleScript
    osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$DMG_VOLUME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {$WINDOW_X, $WINDOW_Y, $WINDOW_X + $WINDOW_W, $WINDOW_Y + $WINDOW_H}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        set background picture of viewOptions to POSIX file "$BG_IMG"
        set position of item "$SCHEME.app" of container window to {$APP_X, $APP_Y}
        set position of item "Applications" of container window to {$LINK_X, $LINK_Y}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

    # Ensure writes are flushed
    sync
    hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || hdiutil detach "$MOUNT_DIR" -force -quiet

    # Convert to compressed read-only DMG
    hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$BUILD_DIR/$DMG_NAME"
    rm -f "$DMG_TEMP"
    echo "DMG: $BUILD_DIR/$DMG_NAME"
else
    echo "Warning: App not found at expected path. Build may have failed."
fi

echo ""
echo "=== Build complete ==="
