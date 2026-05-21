# @mbdayo/react-native-health-kits

A unified React Native interface for accessing health data from both **Android Health Connect** and **iOS HealthKit**.

## Features

- 🔄 **Unified API** - Single interface for both platforms
- 📊 **Comprehensive Data Types** - Steps, heart rate, sleep, workouts, nutrition, and more
- 🔐 **Permission Management** - Easy permission requests and status checks
- 📝 **Read & Write** - Full support for reading and writing health data
- 🔔 **Real-time Updates** - Subscribe to health data changes
- 📱 **Turbo Modules** - Built with React Native's new architecture

## Requirements

- React Native >= 0.70
- iOS 13.0+
- Android API 28+ (Android 9+)
  - **Android 14+**: Health Connect is built into the framework (no setup needed)
  - **Android 9-13**: Health Connect app must be installed from Play Store

## Installation

```bash
yarn add @mbdayo/react-native-health-kits
# or
pnpm add @mbdayo/react-native-health-kits
```

### iOS Setup

1. **Enable HealthKit capability** in Xcode:
   - Open your project in Xcode
   - Select your target → Signing & Capabilities
   - Click "+ Capability" and add "HealthKit"

2. **Add required Info.plist entries**:

```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your health data to display your fitness information.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>We need access to update your health data.</string>
```

3. **Install pods**:

```bash
cd ios && pod install
```

### Android Setup

1. **Add Health Connect permissions** to your `AndroidManifest.xml`:

```xml
<!-- Inside <manifest> tag -->
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.WRITE_STEPS" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.WRITE_HEART_RATE" />
<!-- Add other permissions as needed -->

<!-- Inside <application> tag -->
<activity
    android:name="androidx.health.connect.client.permission.HealthPermissionsRequestActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
    </intent-filter>
</activity>
```

2. **Ensure Health Connect is installed** on the device. The library will return `false` from `isAvailable()` if Health Connect is not installed.

## Usage

### Basic Example

```typescript
import HealthKits from '@mbdayo/react-native-health-kits';

// Check availability
const available = await HealthKits.isAvailable();

// Request permissions
const granted = await HealthKits.requestPermissions([
  { type: 'steps', access: 'read' },
  { type: 'heartRate', access: 'read' },
  { type: 'weight', access: 'write' },
]);

// Read steps data
const steps = await HealthKits.readData({
  type: 'steps',
  startDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
  endDate: new Date(),
});

// Write weight data
await HealthKits.writeData({
  type: 'weight',
  value: 70.5,
  unit: 'kg',
  date: new Date(),
});
```

### Real-time Updates

```typescript
// Subscribe to step updates
const subscription = HealthKits.subscribeToUpdates('steps', (data) => {
  console.log('New steps data:', data);
});

// Unsubscribe when done
subscription.remove();
```

### Reading Aggregated Data

```typescript
// Get daily step totals for the last month
const dailySteps = await HealthKits.readData({
  type: 'steps',
  startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
  endDate: new Date(),
  aggregate: true,
  aggregateInterval: 'day',
});
```

> **Aggregation is for cumulative types only.** `aggregate` produces a
> cumulative sum per interval, which is only meaningful for **`steps`,
> `distance`, `activeCalories`, `totalCalories`, `floorsClimbed`, and
> `hydration`**. Requesting it for any other (instantaneous) type — e.g.
> `heartRate`, `weight`, `bloodGlucose` — rejects with `UNSUPPORTED_DATA_TYPE`.
> Read those as raw records and aggregate in app code instead.
>
> This behaves the same on iOS (HealthKit `HKStatisticsCollectionQuery`) and
> Android (Health Connect `aggregateGroupByPeriod` / `aggregateGroupByDuration`).
>
> **For sync/storage, don't store aggregated results.** They are derived and
> synthetic — each query assigns a generated `id` and an `"aggregated"` source,
> so they have no stable identity and can't be deduplicated. Persist raw
> provider records as your source of truth and aggregate at read time.

### Reading Sleep Data

```typescript
const sleepData = await HealthKits.readData({
  type: 'sleep',
  startDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
  endDate: new Date(),
});

sleepData.forEach((session) => {
  if (session.type === 'sleep') {
    console.log(`Sleep duration: ${session.duration} minutes`);
    console.log('Sleep stages:', session.stages);
  }
});
```

### Writing Workout Data

```typescript
await HealthKits.writeData({
  type: 'workout',
  workoutType: 'running',
  date: new Date(Date.now() - 60 * 60 * 1000), // 1 hour ago
  endDate: new Date(),
  totalEnergyBurned: 500, // kcal
  totalDistance: 5000, // meters
});
```

## API Reference

### `isAvailable(): Promise<boolean>`

Check if health data services are available on the device.

### `requestPermissions(permissions: HealthPermission[]): Promise<boolean>`

