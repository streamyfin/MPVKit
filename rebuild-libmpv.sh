#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "🔨 Rebuilding libmpv..."

# Rebuild iOS arm64
echo "  → Building iOS arm64..."
ninja -C dist/libmpv/ios/scratch/arm64

# Rebuild iOS Simulator arm64
echo "  → Building iOS Simulator arm64..."
ninja -C dist/libmpv/isimulator/scratch/arm64

# Copy to frameworks
echo "📦 Copying to frameworks..."
cp dist/libmpv/ios/scratch/arm64/libmpv.a dist/libmpv/ios/Libmpv.framework/Libmpv
cp dist/libmpv/isimulator/scratch/arm64/libmpv.a dist/libmpv/isimulator/Libmpv.framework/Libmpv

# Recreate xcframework
echo "🏗️  Creating xcframework..."
rm -rf dist/release/Libmpv.xcframework
xcodebuild -create-xcframework \
    -framework dist/libmpv/ios/Libmpv.framework \
    -framework dist/libmpv/isimulator/Libmpv.framework \
    -output dist/release/Libmpv.xcframework

# Rezip for SPM
echo "📦 Zipping for SPM..."
cd dist/release
rm -f Libmpv.xcframework.zip
zip -rq Libmpv.xcframework.zip Libmpv.xcframework
rm -rf Libmpv.xcframework
cd ../..

echo "✅ Done! Clean build in Xcode (Cmd+Shift+K) and rebuild."
