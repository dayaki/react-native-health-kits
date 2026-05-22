#!/usr/bin/env bash
#
# Generates the native iOS/Android host projects for the example app.
#
# The example app's JS (App.tsx, package.json, metro/babel config) lives in the
# repo, but the native projects (example/ios, example/android) are machine-
# generated and not committed. Run this once after cloning to produce them.
#
# Requirements: Node, Yarn, Xcode + CocoaPods (iOS), Android SDK (Android),
# and network access. Run from the repo root: `bash scripts/bootstrap-example.sh`
#
set -euo pipefail

RN_VERSION="${RN_VERSION:-0.76.6}"
APP_NAME="HealthKitsExample"   # must match example/app.json "name"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLE_DIR="$REPO_ROOT/example"
TMP_DIR="$(mktemp -d)"

echo "▸ Repo root:    $REPO_ROOT"
echo "▸ RN version:   $RN_VERSION"

if [[ -d "$EXAMPLE_DIR/ios" || -d "$EXAMPLE_DIR/android" ]]; then
  echo "✗ example/ios or example/android already exists. Remove them first if you want to regenerate." >&2
  exit 1
fi

echo "▸ Generating a throwaway RN $RN_VERSION app to harvest native projects…"
npx @react-native-community/cli@latest init "$APP_NAME" \
  --directory "$TMP_DIR/app" \
  --version "$RN_VERSION" \
  --skip-install \
  --pm yarn

echo "▸ Copying native projects into example/…"
cp -R "$TMP_DIR/app/ios" "$EXAMPLE_DIR/ios"
cp -R "$TMP_DIR/app/android" "$EXAMPLE_DIR/android"
rm -rf "$TMP_DIR"

# --- iOS: raise deployment target to 16.0 (the library requires it) ---
PODFILE="$EXAMPLE_DIR/ios/Podfile"
if [[ -f "$PODFILE" ]]; then
  echo "▸ Setting iOS Podfile platform to 16.0…"
  sed -i.bak -E "s/^platform :ios.*/platform :ios, '16.0'/" "$PODFILE" && rm -f "$PODFILE.bak"
fi

# --- iOS: add HealthKit Info.plist usage descriptions ---
PLIST="$EXAMPLE_DIR/ios/$APP_NAME/Info.plist"
if [[ -f "$PLIST" ]]; then
  echo "▸ Adding HealthKit usage descriptions to Info.plist…"
  /usr/libexec/PlistBuddy -c \
    "Add :NSHealthShareUsageDescription string 'Read your health data to display fitness information.'" \
    "$PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c \
    "Add :NSHealthUpdateUsageDescription string 'Write health data on your behalf.'" \
    "$PLIST" 2>/dev/null || true
fi

# --- Android: ensure the New Architecture is on (default in 0.76, but be safe) ---
GRADLE_PROPS="$EXAMPLE_DIR/android/gradle.properties"
if [[ -f "$GRADLE_PROPS" ]]; then
  echo "▸ Ensuring newArchEnabled=true…"
  if grep -q "^newArchEnabled=" "$GRADLE_PROPS"; then
    sed -i.bak -E "s/^newArchEnabled=.*/newArchEnabled=true/" "$GRADLE_PROPS" && rm -f "$GRADLE_PROPS.bak"
  else
    printf "\nnewArchEnabled=true\n" >> "$GRADLE_PROPS"
  fi
fi

echo "▸ Installing workspace dependencies (links the library into example/)…"
( cd "$REPO_ROOT" && yarn install )

echo "▸ Installing iOS pods (New Architecture)…"
( cd "$EXAMPLE_DIR/ios" && RCT_NEW_ARCH_ENABLED=1 pod install )

cat <<'DONE'

✅ Native projects generated.

Remaining MANUAL steps (one-time):
  • iOS HealthKit capability: open example/ios/HealthKitsExample.xcworkspace in
    Xcode → target → Signing & Capabilities → "+ Capability" → HealthKit.
    Select a development team for signing (HealthKit needs a real device).

Run it:
  • iOS (physical device only — HealthKit is not on the simulator):
        yarn workspace @mbdayo/react-native-health-kits-example ios --device
  • Android (device/emulator with Health Connect installed):
        yarn workspace @mbdayo/react-native-health-kits-example android

DONE
