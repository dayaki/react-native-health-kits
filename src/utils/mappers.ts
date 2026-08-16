import type { HealthDataType, WorkoutType, SleepStage } from '../types';

/**
 * Maps unified health data types to iOS HealthKit identifiers
 *
 * A type backed by more than one identifier is derived from all of them —
 * `totalCalories` is the sum of active and basal energy, since HealthKit has
 * no single "total energy burned" quantity type.
 */
export const healthDataTypeToiOS: Record<HealthDataType, string | string[]> = {
  // Activity
  steps: 'HKQuantityTypeIdentifierStepCount',
  distance: 'HKQuantityTypeIdentifierDistanceWalkingRunning',
  activeCalories: 'HKQuantityTypeIdentifierActiveEnergyBurned',
  basalCalories: 'HKQuantityTypeIdentifierBasalEnergyBurned',
  totalCalories: [
    'HKQuantityTypeIdentifierActiveEnergyBurned',
    'HKQuantityTypeIdentifierBasalEnergyBurned',
  ],
  floorsClimbed: 'HKQuantityTypeIdentifierFlightsClimbed',
  // Vitals
  heartRate: 'HKQuantityTypeIdentifierHeartRate',
  restingHeartRate: 'HKQuantityTypeIdentifierRestingHeartRate',
  heartRateVariability: 'HKQuantityTypeIdentifierHeartRateVariabilitySDNN',
  bloodPressureSystolic: 'HKQuantityTypeIdentifierBloodPressureSystolic',
  bloodPressureDiastolic: 'HKQuantityTypeIdentifierBloodPressureDiastolic',
  bloodGlucose: 'HKQuantityTypeIdentifierBloodGlucose',
  oxygenSaturation: 'HKQuantityTypeIdentifierOxygenSaturation',
  bodyTemperature: 'HKQuantityTypeIdentifierBodyTemperature',
  respiratoryRate: 'HKQuantityTypeIdentifierRespiratoryRate',
  // Body Measurements
  weight: 'HKQuantityTypeIdentifierBodyMass',
  height: 'HKQuantityTypeIdentifierHeight',
  bodyFatPercentage: 'HKQuantityTypeIdentifierBodyFatPercentage',
  bmi: 'HKQuantityTypeIdentifierBodyMassIndex',
  leanBodyMass: 'HKQuantityTypeIdentifierLeanBodyMass',
  // Sleep
  sleep: 'HKCategoryTypeIdentifierSleepAnalysis',
  // Workouts
  workout: 'HKWorkoutType',
  // Nutrition
  hydration: 'HKQuantityTypeIdentifierDietaryWater',
  nutrition: 'HKCorrelationTypeIdentifierFood',
};

/**
 * Maps unified health data types to Android Health Connect record types
 *
 * `basalCalories` is derived: Health Connect stores a basal metabolic *rate*,
 * which the library turns into energy via the `BASAL_CALORIES_TOTAL` metric.
 */
export const healthDataTypeToAndroid: Record<
  HealthDataType,
  string | string[]
> = {
  // Activity
  steps: 'StepsRecord',
  distance: 'DistanceRecord',
  activeCalories: 'ActiveCaloriesBurnedRecord',
  basalCalories: 'BasalMetabolicRateRecord',
  totalCalories: 'TotalCaloriesBurnedRecord',
  floorsClimbed: 'FloorsClimbedRecord',
  // Vitals
  heartRate: 'HeartRateRecord',
  restingHeartRate: 'RestingHeartRateRecord',
  heartRateVariability: 'HeartRateVariabilityRmssdRecord',
  bloodPressureSystolic: 'BloodPressureRecord',
  bloodPressureDiastolic: 'BloodPressureRecord',
  bloodGlucose: 'BloodGlucoseRecord',
  oxygenSaturation: 'OxygenSaturationRecord',
  bodyTemperature: 'BodyTemperatureRecord',
  respiratoryRate: 'RespiratoryRateRecord',
  // Body Measurements
  weight: 'WeightRecord',
  height: 'HeightRecord',
  bodyFatPercentage: 'BodyFatRecord',
  bmi: 'BoneMassRecord', // Note: BMI is calculated, not stored directly
  leanBodyMass: 'LeanBodyMassRecord',
  // Sleep
  sleep: 'SleepSessionRecord',
  // Workouts
  workout: 'ExerciseSessionRecord',
  // Nutrition
  hydration: 'HydrationRecord',
  nutrition: 'NutritionRecord',
};

