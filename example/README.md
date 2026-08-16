# Example app

A minimal React Native app for exercising `@mbdayo/react-native-health-kits` on
a real device. It's the manual test harness for the library.

The native host projects (`ios/`, `android/`) are committed, so CI can build them
and a fresh clone builds without generating anything. `scripts/bootstrap-example.sh`
regenerates them from scratch against a newer React Native, but you do not need to
run it for a normal checkout.

## Requirements

- React Native 0.76 with the **New Architecture** (this library is a Turbo Native Module)
- **iOS:** a *physical device* — HealthKit is unavailable in the simulator. Xcode + CocoaPods.
- **Android:** a device/emulator with **Health Connect** installed (Play Store on Android 9–13; built in on 14+). Android SDK.

## Setup

From the repo root:

```bash
yarn install
cd example/ios && RCT_NEW_ARCH_ENABLED=1 pod install
```

Then, one-time in Xcode: open `example/ios/HealthKitsExample.xcworkspace` →
target → **Signing & Capabilities** → add the **HealthKit** capability and select
a signing team. This is only needed to *run* on a device; a simulator build (what
CI does) compiles without it.

### Regenerating the native projects

`bash scripts/bootstrap-example.sh` rebuilds `ios/` and `android/` from the RN
template — useful when upgrading React Native. It refuses to run if those
directories already exist, so delete them first. It sets the iOS deployment
target to 16.0, adds the HealthKit `Info.plist` keys, raises `minSdkVersion` to
28 (Health Connect needs 26), enables the New Architecture, and runs
`pod install`.

> Autolinking finds the library through `example/react-native.config.js`, not
> through `node_modules`. The workspace dependency resolves as a Yarn *soft*
> link, so `example/node_modules/@mbdayo/react-native-health-kits` is never
> created and autolinking would otherwise skip the library entirely — building
> a JS-only app that never compiles the native code.

> The Health Connect permissions and the permissions-rationale activity are
> declared in the library's own `AndroidManifest.xml` and merge into the app
> automatically — no manifest edits needed in the example.

## Run

```bash
# iOS (physical device only)
yarn workspace @mbdayo/react-native-health-kits-example ios --device

# Android (device/emulator with Health Connect)
yarn workspace @mbdayo/react-native-health-kits-example android
```

## What to verify

**TurboModule registration (#7 / issue #1)**
- The app launches without `TurboModuleRegistry.getEnforcing('HealthKits') could not be found`.
- "Health Data Availability" shows ✅ Available. (If it loads at all, the Turbo Native Module resolved.)

**Aggregation parity (#8)**
- Grant permissions, then **Read Aggregated (daily)** → returns daily step buckets on **both** iOS and Android.
- **Test heartRate Aggregate (expect reject)** → shows "✅ Rejected with UNSUPPORTED_DATA_TYPE" on both platforms (aggregation is cumulative-types-only).

**Basics**
- Read Steps / Read Heart Rate return records; Write Weight succeeds.

## Troubleshooting

- **`getEnforcing(...) could not be found`** — see the root README's troubleshooting section. Almost always: New Architecture off, or the app wasn't natively rebuilt after install.
- **iOS: no HealthKit data** — you're on the simulator; use a physical device.
- **Android: `isAvailable()` is false** — Health Connect isn't installed, or (Android ≤13) the app may need a `<queries>` entry for `com.google.android.apps.healthdata`.
