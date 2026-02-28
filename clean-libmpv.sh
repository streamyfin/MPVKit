#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "🗑️  Deleting libmpv build artifacts..."
rm -rf dist/libmpv
rm -rf dist/libmpv-v0.40.0

echo "🔨 Rebuilding libmpv..."
make build platform=ios

echo "✅ Done!"
