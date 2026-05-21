/**
 * Health data types supported by both iOS HealthKit and Android Health Connect
 */
export type HealthDataType =
  // Activity
  | 'steps'
  | 'distance'
  | 'activeCalories'
  | 'totalCalories'
  | 'floorsClimbed'
  // Vitals
  | 'heartRate'
  | 'restingHeartRate'
  | 'heartRateVariability'
  | 'bloodPressureSystolic'
  | 'bloodPressureDiastolic'
  | 'bloodGlucose'
  | 'oxygenSaturation'
  | 'bodyTemperature'
  | 'respiratoryRate'
  // Body Measurements
  | 'weight'
  | 'height'
  | 'bodyFatPercentage'
  | 'bmi'
  | 'leanBodyMass'
  // Sleep
  | 'sleep'
  // Workouts
  | 'workout'
  // Nutrition
  | 'hydration'
  | 'nutrition';

/**
 * Permission access type
 */
export type PermissionAccess = 'read' | 'write';

/**
 * Permission request object
 */
export interface HealthPermission {
  /** The type of health data */
  type: HealthDataType;
  /** Whether to request read or write access */
  access: PermissionAccess;
}

/**
 * Permission status returned from the native module
 */
export type PermissionStatus =
  | 'authorized'
  | 'denied'
  | 'notDetermined'
  | 'unavailable';

/**
 * Units for health data values
 */
export type HealthUnit =
  // Count
  | 'count'
  // Distance
  | 'meters'
  | 'kilometers'
  | 'miles'
  | 'feet'
  // Mass
  | 'kg'
  | 'lbs'
  | 'grams'
  // Energy
  | 'kcal'
  | 'joules'
  // Temperature
  | 'celsius'
  | 'fahrenheit'
  // Blood glucose
  | 'mgdL'
  | 'mmolL'
  // Blood pressure
  | 'mmHg'
  // Percentage
  | 'percent'
  // Heart rate
  | 'bpm'
  // Respiratory rate
  | 'breathsPerMinute'
  // Volume
  | 'liters'
  | 'milliliters'
  // Time
  | 'minutes'
  | 'seconds'
  | 'hours';

/**
 * Sleep stages
 */
export type SleepStage =
  | 'awake'
  | 'light'
  | 'deep'
  | 'rem'
  | 'asleep' // Generic sleep (when stages not available)
  | 'inBed'
  | 'unknown';

/**
 * Workout/Exercise types supported by both platforms
 */
export type WorkoutType =
  | 'walking'
  | 'running'
  | 'cycling'
  | 'swimming'
  | 'hiking'
  | 'yoga'
  | 'strengthTraining'
  | 'functionalStrengthTraining'
  | 'traditionalStrengthTraining'
  | 'dance'
  | 'elliptical'
  | 'rowing'
  | 'stairClimbing'
  | 'highIntensityIntervalTraining'
  | 'jumpRope'
  | 'pilates'
  | 'soccer'
  | 'basketball'
  | 'tennis'
  | 'badminton'
  | 'martialArts'
  | 'golf'
  | 'baseball'
  | 'softball'
  | 'volleyball'
  | 'tableTennis'
  | 'skating'
  | 'crossCountrySkiing'
  | 'downhillSkiing'
  | 'snowboarding'
  | 'surfing'
  | 'waterPolo'
  | 'other';

/**
 * Cumulative data types that support aggregation.
 *
 * Aggregation produces a cumulative sum per interval, which only has a
 * well-defined meaning for these types. Requesting aggregation for any other
 * (instantaneous) type rejects with `UNSUPPORTED_DATA_TYPE`.
 */
export type CumulativeDataType =
  | 'steps'
  | 'distance'
  | 'activeCalories'
  | 'totalCalories'
  | 'floorsClimbed'
  | 'hydration';

/**
 * Options for reading health data
 */
