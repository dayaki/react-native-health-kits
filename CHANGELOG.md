# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-08-16

A breaking release on two fronts. The module is now a real Turbo Native Module
and requires the New Architecture, and the energy data types now mean the same
thing on both platforms.

### Migration from 1.x

**1. The New Architecture is now required.** This is a Turbo Native Module and
will not load on the legacy bridge. You need React Native >= 0.76 with the New
Architecture enabled (the default since 0.76): `newArchEnabled=true` in
`gradle.properties`, `RCT_NEW_ARCH_ENABLED=1` for iOS pods. If you are still on
the old architecture, stay on 1.x until you migrate.

**2. iOS deployment target is 16.0.** Raise `platform :ios` in your Podfile if
it is lower. 1.x declared 13.0 but never actually compiled below 16.0.

**3. `totalCalories` on iOS changed meaning.** It used to return
`basalEnergyBurned` — resting energy only — while Android returned active +
basal for the same type. It now means active + basal on both platforms.

```diff
- // 1.x on iOS: resting energy, despite the name
+ // 2.0: resting energy, on both platforms
  await HealthKits.readData({
-   type: 'totalCalories',
+   type: 'basalCalories',
    startDate, endDate,
  });
```

If you wanted total energy all along, no change is needed — you were getting the
wrong number on iOS and the right one on Android, and both are now correct.

**4. Derived types return a single record and cannot be written.**
`totalCalories` on iOS and `basalCalories` on Android are computed rather than
stored. An un-aggregated read returns one record spanning the whole requested
window rather than a list, since there are no stored records to page through
(`limit` does not apply). Pass `aggregate: true` with an `aggregateInterval` for
per-interval buckets. `writeData`, `subscribeToUpdates`, and write-access
permission requests reject these types with `UNSUPPORTED_DATA_TYPE`.

**5. Aggregation now rejects non-cumulative types.** In 1.x, iOS silently
summed instantaneous types, so `aggregate: true` on `heartRate` or `weight`
returned meaningless numbers, and Android ignored `aggregate` entirely. Both now
reject with `UNSUPPORTED_DATA_TYPE`. Read those as raw records and aggregate in
app code.

**6. `healthDataTypeToiOS` / `healthDataTypeToAndroid` are re-typed** to
`Record<HealthDataType, string | string[]>`, since iOS `totalCalories` maps to
the two identifiers it derives from. Only affects you if you consume these
lookup tables directly.

### Added
- New `basalCalories` data type for resting/basal energy, on both platforms.
  iOS reads `basalEnergyBurned` directly; Android derives it from
  `BasalMetabolicRateRecord` via `BASAL_CALORIES_TOTAL`.
