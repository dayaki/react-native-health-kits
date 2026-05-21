# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- Raised the iOS deployment target from 13.0 to 16.0. The Swift sources use
  `HKCategoryValueSleepAnalysis.asleepUnspecified` (iOS 16+) and
  `HKWorkoutActivityType.dance` (iOS 14+), so the previous 13.0 floor never
  actually compiled. The podspec and README now reflect the real minimum
  (fixes #3).

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