export interface ReadOptions {
  /** The type of health data to read */
  type: HealthDataType;
  /** Start date for the query (ISO 8601 string or Date) */
  startDate: Date | string;
  /** End date for the query (ISO 8601 string or Date) */
  endDate: Date | string;
  /** Maximum number of records to return (ignored when `aggregate` is true) */
  limit?: number;
  /**
   * Aggregate into a cumulative sum per interval.
   *
   * Supported only for {@link CumulativeDataType} (steps, distance,
   * activeCalories, totalCalories, floorsClimbed, hydration) on both iOS and
   * Android. Requesting it for any other type rejects with
   * `UNSUPPORTED_DATA_TYPE` — read those as raw records and aggregate in app
   * code instead.
   *
   * Aggregated results are derived/synthetic: they have generated `id`s and an
   * `"aggregated"` source, so they are not stable or deduplicable. For
   * sync/storage, persist raw records instead and aggregate at read time.
   */
  aggregate?: boolean;
  /** Aggregation interval when `aggregate` is true. Defaults to `'day'`. */
  aggregateInterval?: 'hour' | 'day' | 'week' | 'month';
}

/**
 * Base health data record
 */
export interface HealthRecord {
  /** Unique identifier for the record */
  id: string;
  /** Type of health data */
  type: HealthDataType;
  /** Start time of the record (ISO 8601) */
  startDate: string;
  /** End time of the record (ISO 8601) */
  endDate: string;
  /** Source application or device */
  sourceName: string;
  /** Source bundle identifier */
  sourceId: string;
}

/**
 * Quantity health data (steps, distance, calories, etc.)
 */
export interface QuantityRecord extends HealthRecord {
  /** The numeric value */
  value: number;
  /** The unit of measurement */
  unit: HealthUnit;
}

/**
 * Blood pressure record
 */
export interface BloodPressureRecord extends HealthRecord {
  type: 'bloodPressureSystolic' | 'bloodPressureDiastolic';
  /** Systolic pressure value */
  systolic: number;
  /** Diastolic pressure value */
  diastolic: number;
  /** Unit (always mmHg) */
  unit: 'mmHg';
}

/**
 * Sleep session record
 */
export interface SleepRecord extends HealthRecord {
  type: 'sleep';
  /** Total sleep duration in minutes */
  duration: number;
  /** Sleep stages breakdown */
  stages: SleepStageRecord[];
}

/**
 * Individual sleep stage within a sleep session
 */
export interface SleepStageRecord {
  /** Sleep stage type */
  stage: SleepStage;
  /** Start time (ISO 8601) */
  startDate: string;
  /** End time (ISO 8601) */
  endDate: string;
  /** Duration in minutes */
  duration: number;
}

/**
 * Workout/Exercise session record
 */
export interface WorkoutRecord extends HealthRecord {
  type: 'workout';
  /** Type of workout */
  workoutType: WorkoutType;
  /** Duration in minutes */
  duration: number;
  /** Total energy burned in kcal */
  totalEnergyBurned?: number;
  /** Total distance in meters */
  totalDistance?: number;
  /** Average heart rate in bpm */
  averageHeartRate?: number;
  /** Max heart rate in bpm */
  maxHeartRate?: number;
}

/**
 * Nutrition record
 */
export interface NutritionRecord extends HealthRecord {
  type: 'nutrition';
  /** Meal name or description */
  mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'unknown';
  /** Calories in kcal */
  calories?: number;
  /** Protein in grams */
  protein?: number;
  /** Carbohydrates in grams */
  carbohydrates?: number;
  /** Total fat in grams */
  fat?: number;
  /** Saturated fat in grams */
  saturatedFat?: number;
  /** Fiber in grams */
  fiber?: number;
  /** Sugar in grams */
  sugar?: number;
  /** Sodium in milligrams */
  sodium?: number;
}

/**
 * Union type for all health data records
 */