- Android: `readData` now honors `aggregate` / `aggregateInterval` using Health
  Connect's aggregate APIs (`aggregateGroupByPeriod` for day/week/month,
  `aggregateGroupByDuration` for hour), reaching parity with iOS (fixes #4).
- Android: `writeData` supports `totalCalories`, which previously fell through
  the `when` and silently resolved `false`.
- README troubleshooting for
  `TurboModuleRegistry.getEnforcing('HealthKits') could not be found`.

### Changed
- **Breaking — iOS `totalCalories` now means total energy (active + basal).**
  It previously mapped to `basalEnergyBurned`, i.e. resting energy only, while
  Android mapped it to `TotalCaloriesBurnedRecord` (active + basal), so the
  same type returned two different metrics per platform (fixes #4). iOS now
  derives it by summing `activeEnergyBurned` + `basalEnergyBurned`. **If you
  were reading `totalCalories` on iOS to get resting energy, switch to
  `basalCalories`.**
- Derived types (`totalCalories` on iOS, `basalCalories` on Android) have no
  records of their own: an un-aggregated read returns one record for the whole
  window with a generated `id` and a `"derived"` source, while an aggregated
  read buckets by interval and reports an `"aggregated"` source like any other
  aggregate. Writing, subscribing to, or requesting write access for one rejects
  with `UNSUPPORTED_DATA_TYPE`. Requesting *read* access for `totalCalories` on
  iOS now covers both underlying types, since the derived read needs both.
- `healthDataTypeToiOS` / `healthDataTypeToAndroid` are now typed
  `Record<HealthDataType, string | string[]>`; `totalCalories` on iOS lists both
  identifiers it is derived from.
- **BREAKING:** Converted to a true Turbo Native Module and dropped legacy-bridge
  support. The library now requires the **New Architecture** (bridgeless) and
  **React Native >= 0.76**.
  - iOS: the module binds to the codegen spec via `getTurboModule`
    (`HealthKits.m` → `HealthKits.mm`); the Swift implementation is unchanged.
  - Android: `HealthKitsModule` now extends the generated `NativeHealthKitsSpec`
    and `HealthKitsPackage` extends `BaseReactPackage`. The React Gradle plugin
    is applied unconditionally so codegen always produces that spec — it was
    gated on `newArchEnabled`, which left the class undefined and the module
    failing to compile whenever the flag was off or absent.
  - This fixes the `TurboModuleRegistry.getEnforcing('HealthKits') could not be
    found` error caused by the previous legacy-module/TurboModule-spec mismatch
    (fixes #1).
- **BREAKING — iOS `totalCalories` now means total energy (active + basal).**
  It previously mapped to `basalEnergyBurned`, i.e. resting energy only, while
  Android mapped it to `TotalCaloriesBurnedRecord` (active + basal), so the
  same type returned two different metrics per platform (fixes #4). iOS now
  derives it by summing `activeEnergyBurned` + `basalEnergyBurned`.
- **BREAKING:** Raised the iOS deployment target from 13.0 to 16.0. The Swift
  sources use `HKCategoryValueSleepAnalysis.asleepUnspecified` (iOS 16+) and
    (#1).
- Raised the iOS deployment target from 13.0 to 16.0. The Swift sources use
  `HKCategoryValueSleepAnalysis.asleepUnspecified` (iOS 16+) and
  `HKWorkoutActivityType.dance` (iOS 14+), so the previous 13.0 floor never
  actually compiled. The podspec and README now reflect the real minimum
  (fixes #3).
- Derived types (`totalCalories` on iOS, `basalCalories` on Android) have no
  records of their own: an un-aggregated read returns one record for the whole
  window with a generated `id` and a `"derived"` source, while an aggregated
  read buckets by interval and reports an `"aggregated"` source like any other
  aggregate. Writing, subscribing to, or requesting write access for one rejects
  with `UNSUPPORTED_DATA_TYPE`. Requesting *read* access for `totalCalories` on
  iOS now covers both underlying types, since the derived read needs both.
- `healthDataTypeToiOS` / `healthDataTypeToAndroid` are now typed
  `Record<HealthDataType, string | string[]>`; `totalCalories` on iOS lists both
  identifiers it is derived from.

### Fixed
- Aggregation is now restricted to cumulative types (`steps`, `distance`,
  `activeCalories`, `basalCalories`, `totalCalories`, `floorsClimbed`,
  `hydration`) on both platforms. Previously iOS silently summed instantaneous
  types (e.g. `heartRate`, `weight`), and Android ignored `aggregate` entirely.
  Unsupported types now reject with `UNSUPPORTED_DATA_TYPE`.
- iOS: writing `totalCalories` no longer silently stores the value as basal
  energy. Derived types reject instead, pointing at the types to write.
- Android: the `READ`/`WRITE_BASAL_METABOLIC_RATE` permissions are declared in
  both `AndroidManifest.xml` and `AndroidManifestNew.xml`. AGP 8 builds use the
  latter, so a permission added only to the former has no effect.

## [1.0.0] - 2025-11-26

### Added
- Initial release of @mbdayo/react-native-health-kits
- Unified API for iOS HealthKit and Android Health Connect
- Support for common health data types:
  - Activity: steps, distance, calories, floors climbed
  - Vitals: heart rate, blood pressure, blood glucose, oxygen saturation
  - Body measurements: weight, height, body fat, BMI
  - Sleep: sleep sessions with stages
  - Workouts: exercise sessions
  - Nutrition: hydration, macros
- Permission management (read/write)
- TypeScript support with comprehensive types
- Example app demonstrating all features

[2.0.0]: https://github.com/dayaki/react-native-health-kits/releases/tag/v2.0.0
[1.0.0]: https://github.com/dayaki/react-native-health-kits/releases/tag/v1.0.0
