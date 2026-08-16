# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Android: `readData` now honors `aggregate` / `aggregateInterval` using Health
  Connect's aggregate APIs (`aggregateGroupByPeriod` for day/week/month,
  `aggregateGroupByDuration` for hour), reaching parity with iOS.
- New `basalCalories` data type for resting/basal energy, on both platforms.
  iOS reads `basalEnergyBurned` directly; Android derives it from
  `BasalMetabolicRateRecord` via `BASAL_CALORIES_TOTAL`.
- Android: `writeData` supports `totalCalories`, which previously fell through
  the `when` and silently resolved `false`.

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
- Raised the iOS deployment target from 13.0 to 16.0. The Swift sources use
  `HKCategoryValueSleepAnalysis.asleepUnspecified` (iOS 16+) and
  `HKWorkoutActivityType.dance` (iOS 14+), so the previous 13.0 floor never
  actually compiled. The podspec and README now reflect the real minimum
  (fixes #3).

### Fixed
- Aggregation is now restricted to cumulative types (`steps`, `distance`,
  `activeCalories`, `basalCalories`, `totalCalories`, `floorsClimbed`,
  `hydration`) on both platforms. Previously iOS silently summed instantaneous
  types (e.g. `heartRate`, `weight`), and Android ignored `aggregate` entirely.
  Unsupported types now reject with `UNSUPPORTED_DATA_TYPE`.
- iOS: writing `totalCalories` no longer silently stores the value as basal
  energy. Derived types reject instead, pointing at the types to write.

## [1.0.0] - 2025-11-26

### Added
- Initial release of @dayaki/react-native-health-kits
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

[1.0.0]: https://github.com/dayaki/react-native-health-kits/releases/tag/v1.0.0