export type HealthData =
  | QuantityRecord
  | BloodPressureRecord
  | SleepRecord
  | WorkoutRecord
  | NutritionRecord;

/**
 * Base write data interface
 */
export interface WriteDataBase {
  /** The type of health data to write */
  type: HealthDataType;
  /** Date/time of the record (ISO 8601 string or Date) */
  date: Date | string;
}

/**
 * Write data for quantity types
 */
export interface WriteQuantityData extends WriteDataBase {
  type: Exclude<HealthDataType, 'sleep' | 'workout' | 'nutrition'>;
  /** The numeric value to write */
  value: number;
  /** The unit of measurement */
  unit: HealthUnit;
  /** Optional end date for range-based data */
  endDate?: Date | string;
}

/**
 * Write data for blood pressure
 */
export interface WriteBloodPressureData extends WriteDataBase {
  type: 'bloodPressureSystolic' | 'bloodPressureDiastolic';
  /** Systolic pressure value */
  systolic: number;
  /** Diastolic pressure value */
  diastolic: number;
}

/**
 * Write data for sleep sessions
 */
export interface WriteSleepData extends WriteDataBase {
  type: 'sleep';
  /** End date of sleep session */
  endDate: Date | string;
  /** Optional sleep stages */
  stages?: Array<{
    stage: SleepStage;
    startDate: Date | string;
    endDate: Date | string;
  }>;
}

/**
 * Write data for workouts
 */
export interface WriteWorkoutData extends WriteDataBase {
  type: 'workout';
  /** Type of workout */
  workoutType: WorkoutType;
  /** End date of workout */
  endDate: Date | string;
  /** Total energy burned in kcal */
  totalEnergyBurned?: number;
  /** Total distance in meters */
  totalDistance?: number;
}

/**
 * Write data for nutrition
 */
export interface WriteNutritionData extends WriteDataBase {
  type: 'nutrition';
  /** Meal type */
  mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'unknown';
  /** Calories in kcal */
  calories?: number;
  /** Protein in grams */
  protein?: number;
  /** Carbohydrates in grams */
  carbohydrates?: number;
  /** Total fat in grams */
  fat?: number;
}

/**
 * Union type for all write data
 */
export type WriteData =
  | WriteQuantityData
  | WriteBloodPressureData
  | WriteSleepData
  | WriteWorkoutData
  | WriteNutritionData;

/**
 * Subscription callback for real-time updates
 */
export type HealthDataCallback = (data: HealthData[]) => void;

/**
 * Subscription handle for unsubscribing
 */
export interface Subscription {
  /** Remove the subscription */
  remove: () => void;
}

/**
 * Error codes for health kit operations
 */
export enum HealthKitErrorCode {
  /** Health data is not available on this device */
  NOT_AVAILABLE = 'NOT_AVAILABLE',
  /** Permission was denied by the user */
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  /** Permission has not been requested yet */
  PERMISSION_NOT_DETERMINED = 'PERMISSION_NOT_DETERMINED',
  /** The requested data type is not supported */
  UNSUPPORTED_DATA_TYPE = 'UNSUPPORTED_DATA_TYPE',
  /** Health Connect is not installed (Android only) */
  HEALTH_CONNECT_NOT_INSTALLED = 'HEALTH_CONNECT_NOT_INSTALLED',
  /** Invalid parameters provided */
  INVALID_PARAMETERS = 'INVALID_PARAMETERS',
  /** Failed to read data */
  READ_FAILED = 'READ_FAILED',
  /** Failed to write data */
  WRITE_FAILED = 'WRITE_FAILED',
  /** Unknown error occurred */
  UNKNOWN = 'UNKNOWN',
}

/**
 * Custom error class for health kit operations
 */
export class HealthKitError extends Error {
  code: HealthKitErrorCode;
  
  constructor(code: HealthKitErrorCode, message: string) {
    super(message);
    this.name = 'HealthKitError';
    this.code = code;
  }
}
