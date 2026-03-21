#!/bin/bash
set -euo pipefail

# ============================================================
# Calpaper Release Script
# Creates a signed DMG and generates the Sparkle appcast.
#
# Usage:
#   ./scripts/create-release.sh [version]
# ============================================================

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(grep 'MARKETING_VERSION' calpaper.xcodeproj/project.pbxproj | head -1 | sed 's/.*= //;s/;//;s/ //g')
    echo "Using version from project: ${VERSION}"
fi

APP_NAME="Calpaper"
SCHEME="calpaper"
BUILD_DIR="$(pwd)/build"
RELEASE_DIR="$(pwd)/releases"
SPARKLE_BIN="${BUILD_DIR}/sparkle-tools"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
DMG_PATH="${RELEASE_DIR}/${DMG_NAME}"

echo "=== Creating ${APP_NAME} v${VERSION} Release ==="

# Clean
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${RELEASE_DIR}"

# --- Download Sparkle tools if needed ---
if [ ! -f "${SPARKLE_BIN}/sign_update" ]; then
    echo ">>> Downloading Sparkle tools..."
    SPARKLE_TAG="2.6.4"
    TMPDIR_DL=$(mktemp -d)
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_TAG}/Sparkle-${SPARKLE_TAG}.tar.xz" \
        -o "${TMPDIR_DL}/sparkle.tar.xz"
    mkdir -p "${SPARKLE_BIN}"
    tar -xf "${TMPDIR_DL}/sparkle.tar.xz" -C "${TMPDIR_DL}" ./bin/sign_update ./bin/generate_keys
    mv "${TMPDIR_DL}/bin/sign_update" "${SPARKLE_BIN}/"
    mv "${TMPDIR_DL}/bin/generate_keys" "${SPARKLE_BIN}/"
    rm -rf "${TMPDIR_DL}"
fi

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

# --- Step 4: Sign with Sparkle ---
echo ">>> Signing DMG with Sparkle EdDSA key..."
SIGNATURE=""
if [ -f "${SPARKLE_BIN}/sign_update" ]; then
    SIGNATURE=$("${SPARKLE_BIN}/sign_update" "${DMG_PATH}" 2>&1 || echo "SIGN_FAILED")
    if [[ "$SIGNATURE" == *"SIGN_FAILED"* ]] || [[ "$SIGNATURE" == *"Error"* ]]; then
        echo "WARNING: Could not sign. Run ./scripts/generate-keys.sh first."
        SIGNATURE=""
    else
        echo "    Signature: ${SIGNATURE}"
    fi
fi

# --- Step 5: Generate appcast.xml ---
echo ">>> Generating appcast.xml..."
DMG_SIZE=$(stat -f%z "${DMG_PATH}")
BASE_URL="https://github.com/berkaygure/calpaper/releases/download/v${VERSION}"

# Parse edSignature and length from sign_update output
ED_SIG=""
if [ -n "$SIGNATURE" ]; then
    ED_SIG=$(echo "$SIGNATURE" | grep -o 'edSignature="[^"]*"' | sed 's/edSignature="//;s/"$//' || echo "")
fi

ENCLOSURE_SIG=""
if [ -n "$ED_SIG" ]; then
    ENCLOSURE_SIG="sparkle:edSignature=\"${ED_SIG}\""
fi

cat > "${RELEASE_DIR}/appcast.xml" << APPCAST
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Calpaper Updates</title>
    <link>https://raw.githubusercontent.com/berkaygure/calpaper/main/appcast.xml</link>
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
          <li>Auto-update support</li>
        </ul>
      ]]></description>
      <enclosure
        url="${BASE_URL}/${DMG_NAME}"
        length="${DMG_SIZE}"
        type="application/octet-stream"
        ${ENCLOSURE_SIG}
      />
    </item>
  </channel>
</rss>
APPCAST

# Also copy to repo root for raw.githubusercontent serving
cp "${RELEASE_DIR}/appcast.xml" "$(pwd)/appcast.xml"

echo ""
echo "=== Release v${VERSION} Ready ==="
echo ""
echo "Files:"
echo "  DMG:     ${DMG_PATH} ($(du -h "${DMG_PATH}" | cut -f1))"
echo "  Appcast: ${RELEASE_DIR}/appcast.xml"
echo ""
echo "To publish on GitHub:"
echo "  git add appcast.xml && git commit -m 'release: v${VERSION}'"
echo "  git tag v${VERSION} && git push && git push --tags"
echo "  gh release create v${VERSION} '${DMG_PATH}' --title 'Calpaper v${VERSION}'"
