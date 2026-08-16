import type { HealthUnit } from '../types';

/**
 * Unit conversion utilities for normalizing health data between platforms
 */

/**
 * Convert distance to meters
 */
export function toMeters(value: number, fromUnit: HealthUnit): number {
  switch (fromUnit) {
    case 'meters':
      return value;
    case 'kilometers':
      return value * 1000;
    case 'miles':
      return value * 1609.344;
    case 'feet':
      return value * 0.3048;
    default:
      return value;
  }
}

/**
 * Convert meters to specified unit
 */
export function fromMeters(value: number, toUnit: HealthUnit): number {
  switch (toUnit) {
    case 'meters':
      return value;
    case 'kilometers':
      return value / 1000;
    case 'miles':
      return value / 1609.344;
    case 'feet':
      return value / 0.3048;
    default:
      return value;
  }
}

/**
 * Convert mass to kilograms
 */
export function toKilograms(value: number, fromUnit: HealthUnit): number {
  switch (fromUnit) {
    case 'kg':
      return value;
    case 'lbs':
      return value * 0.453592;
    case 'grams':
      return value / 1000;
    default:
      return value;
  }
}

/**
 * Convert kilograms to specified unit
 */
export function fromKilograms(value: number, toUnit: HealthUnit): number {
  switch (toUnit) {
    case 'kg':
      return value;
    case 'lbs':
      return value / 0.453592;
    case 'grams':
      return value * 1000;
    default:
      return value;
  }
}

/**
 * Convert temperature to Celsius
 */
export function toCelsius(value: number, fromUnit: HealthUnit): number {
  switch (fromUnit) {
    case 'celsius':
      return value;
    case 'fahrenheit':
      return (value - 32) * (5 / 9);
    default:
      return value;
  }
}

/**
 * Convert Celsius to specified unit
 */
export function fromCelsius(value: number, toUnit: HealthUnit): number {
  switch (toUnit) {
    case 'celsius':
      return value;
    case 'fahrenheit':
      return value * (9 / 5) + 32;
    default:
      return value;
  }
}

/**
 * Convert blood glucose to mg/dL
 */
export function toMgDL(value: number, fromUnit: HealthUnit): number {
  switch (fromUnit) {
    case 'mgdL':
      return value;
    case 'mmolL':
      return value * 18.0182;
    default:
      return value;
  }
}

/**
 * Convert mg/dL to specified unit
 */
export function fromMgDL(value: number, toUnit: HealthUnit): number {
  switch (toUnit) {
    case 'mgdL':
      return value;
    case 'mmolL':
      return value / 18.0182;
    default:
      return value;
  }
}

/**
 * Convert energy to kilocalories
 */
export function toKcal(value: number, fromUnit: HealthUnit): number {
  switch (fromUnit) {
    case 'kcal':
      return value;
    case 'joules':
      return value / 4184;
    default:
      return value;
  }
}

/**
 * Convert kilocalories to specified unit
 */
export function fromKcal(value: number, toUnit: HealthUnit): number {
  switch (toUnit) {
    case 'kcal':
      return value;
    case 'joules':
      return value * 4184;
    default:
      return value;
  }
}

/**
 * Convert volume to liters
 */
export function toLiters(value: number, fromUnit: HealthUnit): number {
  switch (fromUnit) {
    case 'liters':
      return value;
    case 'milliliters':
      return value / 1000;
    default:
      return value;
  }
}

/**
 * Convert liters to specified unit
 */
export function fromLiters(value: number, toUnit: HealthUnit): number {
  switch (toUnit) {
    case 'liters':
      return value;
    case 'milliliters':
      return value * 1000;
    default:
      return value;
  }
}

/**
 * Convert time to minutes
 */
export function toMinutes(value: number, fromUnit: HealthUnit): number {
  switch (fromUnit) {
    case 'minutes':
      return value;
    case 'seconds':
      return value / 60;
    case 'hours':
      return value * 60;
    default:
      return value;
  }
}

/**
 * Convert minutes to specified unit
 */
export function fromMinutes(value: number, toUnit: HealthUnit): number {
  switch (toUnit) {
    case 'minutes':
      return value;
    case 'seconds':
      return value * 60;
    case 'hours':
      return value / 60;
    default:
      return value;
  }
}

/**
 * Get the default unit for a health data type
 */
export function getDefaultUnit(dataType: string): HealthUnit {
  switch (dataType) {
    case 'steps':
    case 'floorsClimbed':
      return 'count';
    case 'distance':
      return 'meters';
    case 'activeCalories':
    case 'basalCalories':
    case 'totalCalories':
      return 'kcal';
    case 'heartRate':
    case 'restingHeartRate':
      return 'bpm';
    case 'heartRateVariability':
      return 'seconds';
    case 'bloodPressureSystolic':
    case 'bloodPressureDiastolic':
      return 'mmHg';
    case 'bloodGlucose':
      return 'mgdL';
    case 'oxygenSaturation':
    case 'bodyFatPercentage':
      return 'percent';
    case 'bodyTemperature':
      return 'celsius';
    case 'respiratoryRate':
      return 'breathsPerMinute';
    case 'weight':
    case 'leanBodyMass':
      return 'kg';
    case 'height':
      return 'meters';
    case 'bmi':
      return 'count';
    case 'hydration':
      return 'liters';
    default:
      return 'count';
  }
}
