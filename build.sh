#!/bin/bash
set -euo pipefail

PROJECT="NextMeeting/NextMeeting.xcodeproj"
SCHEME="NextMeeting"
BUILD_DIR="build"
CONFIGURATION="${1:-Release}"

echo "Building NextMeeting ($CONFIGURATION)..."

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  -destination 'platform=macOS' \
  | tail -5

APP_PATH=$(find "$BUILD_DIR" -name "NextMeeting.app" -type d | head -1)

if [ -n "$APP_PATH" ]; then
  echo "Build succeeded: $APP_PATH"
else
  echo "Build failed."
  exit 1
fi
