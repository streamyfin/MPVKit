#!/bin/bash
set -e

cd "$(dirname "$0")"

VERSION="0.40.0-av"
BUNDLE_NAME="MPVKit-GPL-Frameworks"
BUNDLE_DIR="dist/cocoapods/${BUNDLE_NAME}"
OUTPUT_ZIP="dist/cocoapods/${BUNDLE_NAME}.zip"

echo "🔨 Creating CocoaPods framework bundle for ${VERSION}..."

# Create clean bundle directory
rm -rf dist/cocoapods
mkdir -p "${BUNDLE_DIR}/Frameworks"

# Download xcframeworks from GitHub release
echo "📥 Downloading xcframeworks from release..."

GITHUB_RELEASE="https://github.com/Alexk2309/MPVKit/releases/download/${VERSION}"

# MPVKit frameworks
download_framework() {
    local name=$1
    local url=$2
    echo "  → Downloading ${name}..."
    curl -sL "${url}" -o "/tmp/${name}.zip"
    unzip -q "/tmp/${name}.zip" -d "${BUNDLE_DIR}/Frameworks/"
    rm "/tmp/${name}.zip"
}

# GPL frameworks from our release
download_framework "Libmpv-GPL" "${GITHUB_RELEASE}/Libmpv-GPL.xcframework.zip"
download_framework "Libavcodec-GPL" "${GITHUB_RELEASE}/Libavcodec-GPL.xcframework.zip"
download_framework "Libavdevice-GPL" "${GITHUB_RELEASE}/Libavdevice-GPL.xcframework.zip"
download_framework "Libavfilter-GPL" "${GITHUB_RELEASE}/Libavfilter-GPL.xcframework.zip"
download_framework "Libavformat-GPL" "${GITHUB_RELEASE}/Libavformat-GPL.xcframework.zip"
download_framework "Libavutil-GPL" "${GITHUB_RELEASE}/Libavutil-GPL.xcframework.zip"
download_framework "Libswresample-GPL" "${GITHUB_RELEASE}/Libswresample-GPL.xcframework.zip"
download_framework "Libswscale-GPL" "${GITHUB_RELEASE}/Libswscale-GPL.xcframework.zip"

# Dependencies from mpvkit releases
echo "📥 Downloading dependencies..."
download_framework "Libcrypto" "https://github.com/mpvkit/openssl-build/releases/download/3.3.2-xcode/Libcrypto.xcframework.zip"
download_framework "Libssl" "https://github.com/mpvkit/openssl-build/releases/download/3.3.2-xcode/Libssl.xcframework.zip"
download_framework "gmp" "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/gmp.xcframework.zip"
download_framework "nettle" "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/nettle.xcframework.zip"
download_framework "hogweed" "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/hogweed.xcframework.zip"
download_framework "gnutls" "https://github.com/mpvkit/gnutls-build/releases/download/3.8.8-xcode/gnutls.xcframework.zip"
download_framework "Libunibreak" "https://github.com/mpvkit/libass-build/releases/download/0.17.4/Libunibreak.xcframework.zip"
download_framework "Libfreetype" "https://github.com/mpvkit/libass-build/releases/download/0.17.4/Libfreetype.xcframework.zip"
download_framework "Libfribidi" "https://github.com/mpvkit/libass-build/releases/download/0.17.4/Libfribidi.xcframework.zip"
download_framework "Libharfbuzz" "https://github.com/mpvkit/libass-build/releases/download/0.17.4/Libharfbuzz.xcframework.zip"
download_framework "Libass" "https://github.com/mpvkit/libass-build/releases/download/0.17.4/Libass.xcframework.zip"
download_framework "Libsmbclient" "https://github.com/mpvkit/libsmbclient-build/releases/download/4.15.13-xcode/Libsmbclient.xcframework.zip"
download_framework "Libbluray" "https://github.com/mpvkit/libbluray-build/releases/download/1.3.4-xcode/Libbluray.xcframework.zip"
download_framework "Libuavs3d" "https://github.com/mpvkit/libuavs3d-build/releases/download/1.2.1-xcode/Libuavs3d.xcframework.zip"
download_framework "Libdovi" "https://github.com/mpvkit/libdovi-build/releases/download/3.3.1-xcode/Libdovi.xcframework.zip"
download_framework "MoltenVK" "https://github.com/mpvkit/moltenvk-build/releases/download/1.4.0-xcode/MoltenVK.xcframework.zip"
download_framework "Libshaderc_combined" "https://github.com/mpvkit/libshaderc-build/releases/download/2025.4.0-xcode/Libshaderc_combined.xcframework.zip"
download_framework "lcms2" "https://github.com/mpvkit/lcms2-build/releases/download/2.16.0-xcode/lcms2.xcframework.zip"
download_framework "Libplacebo" "https://github.com/mpvkit/libplacebo-build/releases/download/7.351.0-xcode/Libplacebo.xcframework.zip"
download_framework "Libdav1d" "https://github.com/mpvkit/libdav1d-build/releases/download/1.5.2-xcode/Libdav1d.xcframework.zip"
download_framework "Libuchardet" "https://github.com/mpvkit/libuchardet-build/releases/download/0.0.8-xcode/Libuchardet.xcframework.zip"

# Rename GPL frameworks to remove -GPL suffix for CocoaPods
echo "📝 Renaming frameworks..."
cd "${BUNDLE_DIR}/Frameworks"
for f in *-GPL.xcframework; do
    if [ -d "$f" ]; then
        newname="${f/-GPL/}"
        mv "$f" "$newname"
        echo "  → Renamed $f to $newname"
    fi
done
cd - > /dev/null

# Create zip
echo "📦 Creating zip bundle..."
cd dist/cocoapods
rm -f "${BUNDLE_NAME}.zip"
zip -rq "${BUNDLE_NAME}.zip" "${BUNDLE_NAME}"
cd - > /dev/null

# Calculate checksum
CHECKSUM=$(shasum -a 256 "${OUTPUT_ZIP}" | awk '{print $1}')

echo ""
echo "✅ Done!"
echo "   Output: ${OUTPUT_ZIP}"
echo "   Size: $(du -h "${OUTPUT_ZIP}" | cut -f1)"
echo "   Checksum: ${CHECKSUM}"
echo ""
echo "📤 Upload this file to GitHub release ${VERSION}:"
echo "   gh release upload ${VERSION} ${OUTPUT_ZIP}"
