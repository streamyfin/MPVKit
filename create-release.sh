#!/bin/bash

# Script to create a GitHub release with all the xcframework files
# Usage: ./create-release.sh [version] [--prerelease]

set -e

RELEASE_VERSION="${1:-0.40.0-av}"
RELEASE_DIR="./dist/release"
IS_PRERELEASE=false

# Check for prerelease flag
if [[ "$*" == *"--prerelease"* ]] || [[ "$RELEASE_VERSION" == *"-"* ]]; then
    IS_PRERELEASE=true
fi

echo "=========================================="
echo "Creating GitHub Release: $RELEASE_VERSION"
echo "=========================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh > /dev/null 2>&1; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "   Install it with: brew install gh"
    exit 1
fi

# Check if release directory exists
if [ ! -d "$RELEASE_DIR" ]; then
    echo "❌ Error: Release directory not found: $RELEASE_DIR"
    echo "   Run 'make build version=$RELEASE_VERSION' first"
    exit 1
fi

cd "$RELEASE_DIR"

# Check if files exist
ZIP_FILES=($(find . -name "*.xcframework.zip" -type f))
if [ ${#ZIP_FILES[@]} -eq 0 ]; then
    echo "❌ Error: No xcframework.zip files found"
    echo "   Run 'make build version=$RELEASE_VERSION' first"
    exit 1
fi

echo "📦 Found ${#ZIP_FILES[@]} xcframework zip files"
echo ""

# Check if release already exists
if gh release view "$RELEASE_VERSION" > /dev/null 2>&1; then
    echo "⚠️  Release $RELEASE_VERSION already exists!"
    read -p "   Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing release..."
        gh release delete "$RELEASE_VERSION" --yes
    else
        echo "❌ Aborted"
        exit 1
    fi
fi

# Prepare release notes
RELEASE_NOTES="release-notes-${RELEASE_VERSION}.md"
{
    echo "# Release $RELEASE_VERSION"
    echo ""
    echo "## Included Frameworks"
    echo ""
    for zip_file in "${ZIP_FILES[@]}"; do
        framework_name=$(basename "$zip_file" .xcframework.zip)
        echo "- \`$framework_name\`"
    done
    echo ""
    echo "## Installation"
    echo ""
    echo "Add this package to your \`Package.swift\` dependencies:"
    echo ""
    echo "\`\`\`swift"
    echo "dependencies: ["
    echo "    .package(url: \"https://github.com/Alexk2309/MPVKit.git\", from: \"$RELEASE_VERSION\")"
    echo "]"
    echo "\`\`\`"
    echo ""
    echo "---"
    echo ""
    echo "*Generated on $(date)*"
} > "$RELEASE_NOTES"

echo "📝 Release notes created: $RELEASE_NOTES"
echo ""

# Build file list for upload
UPLOAD_FILES=()
UPLOAD_FILES+=($(find . -name "*.xcframework.zip" -type f))
UPLOAD_FILES+=($(find . -name "*.xcframework.checksum.txt" -type f))
UPLOAD_FILES+=($(find . -name "Package.swift" -type f))

echo "📤 Uploading ${#UPLOAD_FILES[@]} files to release..."
echo ""

# Create the release
PRERELEASE_FLAG=""
if [ "$IS_PRERELEASE" = true ]; then
    PRERELEASE_FLAG="--prerelease"
    echo "🏷️  Creating as prerelease"
fi

gh release create "$RELEASE_VERSION" \
    --title "$RELEASE_VERSION" \
    --notes-file "$RELEASE_NOTES" \
    $PRERELEASE_FLAG \
    "${UPLOAD_FILES[@]}"

echo ""
echo "=========================================="
echo "✅ Release created successfully!"
echo "=========================================="
echo ""
echo "Release URL: https://github.com/Alexk2309/MPVKit/releases/tag/$RELEASE_VERSION"
echo ""
