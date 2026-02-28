#!/bin/bash

# Script to prepare release files for GitHub release
# This script verifies xcframework zip files and their checksums

set -e

RELEASE_DIR="./dist/release"
RELEASE_VERSION="${1:-0.40.0-av}"

echo "=========================================="
echo "Preparing Release: $RELEASE_VERSION"
echo "=========================================="
echo ""

# Check if release directory exists
if [ ! -d "$RELEASE_DIR" ]; then
    echo "❌ Error: Release directory not found: $RELEASE_DIR"
    echo "   Run 'make build version=$RELEASE_VERSION' first"
    exit 1
fi

cd "$RELEASE_DIR"

echo "📦 Checking xcframework zip files..."
echo ""

# Find all xcframework zip files
ZIP_FILES=($(find . -name "*.xcframework.zip" -type f | sort))

if [ ${#ZIP_FILES[@]} -eq 0 ]; then
    echo "⚠️  Warning: No xcframework.zip files found in $RELEASE_DIR"
    echo "   The build may not have completed yet."
    exit 1
fi

echo "Found ${#ZIP_FILES[@]} xcframework zip files:"
echo ""

# Arrays to track results
VALID_FILES=()
INVALID_FILES=()
MISSING_CHECKSUMS=()

# Process each zip file
for zip_file in "${ZIP_FILES[@]}"; do
    zip_name=$(basename "$zip_file")
    framework_name="${zip_name%.xcframework.zip}"
    checksum_file="${framework_name}.xcframework.checksum.txt"
    
    echo "  📄 $zip_name"
    
    # Check if zip file is valid
    if ! unzip -tq "$zip_file" > /dev/null 2>&1; then
        echo "     ❌ Invalid zip file!"
        INVALID_FILES+=("$zip_file")
        continue
    fi
    
    # Compute checksum
    if command -v swift > /dev/null 2>&1; then
        computed_checksum=$(swift package compute-checksum "$zip_file" 2>/dev/null | tr -d '[:space:]')
        
        if [ -f "$checksum_file" ]; then
            stored_checksum=$(cat "$checksum_file" | tr -d '[:space:]')
            
            if [ "$computed_checksum" == "$stored_checksum" ]; then
                echo "     ✅ Checksum verified: $computed_checksum"
                VALID_FILES+=("$zip_file")
            else
                echo "     ⚠️  Checksum mismatch!"
                echo "        Stored:  $stored_checksum"
                echo "        Computed: $computed_checksum"
                echo "     🔄 Updating checksum file..."
                echo "$computed_checksum" > "$checksum_file"
                VALID_FILES+=("$zip_file")
            fi
        else
            echo "     ⚠️  Missing checksum file, creating..."
            echo "$computed_checksum" > "$checksum_file"
            echo "     ✅ Checksum: $computed_checksum"
            VALID_FILES+=("$zip_file")
        fi
    else
        echo "     ⚠️  Swift not found, skipping checksum verification"
        if [ ! -f "$checksum_file" ]; then
            MISSING_CHECKSUMS+=("$zip_file")
        fi
        VALID_FILES+=("$zip_file")
    fi
    
    # Show file size
    file_size=$(du -h "$zip_file" | cut -f1)
    echo "     📊 Size: $file_size"
    echo ""
done

echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "✅ Valid files: ${#VALID_FILES[@]}"
if [ ${#INVALID_FILES[@]} -gt 0 ]; then
    echo "❌ Invalid files: ${#INVALID_FILES[@]}"
    for file in "${INVALID_FILES[@]}"; do
        echo "   - $file"
    done
fi
if [ ${#MISSING_CHECKSUMS[@]} -gt 0 ]; then
    echo "⚠️  Missing checksums: ${#MISSING_CHECKSUMS[@]}"
    for file in "${MISSING_CHECKSUMS[@]}"; do
        echo "   - $file"
    done
fi
echo ""

# List all files that will be uploaded
echo "=========================================="
echo "Files ready for release upload:"
echo "=========================================="
echo ""

# List zip files
echo "📦 xcframework zip files:"
for zip_file in "${ZIP_FILES[@]}"; do
    echo "   - $(basename "$zip_file")"
done
echo ""

# List checksum files
CHECKSUM_FILES=($(find . -name "*.xcframework.checksum.txt" -type f | sort))
if [ ${#CHECKSUM_FILES[@]} -gt 0 ]; then
    echo "🔐 Checksum files:"
    for checksum_file in "${CHECKSUM_FILES[@]}"; do
        echo "   - $(basename "$checksum_file")"
    done
    echo ""
fi

# List other files (like Package.swift, -all.zip files, etc.)
OTHER_FILES=($(find . -type f \( -name "*.txt" -o -name "Package.swift" -o -name "*-all.zip" \) ! -name "*.checksum.txt" | sort))
if [ ${#OTHER_FILES[@]} -gt 0 ]; then
    echo "📄 Other release files:"
    for other_file in "${OTHER_FILES[@]}"; do
        echo "   - $(basename "$other_file")"
    done
    echo ""
fi

# Total size
TOTAL_SIZE=$(du -sh . | cut -f1)
echo "📊 Total release size: $TOTAL_SIZE"
echo ""

# Create a file list for GitHub release
FILE_LIST="release-files-${RELEASE_VERSION}.txt"
{
    echo "Release files for $RELEASE_VERSION"
    echo "Generated: $(date)"
    echo ""
    echo "=== xcframework zip files ==="
    for zip_file in "${ZIP_FILES[@]}"; do
        echo "$(basename "$zip_file")"
    done
    echo ""
    echo "=== checksum files ==="
    for checksum_file in "${CHECKSUM_FILES[@]}"; do
        echo "$(basename "$checksum_file")"
    done
} > "$FILE_LIST"

echo "✅ File list saved to: $FILE_LIST"
echo ""

echo "=========================================="
echo "Ready for GitHub release!"
echo "=========================================="
echo ""
echo "To create the release, run:"
echo "  gh release create $RELEASE_VERSION \\"
echo "    --title \"$RELEASE_VERSION\" \\"
echo "    --notes \"Release $RELEASE_VERSION\" \\"
echo "    ./dist/release/*.zip ./dist/release/*.txt"
echo ""
