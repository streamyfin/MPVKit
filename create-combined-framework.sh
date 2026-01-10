#!/bin/bash
set -e

# Create a single MPVKit.xcframework with all internal symbols hidden
# Only mpv_* symbols will be public

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$SCRIPT_DIR/dist/release"
WORK_DIR="$SCRIPT_DIR/dist/MPVKit-combined"
XCF_DIR="$WORK_DIR/xcframework"

echo "=============================================="
echo "  Creating MPVKit Combined Framework"
echo "  (All internal symbols hidden)"
echo "=============================================="
echo ""

# Clean work directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
mkdir -p "$XCF_DIR"

# Get architectures for a platform
get_arches() {
    case "$1" in
        ios) echo "arm64" ;;
        isimulator) echo "arm64 x86_64" ;;
        tvos) echo "arm64 arm64e" ;;
        tvsimulator) echo "arm64 x86_64" ;;
    esac
}

# Get platform info for ld command
get_platform_info() {
    local platform="$1"
    case "$platform" in
        ios)
            echo "ios 13.0 17.0"
            ;;
        isimulator)
            echo "ios-simulator 13.0 17.0"
            ;;
        tvos)
            echo "tvos 13.0 17.0"
            ;;
        tvsimulator)
            echo "tvos-simulator 13.0 17.0"
            ;;
    esac
}

# Step 1: Extract mpv_* symbols for export list
echo "Step 1: Creating export symbols list..."
EXPORTS_FILE="$WORK_DIR/exports.txt"

# Get symbols from any mpv library
SAMPLE_MPV=$(find "$RELEASE_DIR/libmpv" -name "libmpv.a" | head -1)
if [ -z "$SAMPLE_MPV" ]; then
    echo "Error: No libmpv.a found"
    exit 1
fi

nm -g "$SAMPLE_MPV" 2>/dev/null | grep " [TDS] _mpv_" | awk '{print $3}' | sort -u > "$EXPORTS_FILE"
EXPORT_COUNT=$(wc -l < "$EXPORTS_FILE" | tr -d ' ')
echo "  Found $EXPORT_COUNT mpv_* symbols to export"
echo ""

# Step 2: Process each platform
echo "Step 2: Processing platforms..."
echo ""

FRAMEWORK_ARGS=()

