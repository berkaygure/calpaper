#!/bin/bash
set -euo pipefail

# --- Configuration ---
APP_NAME="calpaper"
VERSION="1.0"
SCHEME="calpaper"
BUILD_DIR="$(pwd)/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"

echo "=== Building ${APP_NAME} v${VERSION} ==="

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# --- Step 1: Archive ---
echo ">>> Archiving..."
xcodebuild archive \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    | tail -3

# --- Step 2: Export app from archive ---
echo ">>> Exporting app..."

# Create export options plist
cat > "${BUILD_DIR}/ExportOptions.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

# Try exporting; if it fails (no signing identity), copy from archive directly
if xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist" \
    -exportPath "${EXPORT_PATH}" 2>/dev/null; then
    APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"
else
    echo ">>> Export failed, copying app from archive directly..."
    mkdir -p "${EXPORT_PATH}"
    cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/"
    APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"
fi

if [ ! -d "${APP_PATH}" ]; then
    echo "ERROR: App not found at ${APP_PATH}"
    exit 1
fi

echo ">>> App built at: ${APP_PATH}"

# --- Step 3: Create DMG ---
echo ">>> Creating DMG..."

DMG_STAGING="${BUILD_DIR}/dmg-staging"
rm -rf "${DMG_STAGING}"
mkdir -p "${DMG_STAGING}"

# Copy app
cp -R "${APP_PATH}" "${DMG_STAGING}/"

# Create Applications symlink for drag-to-install
ln -s /Applications "${DMG_STAGING}/Applications"

# Create DMG
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

echo ""
echo "=== Done! ==="
echo "DMG: ${DMG_PATH}"
echo "Size: $(du -h "${DMG_PATH}" | cut -f1)"