/**
 * Maps unified workout types to iOS HKWorkoutActivityType
 */
export const workoutTypeToiOS: Record<WorkoutType, number> = {
  walking: 52, // HKWorkoutActivityTypeWalking
  running: 37, // HKWorkoutActivityTypeRunning
  cycling: 13, // HKWorkoutActivityTypeCycling
  swimming: 46, // HKWorkoutActivityTypeSwimming
  hiking: 24, // HKWorkoutActivityTypeHiking
  yoga: 50, // HKWorkoutActivityTypeYoga
  strengthTraining: 20, // HKWorkoutActivityTypeFunctionalStrengthTraining
  functionalStrengthTraining: 20,
  traditionalStrengthTraining: 50,
  dance: 14, // HKWorkoutActivityTypeDance
  elliptical: 16, // HKWorkoutActivityTypeElliptical
  rowing: 35, // HKWorkoutActivityTypeRowing
  stairClimbing: 44, // HKWorkoutActivityTypeStairClimbing
  highIntensityIntervalTraining: 63, // HKWorkoutActivityTypeHighIntensityIntervalTraining
  jumpRope: 27, // HKWorkoutActivityTypeJumpRope
  pilates: 33, // HKWorkoutActivityTypePilates
  soccer: 43, // HKWorkoutActivityTypeSoccer
  basketball: 4, // HKWorkoutActivityTypeBasketball
  tennis: 47, // HKWorkoutActivityTypeTennis
  badminton: 2, // HKWorkoutActivityTypeBadminton
  martialArts: 29, // HKWorkoutActivityTypeMartialArts
  golf: 21, // HKWorkoutActivityTypeGolf
  baseball: 3, // HKWorkoutActivityTypeBaseball
  softball: 42, // HKWorkoutActivityTypeSoftball
  volleyball: 51, // HKWorkoutActivityTypeVolleyball
  tableTennis: 45, // HKWorkoutActivityTypeTableTennis
  skating: 38, // HKWorkoutActivityTypeSkating
  crossCountrySkiing: 11, // HKWorkoutActivityTypeCrossCountrySkiing
  downhillSkiing: 15, // HKWorkoutActivityTypeDownhillSkiing
  snowboarding: 41, // HKWorkoutActivityTypeSnowboarding
  surfing: 48, // HKWorkoutActivityTypeSurfingSports
  waterPolo: 54, // HKWorkoutActivityTypeWaterPolo
  other: 3000, // HKWorkoutActivityTypeOther
};

/**
 * Maps unified workout types to Android ExerciseSessionRecord types
 */
export const workoutTypeToAndroid: Record<WorkoutType, number> = {
  walking: 79, // EXERCISE_TYPE_WALKING
  running: 56, // EXERCISE_TYPE_RUNNING
  cycling: 8, // EXERCISE_TYPE_BIKING
  swimming: 74, // EXERCISE_TYPE_SWIMMING_POOL
  hiking: 37, // EXERCISE_TYPE_HIKING
  yoga: 80, // EXERCISE_TYPE_YOGA
  strengthTraining: 78, // EXERCISE_TYPE_WEIGHTLIFTING
  functionalStrengthTraining: 78,
  traditionalStrengthTraining: 78,
  dance: 14, // EXERCISE_TYPE_DANCING
  elliptical: 25, // EXERCISE_TYPE_ELLIPTICAL
  rowing: 55, // EXERCISE_TYPE_ROWING
  stairClimbing: 68, // EXERCISE_TYPE_STAIR_CLIMBING
  highIntensityIntervalTraining: 35, // EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING
  jumpRope: 44, // EXERCISE_TYPE_JUMPING_ROPE
  pilates: 51, // EXERCISE_TYPE_PILATES
  soccer: 64, // EXERCISE_TYPE_SOCCER
  basketball: 4, // EXERCISE_TYPE_BASKETBALL
  tennis: 76, // EXERCISE_TYPE_TENNIS
  badminton: 2, // EXERCISE_TYPE_BADMINTON
  martialArts: 47, // EXERCISE_TYPE_MARTIAL_ARTS
  golf: 32, // EXERCISE_TYPE_GOLF
  baseball: 3, // EXERCISE_TYPE_BASEBALL
  softball: 65, // EXERCISE_TYPE_SOFTBALL
  volleyball: 77, // EXERCISE_TYPE_VOLLEYBALL
  tableTennis: 75, // EXERCISE_TYPE_TABLE_TENNIS
  skating: 59, // EXERCISE_TYPE_SKATING
  crossCountrySkiing: 13, // EXERCISE_TYPE_CROSS_COUNTRY_SKIING
  downhillSkiing: 63, // EXERCISE_TYPE_SKIING
  snowboarding: 66, // EXERCISE_TYPE_SNOWBOARDING
  surfing: 72, // EXERCISE_TYPE_SURFING
  waterPolo: 29, // EXERCISE_TYPE_WATER_POLO
  other: 0, // EXERCISE_TYPE_OTHER_WORKOUT
};

