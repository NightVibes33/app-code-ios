#!/bin/sh
set -eu

SCHEME="${SCHEME:-Code App}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build/DerivedData}"
IPA_NAME="${IPA_NAME:-AppCode-unsigned.ipa}"

./scripts/bootstrap_resources.sh

xcodebuild -resolvePackageDependencies -project Code.xcodeproj -scheme "$SCHEME" -derivedDataPath "$DERIVED_DATA_PATH"
./scripts/patch_swift_packages.sh "$DERIVED_DATA_PATH"

rm -rf build/Payload "$IPA_NAME"
mkdir -p build/Payload

xcodebuild -project Code.xcodeproj -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination "generic/platform=iOS" -derivedDataPath "$DERIVED_DATA_PATH" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" build

APP_PATH=$(find "$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos" -maxdepth 2 -name "*.app" -type d | head -n 1)
if [ -z "$APP_PATH" ]; then
  echo "Unable to locate built .app" >&2
  exit 1
fi

cp -R "$APP_PATH" "build/Payload/AppCode.app"
(cd build && zip -qry "../$IPA_NAME" Payload)

echo "Built $IPA_NAME"
