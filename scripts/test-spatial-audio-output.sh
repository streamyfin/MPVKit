#!/bin/bash
# Builds and runs the "spatial" audio output's unit test (patch 0007) against
# the pinned mpv with this repository's patches applied. macOS only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=$(sed -n '/case .libmpv:/{n;s/.*"\(.*\)".*/\1/p;q;}' "$ROOT/Sources/BuildScripts/XCFrameworkBuild/main.swift")
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git -c advice.detachedHead=false clone -q --depth 1 --branch "$VERSION" \
    https://github.com/mpv-player/mpv.git "$WORK/mpv"
for patch in "$ROOT"/Sources/BuildScripts/patch/libmpv/*.patch; do
    git -C "$WORK/mpv" apply "$patch"
done

# The driver reads one build switch; the test supplies the mpv functions it calls.
printf '#pragma once\n#define HAVE_AVFOUNDATION 1\n' > "$WORK/config.h"
xcrun --sdk macosx clang -x objective-c -std=c11 -Wall -Wno-unused-parameter \
    -I"$WORK" -I"$WORK/mpv" -I"$WORK/mpv/include" \
    "$ROOT/scripts/spatial-audio-output-test.m" \
    -framework AVFoundation -framework CoreMedia -framework Foundation -framework QuartzCore \
    -o "$WORK/spatial-audio-output-test"
"$WORK/spatial-audio-output-test"
