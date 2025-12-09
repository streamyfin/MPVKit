#!/bin/bash

# Script to create xcframeworks from local libass 0.17.4 build

set -e

DIST_DIR="/Users/alex/Documents/MPVKit/dist"
RELEASE_DIR="${DIST_DIR}/release"
LIBASS_VERSION="0.17.4"

# Libraries to process
LIBRARIES=("libass" "libfreetype" "libfribidi" "libharfbuzz" "libunibreak")
LIB_NAMES=("ass" "freetype" "fribidi" "harfbuzz" "unibreak")

mkdir -p "${RELEASE_DIR}"

for i in "${!LIBRARIES[@]}"; do
    LIB_DIR="${LIBRARIES[$i]}-${LIBASS_VERSION}"
    LIB_NAME="${LIB_NAMES[$i]}"
    XCFRAMEWORK_NAME="Lib${LIB_NAME}"
    
    echo "Processing ${LIB_NAME}..."
    
    SRC_DIR="${DIST_DIR}/${LIB_DIR}"
    if [ ! -d "$SRC_DIR" ]; then
        echo "  Directory not found: $SRC_DIR, skipping..."
        continue
    fi
    
    INCLUDE_DIR="${SRC_DIR}/include"
    WORK_DIR="${SRC_DIR}/xcframework_work"
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    
    XCFRAMEWORK_ARGS=""
    
    # iOS
    if [ -f "${SRC_DIR}/lib/ios/thin/arm64/lib/lib${LIB_NAME}.a" ]; then
        echo "  Creating iOS framework..."
        mkdir -p "${WORK_DIR}/ios"
        cp "${SRC_DIR}/lib/ios/thin/arm64/lib/lib${LIB_NAME}.a" "${WORK_DIR}/ios/lib${LIB_NAME}.a"
        cp -r "$INCLUDE_DIR" "${WORK_DIR}/ios/"
        XCFRAMEWORK_ARGS="${XCFRAMEWORK_ARGS} -library ${WORK_DIR}/ios/lib${LIB_NAME}.a -headers ${WORK_DIR}/ios/include"
    fi
    
    # iOS Simulator (fat: arm64 + x86_64)
    if [ -f "${SRC_DIR}/lib/isimulator/thin/arm64/lib/lib${LIB_NAME}.a" ]; then
        echo "  Creating iOS Simulator framework..."
        mkdir -p "${WORK_DIR}/isimulator"
        if [ -f "${SRC_DIR}/lib/isimulator/thin/x86_64/lib/lib${LIB_NAME}.a" ]; then
            lipo -create \
                "${SRC_DIR}/lib/isimulator/thin/arm64/lib/lib${LIB_NAME}.a" \
                "${SRC_DIR}/lib/isimulator/thin/x86_64/lib/lib${LIB_NAME}.a" \
                -output "${WORK_DIR}/isimulator/lib${LIB_NAME}.a"
        else
            cp "${SRC_DIR}/lib/isimulator/thin/arm64/lib/lib${LIB_NAME}.a" "${WORK_DIR}/isimulator/lib${LIB_NAME}.a"
        fi
        cp -r "$INCLUDE_DIR" "${WORK_DIR}/isimulator/"
        XCFRAMEWORK_ARGS="${XCFRAMEWORK_ARGS} -library ${WORK_DIR}/isimulator/lib${LIB_NAME}.a -headers ${WORK_DIR}/isimulator/include"
    fi
    
    # macOS (fat: arm64 + x86_64)
    if [ -f "${SRC_DIR}/lib/macos/thin/arm64/lib/lib${LIB_NAME}.a" ]; then
        echo "  Creating macOS framework..."
        mkdir -p "${WORK_DIR}/macos"
        if [ -f "${SRC_DIR}/lib/macos/thin/x86_64/lib/lib${LIB_NAME}.a" ]; then
            lipo -create \
                "${SRC_DIR}/lib/macos/thin/arm64/lib/lib${LIB_NAME}.a" \
                "${SRC_DIR}/lib/macos/thin/x86_64/lib/lib${LIB_NAME}.a" \
                -output "${WORK_DIR}/macos/lib${LIB_NAME}.a"
        else
            cp "${SRC_DIR}/lib/macos/thin/arm64/lib/lib${LIB_NAME}.a" "${WORK_DIR}/macos/lib${LIB_NAME}.a"
        fi
        cp -r "$INCLUDE_DIR" "${WORK_DIR}/macos/"
        XCFRAMEWORK_ARGS="${XCFRAMEWORK_ARGS} -library ${WORK_DIR}/macos/lib${LIB_NAME}.a -headers ${WORK_DIR}/macos/include"
    fi
    
    # tvOS
    if [ -f "${SRC_DIR}/lib/tvos/thin/arm64/lib/lib${LIB_NAME}.a" ]; then
        echo "  Creating tvOS framework..."
        mkdir -p "${WORK_DIR}/tvos"
        cp "${SRC_DIR}/lib/tvos/thin/arm64/lib/lib${LIB_NAME}.a" "${WORK_DIR}/tvos/lib${LIB_NAME}.a"
        cp -r "$INCLUDE_DIR" "${WORK_DIR}/tvos/"
        XCFRAMEWORK_ARGS="${XCFRAMEWORK_ARGS} -library ${WORK_DIR}/tvos/lib${LIB_NAME}.a -headers ${WORK_DIR}/tvos/include"
    fi
    
    # tvOS Simulator (fat: arm64 + x86_64)
    if [ -f "${SRC_DIR}/lib/tvsimulator/thin/arm64/lib/lib${LIB_NAME}.a" ]; then
        echo "  Creating tvOS Simulator framework..."
        mkdir -p "${WORK_DIR}/tvsimulator"
        if [ -f "${SRC_DIR}/lib/tvsimulator/thin/x86_64/lib/lib${LIB_NAME}.a" ]; then
            lipo -create \
                "${SRC_DIR}/lib/tvsimulator/thin/arm64/lib/lib${LIB_NAME}.a" \
                "${SRC_DIR}/lib/tvsimulator/thin/x86_64/lib/lib${LIB_NAME}.a" \
                -output "${WORK_DIR}/tvsimulator/lib${LIB_NAME}.a"
        else
            cp "${SRC_DIR}/lib/tvsimulator/thin/arm64/lib/lib${LIB_NAME}.a" "${WORK_DIR}/tvsimulator/lib${LIB_NAME}.a"
        fi
        cp -r "$INCLUDE_DIR" "${WORK_DIR}/tvsimulator/"
        XCFRAMEWORK_ARGS="${XCFRAMEWORK_ARGS} -library ${WORK_DIR}/tvsimulator/lib${LIB_NAME}.a -headers ${WORK_DIR}/tvsimulator/include"
    fi
    
    # Mac Catalyst (fat: arm64 + x86_64)
    if [ -f "${SRC_DIR}/lib/maccatalyst/thin/arm64/lib/lib${LIB_NAME}.a" ]; then
        echo "  Creating Mac Catalyst framework..."
        mkdir -p "${WORK_DIR}/maccatalyst"
        if [ -f "${SRC_DIR}/lib/maccatalyst/thin/x86_64/lib/lib${LIB_NAME}.a" ]; then
            lipo -create \
                "${SRC_DIR}/lib/maccatalyst/thin/arm64/lib/lib${LIB_NAME}.a" \
                "${SRC_DIR}/lib/maccatalyst/thin/x86_64/lib/lib${LIB_NAME}.a" \
                -output "${WORK_DIR}/maccatalyst/lib${LIB_NAME}.a"
        else
            cp "${SRC_DIR}/lib/maccatalyst/thin/arm64/lib/lib${LIB_NAME}.a" "${WORK_DIR}/maccatalyst/lib${LIB_NAME}.a"
        fi
        cp -r "$INCLUDE_DIR" "${WORK_DIR}/maccatalyst/"
        XCFRAMEWORK_ARGS="${XCFRAMEWORK_ARGS} -library ${WORK_DIR}/maccatalyst/lib${LIB_NAME}.a -headers ${WORK_DIR}/maccatalyst/include"
    fi
    
    # Create xcframework
    XCFRAMEWORK_PATH="${RELEASE_DIR}/${XCFRAMEWORK_NAME}.xcframework"
    rm -rf "$XCFRAMEWORK_PATH"
    
    echo "  Creating xcframework: ${XCFRAMEWORK_NAME}.xcframework"
    eval "xcodebuild -create-xcframework ${XCFRAMEWORK_ARGS} -output ${XCFRAMEWORK_PATH}"
    
    # Create zip
    echo "  Creating zip..."
    cd "${RELEASE_DIR}"
    rm -f "${XCFRAMEWORK_NAME}.xcframework.zip"
    zip -qry "${XCFRAMEWORK_NAME}.xcframework.zip" "${XCFRAMEWORK_NAME}.xcframework"
    
    # Cleanup
    rm -rf "$WORK_DIR"
    
    echo "  Done: ${XCFRAMEWORK_NAME}.xcframework.zip"
done

echo ""
echo "All xcframeworks created in ${RELEASE_DIR}"
