#!/bin/sh
set -eu

ROOT_DIR="${1:-.}"
MANIFEST="$ROOT_DIR/scripts/privacy_manifests/openssl/PrivacyInfo.xcprivacy"

if [ ! -f "$MANIFEST" ]; then
  echo "Missing OpenSSL privacy manifest template: $MANIFEST" >&2
  exit 1
fi

XCFRAMEWORKS=$(find "$ROOT_DIR/Resources" -name openssl.xcframework -type d 2>/dev/null || true)
if [ -z "$XCFRAMEWORKS" ]; then
  echo "Missing Resources OpenSSL XCFramework" >&2
  exit 1
fi

for xcframework in $XCFRAMEWORKS; do
  echo "Preparing third-party SDK: $xcframework"

  FRAMEWORKS=$(find "$xcframework" -name "*.framework" -type d 2>/dev/null || true)
  if [ -z "$FRAMEWORKS" ]; then
    echo "No framework slices found in $xcframework" >&2
    exit 1
  fi

  for framework in $FRAMEWORKS; do
    cp "$MANIFEST" "$framework/PrivacyInfo.xcprivacy"
    echo "Added PrivacyInfo.xcprivacy to $framework"
  done

  if [ "${SDK_SIGNATURE_DRY_RUN:-0}" = "1" ]; then
    echo "Dry run: skipping codesign for $xcframework"
    continue
  fi

  if ! command -v codesign >/dev/null 2>&1; then
    echo "codesign is required to sign $xcframework" >&2
    exit 1
  fi

  if [ -n "${SDK_SIGNING_IDENTITY:-}" ]; then
    SIGNING_IDENTITY="$SDK_SIGNING_IDENTITY"
  else
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | awk -F '"' '/Apple Distribution/ { print $2; exit }')
  fi

  if [ -z "$SIGNING_IDENTITY" ]; then
    echo "Unable to find an Apple Distribution signing identity for SDK signing" >&2
    security find-identity -v -p codesigning || true
    exit 1
  fi

  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$xcframework"
  codesign --verify --verbose=2 "$xcframework"
done
