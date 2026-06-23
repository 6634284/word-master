#!/bin/bash
set -e

echo "Building release AAB..."
flutter build appbundle --release

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
  echo "Build successful!"
  echo "AAB: $AAB_PATH"
  ls -lh "$AAB_PATH"
else
  echo "Build failed: AAB not found"
  exit 1
fi