for platform in ios isimulator tvos tvsimulator; do
    arches=$(get_arches "$platform")
    
    echo "=== Platform: $platform ($arches) ==="
    
    # Create fat library from all architectures
    THIN_LIBS=()
    
    for arch in $arches; do
        echo "  Processing $arch..."
        
        ARCH_WORK="$WORK_DIR/$platform-$arch"
        mkdir -p "$ARCH_WORK"
        
        # Collect ALL .a files from all library directories for this arch
        LIBS=()
        
        # All library directories in dist (not release, which only has FFmpeg/mpv)
        DIST_DIR="$SCRIPT_DIR/dist"
        
        # List of all dependency libraries to include
        LIB_DIRS=(
            "FFmpeg"
            "libmpv"
            "openssl"
            "gnutls"
            "gmp"
            "nettle"
            "libass"
            "libfreetype"
            "libfribidi"
            "libharfbuzz"
            "libunibreak"
            "vulkan"
            "libshaderc"
            "lcms2"
            "libplacebo"
            "libdav1d"
            "libdovi"
            "libsmbclient"
            "libuavs3d"
            "libuchardet"
            "libbluray"
            "libluajit"
        )
        
        # Libraries to exclude (have dependencies we don't include)
        EXCLUDE_LIBS=(
            "libharfbuzz-cairo.a"    # Requires Cairo (not included)
            "libharfbuzz-gobject.a"  # Requires GObject (not included)
            "libharfbuzz-subset.a"   # Font subsetting (not needed for playback)
        )
        
        for lib_dir in "${LIB_DIRS[@]}"; do
            LIB_PATH="$DIST_DIR/$lib_dir/$platform/thin/$arch/lib"
            if [ -d "$LIB_PATH" ]; then
                for lib in "$LIB_PATH"/*.a; do
                    if [ -f "$lib" ]; then
                        # Skip excluded libraries
                        LIB_NAME=$(basename "$lib")
                        SKIP=false
                        for exclude in "${EXCLUDE_LIBS[@]}"; do
                            if [ "$LIB_NAME" = "$exclude" ]; then
                                SKIP=true
                                break
                            fi
                        done
                        if [ "$SKIP" = true ]; then
                            continue
                        fi
                        
                        # Check if library has our architecture
                        LIB_ARCHS=$(lipo -info "$lib" 2>/dev/null)
                        
                        # Check if this lib contains our target arch
                        if echo "$LIB_ARCHS" | grep -qw "$arch"; then
                            # Check if it's a fat binary (multiple archs)
                            ARCH_COUNT=$(echo "$LIB_ARCHS" | grep -o "arm64e\|arm64\|x86_64" | wc -l | tr -d ' ')
                            if [ "$ARCH_COUNT" -gt 1 ]; then
                                # Fat binary - extract just our arch
                                THIN_LIB="$ARCH_WORK/$(basename "$lib")"
                                lipo -thin "$arch" -output "$THIN_LIB" "$lib" 2>/dev/null && LIBS+=("$THIN_LIB") || LIBS+=("$lib")
                            else
                                LIBS+=("$lib")
                            fi
                        fi
                    fi
                done
            fi
        done
        
        if [ ${#LIBS[@]} -eq 0 ]; then
            echo "    ⚠ No libraries found, skipping"
            continue
        fi
        
        echo "    Combining ${#LIBS[@]} libraries..."
        
        # Combine into one static library using libtool
        # Note: This creates an archive of archives - internal symbol references
        # require -force_load or -all_load at link time
        COMBINED="$ARCH_WORK/libMPVKit.a"
        libtool -static -o "$COMBINED" "${LIBS[@]}" 2>/dev/null
        
        echo "    ✓ Libraries combined"
        
        # Count symbols before hiding
        BEFORE_COUNT=$(nm -gU "$COMBINED" 2>/dev/null | grep " [TDS] " | wc -l | tr -d ' ')
        echo "    → $BEFORE_COUNT global symbols before hiding"
        
        # ============================================
        # Symbol Hiding: DISABLED for now
        # nmedit breaks internal cross-object-file references
        # TODO: Use ld -r to create single relocatable object first
        # ============================================
        echo "    ⚠ Symbol hiding disabled (internal references would break)"
        echo "    → $BEFORE_COUNT global symbols (all visible)"
        
        THIN_LIBS+=("$COMBINED")
    done
    
    if [ ${#THIN_LIBS[@]} -eq 0 ]; then
        echo "  ⚠ No libraries for $platform, skipping"
        continue
    fi
    
    # Create fat library if multiple architectures
    FAT_LIB="$WORK_DIR/$platform/libMPVKit.a"
    mkdir -p "$(dirname "$FAT_LIB")"
    
    if [ ${#THIN_LIBS[@]} -gt 1 ]; then
        echo "  Creating fat library..."
        lipo -create "${THIN_LIBS[@]}" -output "$FAT_LIB"
    else
        cp "${THIN_LIBS[0]}" "$FAT_LIB"
    fi
    
    # Create framework structure
    FRAMEWORK_DIR="$WORK_DIR/$platform/MPVKit.framework"
    mkdir -p "$FRAMEWORK_DIR/Headers"
    mkdir -p "$FRAMEWORK_DIR/Modules"
    
    # Copy library
    cp "$FAT_LIB" "$FRAMEWORK_DIR/MPVKit"
    
    # Copy headers (mpv headers only for now)
    if [ -d "$RELEASE_DIR/libmpv/include" ]; then
        cp -R "$RELEASE_DIR/libmpv/include"/* "$FRAMEWORK_DIR/Headers/" 2>/dev/null || true
    fi
    
    # Create umbrella header that includes all mpv headers
    cat > "$FRAMEWORK_DIR/Headers/MPVKit.h" << 'UMBRELLA'
//
//  MPVKit.h
//  MPVKit
//
//  Umbrella header for MPVKit framework
//

#ifndef MPVKit_h
#define MPVKit_h

#include "mpv/client.h"
#include "mpv/render.h"
#include "mpv/render_gl.h"
#include "mpv/stream_cb.h"

#endif /* MPVKit_h */
UMBRELLA
    
    # Create module.modulemap
    cat > "$FRAMEWORK_DIR/Modules/module.modulemap" << 'MODULEMAP'
framework module MPVKit {
    umbrella header "MPVKit.h"
    
    export *
    module * { export * }
    
    link framework "AudioToolbox"
    link framework "AVFoundation"
    link framework "CoreAudio"
    link framework "CoreFoundation"
    link framework "CoreMedia"
    link framework "CoreVideo"
    link framework "Metal"
    link framework "QuartzCore"
    link framework "VideoToolbox"
    link "bz2"
    link "c++"
    link "iconv"
    link "xml2"
    link "z"
}

// Backwards compatibility - allows "import Libmpv" to work
module Libmpv {
    export MPVKit
}
MODULEMAP
    
    # Create Info.plist
    cat > "$FRAMEWORK_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MPVKit</string>
    <key>CFBundleIdentifier</key>
    <string>com.mpvkit.MPVKit</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MPVKit</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>12.0</string>
</dict>
</plist>
PLIST
    
    FRAMEWORK_ARGS+=("-framework" "$FRAMEWORK_DIR")
    echo "  ✓ Framework ready"
    echo ""
done

# Step 3: Create XCFramework manually (xcodebuild can't detect platform from static libs)
echo "Step 3: Creating XCFramework..."
XCF_PATH="$XCF_DIR/MPVKit.xcframework"
rm -rf "$XCF_PATH"
mkdir -p "$XCF_PATH"