Request permissions for specified health data types.

```typescript
interface HealthPermission {
  type: HealthDataType;
  access: 'read' | 'write';
}
```

### `getPermissionStatus(dataType: HealthDataType, access?: 'read' | 'write'): Promise<PermissionStatus>`

Get the current authorization status for a specific data type.

Returns: `'authorized' | 'denied' | 'notDetermined' | 'unavailable'`

### `readData(options: ReadOptions): Promise<HealthData[]>`

Read health data based on provided options.

```typescript
interface ReadOptions {
  type: HealthDataType;
  startDate: Date | string;
  endDate: Date | string;
  limit?: number;
  /** Cumulative types only (steps, distance, activeCalories, totalCalories, floorsClimbed, hydration). */
  aggregate?: boolean;
  /** Defaults to 'day'. */
  aggregateInterval?: 'hour' | 'day' | 'week' | 'month';
}
```

### `writeData(data: WriteData): Promise<boolean>`

Write health data.

### `subscribeToUpdates(dataType: HealthDataType, callback: Function): Subscription`

Subscribe to real-time updates for a specific health data type.

### `openHealthConnectSettings(): Promise<void>`

Open Health Connect settings on Android. No-op on iOS.

## Supported Data Types

| Data Type | iOS HealthKit | Android Health Connect |
|-----------|---------------|------------------------|
| `steps` | ✅ | ✅ |
| `distance` | ✅ | ✅ |
| `activeCalories` | ✅ | ✅ |
| `totalCalories` | ✅ | ✅ |
| `floorsClimbed` | ✅ | ✅ |
| `heartRate` | ✅ | ✅ |
| `restingHeartRate` | ✅ | ✅ |
| `heartRateVariability` | ✅ | ✅ |
| `bloodPressureSystolic` | ✅ | ✅ |
| `bloodPressureDiastolic` | ✅ | ✅ |
| `bloodGlucose` | ✅ | ✅ |
| `oxygenSaturation` | ✅ | ✅ |
| `bodyTemperature` | ✅ | ✅ |
| `respiratoryRate` | ✅ | ✅ |
| `weight` | ✅ | ✅ |
| `height` | ✅ | ✅ |
| `bodyFatPercentage` | ✅ | ✅ |
| `bmi` | ✅ | ⚠️ (calculated) |
| `leanBodyMass` | ✅ | ✅ |
| `sleep` | ✅ | ✅ |
| `workout` | ✅ | ✅ |
| `hydration` | ✅ | ✅ |
| `nutrition` | ✅ | ✅ |

## Workout Types

The following workout types are supported on both platforms:

- `walking`, `running`, `cycling`, `swimming`, `hiking`
- `yoga`, `strengthTraining`, `dance`, `elliptical`, `rowing`
- `stairClimbing`, `highIntensityIntervalTraining`, `jumpRope`, `pilates`
- `soccer`, `basketball`, `tennis`, `badminton`, `martialArts`
- `golf`, `baseball`, `softball`, `volleyball`, `tableTennis`
- `skating`, `crossCountrySkiing`, `downhillSkiing`, `snowboarding`
- `surfing`, `waterPolo`, `other`

## Error Handling

The library provides typed errors for common failure cases:

```typescript
import { HealthKitError, HealthKitErrorCode } from '@mbdayo/react-native-health-kits';

try {
  await HealthKits.readData({ ... });
} catch (error) {
  if (error instanceof HealthKitError) {
    switch (error.code) {
      case HealthKitErrorCode.NOT_AVAILABLE:
        console.log('Health data not available');
        break;
      case HealthKitErrorCode.PERMISSION_DENIED:
        console.log('Permission denied');
        break;
      case HealthKitErrorCode.HEALTH_CONNECT_NOT_INSTALLED:
        console.log('Health Connect not installed');
        break;
    }
  }
}
```

## Troubleshooting

### iOS

- **HealthKit not available**: HealthKit is only available on physical devices, not simulators.
- **Permission not showing**: Ensure you've added the required `Info.plist` entries.
- **Background updates not working**: Enable "Background Delivery" in HealthKit capabilities.

### Android

- **Health Connect not available**: On Android 9-13, ensure the Health Connect app is installed from Google Play Store. On Android 14+, it's built into the system.
- **Permissions not granted**: Users must manually grant permissions in Health Connect settings.
- **Data not syncing**: Some devices require the Health Connect app to be opened at least once.

## Platform Notes

### iOS
- HealthKit requires a physical device for testing (not available in simulator)
- Some data types require special entitlements
- HealthKit doesn't reveal if read permission was denied for privacy reasons

### Android
- Android 14+: Health Connect is part of the Android Framework (no installation needed)
- Android 9-13: Health Connect is available via Play Store app
- Permissions are managed through the Health Connect settings
- Background data access requires additional setup

## License

MIT

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting a pull request.