/**
 * Maps iOS HKWorkoutActivityType to unified workout type
 */
export const iOSToWorkoutType: Record<number, WorkoutType> = Object.entries(
  workoutTypeToiOS
).reduce(
  (acc, [key, value]) => {
    acc[value] = key as WorkoutType;
    return acc;
  },
  {} as Record<number, WorkoutType>
);

/**
 * Maps Android ExerciseSessionRecord types to unified workout type
 */
export const androidToWorkoutType: Record<number, WorkoutType> = Object.entries(
  workoutTypeToAndroid
).reduce(
  (acc, [key, value]) => {
    acc[value] = key as WorkoutType;
    return acc;
  },
  {} as Record<number, WorkoutType>
);

/**
 * Maps unified sleep stages to iOS HKCategoryValueSleepAnalysis
 */
export const sleepStageToiOS: Record<SleepStage, number> = {
  inBed: 0, // HKCategoryValueSleepAnalysisInBed
  asleep: 1, // HKCategoryValueSleepAnalysisAsleep (deprecated but still used)
  awake: 2, // HKCategoryValueSleepAnalysisAwake
  light: 3, // HKCategoryValueSleepAnalysisAsleepCore
  deep: 4, // HKCategoryValueSleepAnalysisAsleepDeep
  rem: 5, // HKCategoryValueSleepAnalysisAsleepREM
  unknown: 0,
};

/**
 * Maps unified sleep stages to Android SleepSessionRecord.StageType
 */
export const sleepStageToAndroid: Record<SleepStage, number> = {
  unknown: 0, // STAGE_TYPE_UNKNOWN
  awake: 1, // STAGE_TYPE_AWAKE
  light: 4, // STAGE_TYPE_LIGHT
  deep: 5, // STAGE_TYPE_DEEP
  rem: 6, // STAGE_TYPE_REM
  asleep: 3, // STAGE_TYPE_SLEEPING (generic)
  inBed: 7, // STAGE_TYPE_OUT_OF_BED (closest equivalent)
};

/**
 * Maps iOS sleep stage values to unified sleep stages
 */
export const iOSToSleepStage: Record<number, SleepStage> = {
  0: 'inBed',
  1: 'asleep',
  2: 'awake',
  3: 'light',
  4: 'deep',
  5: 'rem',
};

/**
 * Maps Android sleep stage values to unified sleep stages
 */
export const androidToSleepStage: Record<number, SleepStage> = {
  0: 'unknown',
  1: 'awake',
  2: 'asleep', // STAGE_TYPE_SLEEPING_LIGHT (deprecated)
  3: 'asleep', // STAGE_TYPE_SLEEPING
  4: 'light',
  5: 'deep',
  6: 'rem',
  7: 'inBed', // STAGE_TYPE_OUT_OF_BED
};

/**
 * Convert a Date or string to ISO 8601 format
 */
export function toISOString(date: Date | string): string {
  if (typeof date === 'string') {
    return new Date(date).toISOString();
  }
  return date.toISOString();
}

/**
 * Parse an ISO 8601 string to Date
 */
export function fromISOString(isoString: string): Date {
  return new Date(isoString);
}
