#!/bin/bash
set -e

# Upload MPVKit-GPL-Frameworks.zip to GitHub release
# Just uploads - doesn't rebuild anything
#
# Usage: ./upload-framework.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# GitHub release settings
GITHUB_REPO="Alexk2309/MPVKit"
GITHUB_TAG="0.40.0-av"
RELEASE_ZIP_NAME="MPVKit-GPL-Frameworks.zip"

# Source zip location
SOURCE_ZIP="$SCRIPT_DIR/dist/MPVKit-combined/MPVKit.xcframework.zip"

echo "=============================================="
echo "  Uploading to GitHub Release"
echo "=============================================="
echo "  Repo:   $GITHUB_REPO"
echo "  Tag:    $GITHUB_TAG"
echo "  Asset:  $RELEASE_ZIP_NAME"
echo "  Source: $SOURCE_ZIP"
echo ""

# Check source exists
if [ ! -f "$SOURCE_ZIP" ]; then
    echo "❌ Source zip not found: $SOURCE_ZIP"
    echo "   Run './create-combined-framework.sh' first"
    exit 1
fi

ls -lh "$SOURCE_ZIP"
echo ""

# Create renamed copy for upload
UPLOAD_ZIP="/tmp/$RELEASE_ZIP_NAME"
cp "$SOURCE_ZIP" "$UPLOAD_ZIP"

# Delete existing asset if present (ignore errors)
echo "🗑️  Removing old asset (if exists)..."
gh release delete-asset "$GITHUB_TAG" "$RELEASE_ZIP_NAME" --repo "$GITHUB_REPO" --yes 2>/dev/null || true

# Upload new asset
echo "🚀 Uploading new asset..."
gh release upload "$GITHUB_TAG" "$UPLOAD_ZIP" --repo "$GITHUB_REPO"

# Cleanup
rm -f "$UPLOAD_ZIP"

echo ""
echo "✅ Uploaded to: https://github.com/$GITHUB_REPO/releases/tag/$GITHUB_TAG"
echo ""
echo "📌 In your other project, run:"
echo "   pod cache clean MPVKit-GPL --all"
echo "   rm -rf Pods Podfile.lock"
echo "   pod install"
