#!/bin/bash
set -e

echo "Building release APK..."
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
  echo "Build successful!"
  echo "APK: $APK_PATH"
  ls -lh "$APK_PATH"
else
  echo "Build failed: APK not found"
  exit 1
fi