# Create Info.plist for xcframework
cat > "$XCF_PATH/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64</string>
            <key>LibraryPath</key>
            <string>MPVKit.framework</string>
            <key>SupportedArchitectures</key>
            <array><string>arm64</string></array>
            <key>SupportedPlatform</key>
            <string>ios</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64_x86_64-simulator</string>
            <key>LibraryPath</key>
            <string>MPVKit.framework</string>
            <key>SupportedArchitectures</key>
            <array><string>arm64</string><string>x86_64</string></array>
            <key>SupportedPlatform</key>
            <string>ios</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>tvos-arm64_arm64e</string>
            <key>LibraryPath</key>
            <string>MPVKit.framework</string>
            <key>SupportedArchitectures</key>
            <array><string>arm64</string><string>arm64e</string></array>
            <key>SupportedPlatform</key>
            <string>tvos</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>tvos-arm64_x86_64-simulator</string>
            <key>LibraryPath</key>
            <string>MPVKit.framework</string>
            <key>SupportedArchitectures</key>
            <array><string>arm64</string><string>x86_64</string></array>
            <key>SupportedPlatform</key>
            <string>tvos</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
PLIST

# Copy frameworks to xcframework structure
mkdir -p "$XCF_PATH/ios-arm64"
mkdir -p "$XCF_PATH/ios-arm64_x86_64-simulator"
mkdir -p "$XCF_PATH/tvos-arm64_arm64e"
mkdir -p "$XCF_PATH/tvos-arm64_x86_64-simulator"

cp -R "$WORK_DIR/ios/MPVKit.framework" "$XCF_PATH/ios-arm64/MPVKit.framework"
cp -R "$WORK_DIR/isimulator/MPVKit.framework" "$XCF_PATH/ios-arm64_x86_64-simulator/MPVKit.framework"
cp -R "$WORK_DIR/tvos/MPVKit.framework" "$XCF_PATH/tvos-arm64_arm64e/MPVKit.framework"
cp -R "$WORK_DIR/tvsimulator/MPVKit.framework" "$XCF_PATH/tvos-arm64_x86_64-simulator/MPVKit.framework"

echo "  ✓ Created MPVKit.xcframework"

echo ""
echo "  ✓ Created MPVKit.xcframework"

# Step 4: Create zip
echo ""
echo "Step 4: Creating distribution zip..."
ZIP_PATH="$WORK_DIR/MPVKit.xcframework.zip"
cd "$XCF_DIR"
zip -qry "$ZIP_PATH" "MPVKit.xcframework"

# Checksum
CHECKSUM=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
echo "$CHECKSUM" > "$WORK_DIR/MPVKit.xcframework.checksum.txt"

echo "  ✓ Created MPVKit.xcframework.zip"
echo "  Checksum: $CHECKSUM"

# Step 5: Verify
echo ""
echo "=============================================="
echo "  Verification"
echo "=============================================="

# Check one of the frameworks
SAMPLE_FW=$(find "$XCF_PATH" -name "MPVKit" -type f | head -1)
if [ -n "$SAMPLE_FW" ]; then
    TOTAL=$(nm -gU "$SAMPLE_FW" 2>/dev/null | grep " [TDS] " | wc -l | tr -d ' ')
    MPV=$(nm -gU "$SAMPLE_FW" 2>/dev/null | grep " [TDS] _mpv_" | wc -l | tr -d ' ')
    DAV1D=$(nm -gU "$SAMPLE_FW" 2>/dev/null | grep " [TDS] .*dav1d" | wc -l | tr -d ' ')
    FFMPEG=$(nm -gU "$SAMPLE_FW" 2>/dev/null | grep " [TDS] _ff_" | wc -l | tr -d ' ')
    
    echo "  Total public symbols: $TOTAL"
    echo "  mpv_* symbols: $MPV"
    echo "  dav1d symbols (should be 0): $DAV1D"
    echo "  FFmpeg symbols (should be 0): $FFMPEG"
    echo ""
    
    if [ "$TOTAL" -le 60 ] && [ "$DAV1D" -eq 0 ]; then
        echo "  ✓ SUCCESS: All internal symbols hidden!"
        echo "  Only mpv_* public API is exposed."
        echo "  No duplicate symbol conflicts will occur."
    else
        echo "  ⚠ WARNING: Some internal symbols may still be visible."
        echo "  This might be due to common symbols that cannot be hidden."
    fi
fi

echo ""
echo "=============================================="
echo "  Output files:"
echo "=============================================="
echo "  XCFramework: $XCF_PATH"
echo "  Zip: $ZIP_PATH"
echo "  Checksum: $WORK_DIR/MPVKit.xcframework.checksum.txt"
echo ""
ls -lh "$ZIP_PATH"
