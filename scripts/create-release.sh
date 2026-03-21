#!/bin/bash
set -euo pipefail

# ============================================================
# Calpaper Release Script
# Creates a signed DMG and updates the Sparkle appcast.
#
# Usage:
#   ./scripts/create-release.sh [version]
#
# Prerequisites:
#   1. Generate a Sparkle EdDSA key pair (one-time):
#        ./scripts/generate-keys.sh
#   2. Set SUPublicEDKey in Info.plist (done by generate-keys.sh)
#   3. Host appcast.xml and DMGs at SUFeedURL location
# ============================================================

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    # Read from Xcode project
    VERSION=$(grep 'MARKETING_VERSION' calpaper.xcodeproj/project.pbxproj | head -1 | sed 's/.*= //;s/;//')
    echo "Using version from project: ${VERSION}"
fi

APP_NAME="Calpaper"
SCHEME="calpaper"
BUILD_DIR="$(pwd)/build"
RELEASE_DIR="$(pwd)/releases"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
DMG_PATH="${RELEASE_DIR}/${DMG_NAME}"
APPCAST_DIR="${RELEASE_DIR}"

echo "=== Creating ${APP_NAME} v${VERSION} Release ==="

# Clean
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${RELEASE_DIR}"

# --- Step 1: Archive ---
echo ">>> Archiving..."
xcodebuild archive \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    MARKETING_VERSION="${VERSION}" \
    2>&1 | tail -3

# --- Step 2: Export ---
echo ">>> Exporting..."
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

if ! xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist" \
    -exportPath "${EXPORT_PATH}" 2>/dev/null; then
    mkdir -p "${EXPORT_PATH}"
    cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/"
fi

APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"

# --- Step 3: Create DMG ---
echo ">>> Creating DMG..."
DMG_STAGING="${BUILD_DIR}/dmg-staging"
rm -rf "${DMG_STAGING}"
mkdir -p "${DMG_STAGING}"
cp -R "${APP_PATH}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# --- Step 4: Generate Sparkle signature ---
echo ">>> Generating Sparkle signature..."
SPARKLE_BIN="${BUILD_DIR}/sparkle-tools"

# Download Sparkle tools if needed
if [ ! -f "${SPARKLE_BIN}/sign_update" ]; then
    echo ">>> Downloading Sparkle tools..."
    mkdir -p "${SPARKLE_BIN}"
    SPARKLE_TAG="2.6.4"
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_TAG}/Sparkle-${SPARKLE_TAG}.tar.xz" \
        | tar -xJ -C "${SPARKLE_BIN}" --include='*/bin/sign_update' --include='*/bin/generate_keys' --strip-components=1 2>/dev/null || true

    # Try alternate path
    if [ ! -f "${SPARKLE_BIN}/sign_update" ] && [ -f "${SPARKLE_BIN}/bin/sign_update" ]; then
        mv "${SPARKLE_BIN}/bin/"* "${SPARKLE_BIN}/" 2>/dev/null || true
    fi
fi

DMG_SIZE=$(stat -f%z "${DMG_PATH}")
SIGNATURE=""

if [ -f "${SPARKLE_BIN}/sign_update" ]; then
    SIGNATURE=$("${SPARKLE_BIN}/sign_update" "${DMG_PATH}" 2>/dev/null || echo "")
fi

# --- Step 5: Generate appcast.xml ---
echo ">>> Generating appcast.xml..."

# Base URL — update this to your actual hosting location
BASE_URL="https://github.com/berkaygure/calpaper/releases/download/v${VERSION}"

cat > "${APPCAST_DIR}/appcast.xml" << APPCAST
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Calpaper Updates</title>
    <link>https://berkaygure.github.io/calpaper/appcast.xml</link>
    <language>en</language>
    <item>
      <title>Calpaper v${VERSION}</title>
      <pubDate>$(date -R)</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[
        <h2>What's New in v${VERSION}</h2>
        <ul>
          <li>Calendar wallpaper with curved split design</li>
          <li>10 built-in color themes</li>
          <li>Progress tracker mode</li>
          <li>EventKit integration</li>
          <li>Auto-update support via Sparkle</li>
        </ul>
      ]]></description>
      <enclosure
        url="${BASE_URL}/${DMG_NAME}"
        length="${DMG_SIZE}"
        type="application/octet-stream"
        ${SIGNATURE:+sparkle:edSignature=\"$(echo "$SIGNATURE" | grep -o 'sparkle:edSignature="[^"]*"' | sed 's/sparkle:edSignature="//' | sed 's/"$//')\"}
      />
    </item>
  </channel>
</rss>
APPCAST

echo ""
echo "=== Release v${VERSION} Ready ==="
echo ""
echo "Files:"
echo "  DMG:     ${DMG_PATH} ($(du -h "${DMG_PATH}" | cut -f1))"
echo "  Appcast: ${APPCAST_DIR}/appcast.xml"
echo ""
echo "To publish:"
echo "  1. Create GitHub release: gh release create v${VERSION} '${DMG_PATH}'"
echo "  2. Host appcast.xml at: https://berkaygure.github.io/calpaper/appcast.xml"
echo "     (or update SUFeedURL in Info.plist to match your hosting)"
echo ""
echo "If using GitHub Releases for the appcast too:"
echo "  gh release create v${VERSION} '${DMG_PATH}' '${APPCAST_DIR}/appcast.xml'"
