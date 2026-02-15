#!/usr/bin/env bash
set -euo pipefail

SCHEME="${SCHEME:-DiskCleaner}"
PROJECT_PATH="${PROJECT_PATH:-DiskCleaner.xcodeproj}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_ROOT="${BUILD_ROOT:-$PWD/build}"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Project not found at: $PROJECT_PATH" >&2
  exit 1
fi

echo "Building scheme '$SCHEME' ($CONFIGURATION)..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  clean build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/${SCHEME}.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at expected path: $APP_PATH" >&2
  exit 1
fi

echo "Built app: $APP_PATH"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "app_path=$APP_PATH" >> "$GITHUB_OUTPUT"
fi
