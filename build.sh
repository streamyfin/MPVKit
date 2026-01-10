#!/bin/bash
# MPVKit Build Script
# Ensures a clean build with symbol prefixing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default platforms (can be overridden via argument)
PLATFORMS="${1:-ios,tvos,tvsimulator,isimulator}"

echo "==================================="
echo "  MPVKit Build Script"
echo "==================================="
echo ""
echo "Platforms: $PLATFORMS"
echo ""

# Clean previous build
echo "Cleaning dist folder..."
rm -rf "$SCRIPT_DIR/dist"
rm -f "$SCRIPT_DIR/dist/dav1d_symbol_rename_map.txt"

echo "Starting build..."
echo ""

# Run the build
make gpl platform="$PLATFORMS"

echo ""
echo "==================================="
echo "  Build Complete!"
echo "==================================="

