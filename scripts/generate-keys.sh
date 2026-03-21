#!/bin/bash
set -euo pipefail

# ============================================================
# Generate Sparkle EdDSA key pair for signing updates.
# Run this ONCE. The private key is stored in your Keychain.
# The public key must be set in Info.plist as SUPublicEDKey.
# ============================================================

BUILD_DIR="$(pwd)/build"
SPARKLE_BIN="${BUILD_DIR}/sparkle-tools"

mkdir -p "${SPARKLE_BIN}"

# Download Sparkle tools if needed
if [ ! -f "${SPARKLE_BIN}/generate_keys" ]; then
    echo ">>> Downloading Sparkle tools..."
    SPARKLE_TAG="2.6.4"
    TMPDIR=$(mktemp -d)
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_TAG}/Sparkle-${SPARKLE_TAG}.tar.xz" \
        -o "${TMPDIR}/sparkle.tar.xz"
    tar -xf "${TMPDIR}/sparkle.tar.xz" -C "${TMPDIR}" ./bin/generate_keys ./bin/sign_update
    mv "${TMPDIR}/bin/generate_keys" "${SPARKLE_BIN}/"
    mv "${TMPDIR}/bin/sign_update" "${SPARKLE_BIN}/"
    rm -rf "${TMPDIR}"
fi

if [ ! -f "${SPARKLE_BIN}/generate_keys" ]; then
    echo "ERROR: Could not find generate_keys tool"
    exit 1
fi

echo ">>> Generating EdDSA key pair..."
echo "The private key will be stored in your Keychain."
echo ""
"${SPARKLE_BIN}/generate_keys"
echo ""
echo "=== IMPORTANT ==="
echo "Copy the public key above and set it as SUPublicEDKey in calpaper/Info.plist"
