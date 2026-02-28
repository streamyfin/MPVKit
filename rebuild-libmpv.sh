#!/bin/bash
set -e

cd "$(dirname "$0")"

# Check if this is a GPL build (default to GPL since that's what you're using)
GPL_SUFFIX="-GPL"
OUTPUT_NAME="Libmpv${GPL_SUFFIX}"

echo "🔨 Rebuilding libmpv for all platforms (GPL build)..."

# Define all platforms (iOS and tvOS only, no macOS)
PLATFORMS="ios isimulator tvos tvsimulator"

# Get architectures for each platform (must match original build)
get_archs() {
    case "$1" in
        ios) echo "arm64" ;;
        isimulator) echo "arm64 x86_64" ;;
        tvos) echo "arm64 arm64e" ;;
        tvsimulator) echo "arm64 x86_64" ;;
        *) echo "arm64" ;;
    esac
}

# Check which platforms have scratch directories
AVAILABLE_PLATFORMS=""
for platform in $PLATFORMS; do
    archs=$(get_archs "$platform")
    first_arch="${archs%% *}"
    scratch_dir="dist/libmpv/${platform}/scratch/${first_arch}"
    
    if [ -d "$scratch_dir" ]; then
        AVAILABLE_PLATFORMS="$AVAILABLE_PLATFORMS $platform"
        echo "  ✓ Found $platform scratch directory"
    else
        echo "  ⚠ Skipping $platform (no scratch directory)"
    fi
done

# Trim leading space
AVAILABLE_PLATFORMS="${AVAILABLE_PLATFORMS# }"

if [ -z "$AVAILABLE_PLATFORMS" ]; then
    echo "❌ Error: No platform scratch directories found"
    echo "   You need to run a full build first:"
    echo "   make gpl platform=ios,tvos,tvsimulator,isimulator"
    exit 1
fi

# Build each platform
echo ""
echo "🔧 Building platforms..."
for platform in $AVAILABLE_PLATFORMS; do
    archs=$(get_archs "$platform")
    for arch in $archs; do
        scratch_dir="dist/libmpv/${platform}/scratch/${arch}"
        if [ -d "$scratch_dir" ]; then
            echo "  → Building ${platform} ${arch}..."
            ninja -C "$scratch_dir"
        fi
    done
done

# Copy to frameworks
echo ""
echo "📦 Copying to frameworks..."
for platform in $AVAILABLE_PLATFORMS; do
    archs=$(get_archs "$platform")
    first_arch="${archs%% *}"
    framework_dir="dist/libmpv/${platform}/Libmpv.framework"
    
    if [ -d "$framework_dir" ]; then
        echo "  → Copying ${platform}..."
        cp "dist/libmpv/${platform}/scratch/${first_arch}/libmpv.a" "${framework_dir}/Libmpv"
    fi
done

# Copy to thin directories (used by create-combined-framework.sh)
echo ""
echo "📦 Copying to thin directories (for combined framework)..."
for platform in $AVAILABLE_PLATFORMS; do
    archs=$(get_archs "$platform")
    for arch in $archs; do
        scratch_lib="dist/libmpv/${platform}/scratch/${arch}/libmpv.a"
        thin_dir="dist/libmpv/${platform}/thin/${arch}/lib"
        
        if [ -f "$scratch_lib" ] && [ -d "$thin_dir" ]; then
            cp "$scratch_lib" "$thin_dir/libmpv.a"
            echo "  ✓ ${platform}/${arch}"
        fi
    done
done

# Build xcframework arguments
echo ""
echo "🏗️  Creating xcframework..."
XCFRAMEWORK_ARGS=""
for platform in $AVAILABLE_PLATFORMS; do
    framework_dir="dist/libmpv/${platform}/Libmpv.framework"
    if [ -d "$framework_dir" ]; then
        XCFRAMEWORK_ARGS="$XCFRAMEWORK_ARGS -framework $framework_dir"
    fi
done

# Create the xcframework
rm -rf "dist/release/${OUTPUT_NAME}.xcframework"
xcodebuild -create-xcframework \
    $XCFRAMEWORK_ARGS \
    -output "dist/release/${OUTPUT_NAME}.xcframework"

# Zip for SPM (but keep xcframework for local development)
echo "📦 Zipping for SPM..."
cd dist/release
rm -f "${OUTPUT_NAME}.xcframework.zip"
zip -rq "${OUTPUT_NAME}.xcframework.zip" "${OUTPUT_NAME}.xcframework"
# NOTE: Keep xcframework directory for local Package.swift references

# Calculate checksum for Package.swift
echo ""
echo "📋 Checksum for Package.swift:"
CHECKSUM=$(shasum -a 256 "${OUTPUT_NAME}.xcframework.zip" | awk '{print $1}')
echo "   ${OUTPUT_NAME}.xcframework.zip: $CHECKSUM"

cd ../..

# Optionally create combined framework (for CocoaPods distribution)
if [ "$1" = "--combined" ] || [ "$1" = "-c" ]; then
    echo ""
    echo "🔗 Creating combined framework..."
    ./create-combined-framework.sh
fi

echo ""
echo "✅ Done! Platforms built: $AVAILABLE_PLATFORMS"
echo "   Output: dist/release/${OUTPUT_NAME}.xcframework"
echo "   Zip:    dist/release/${OUTPUT_NAME}.xcframework.zip"
echo ""
echo "📌 Next steps:"
echo "   • For local development: Clean build in Xcode (Cmd+Shift+K)"
echo "   • For CocoaPods release: Run './create-combined-framework.sh'"
echo "   • Or use: './rebuild-libmpv.sh --combined' to do both"
