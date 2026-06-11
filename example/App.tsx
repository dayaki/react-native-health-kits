import React, { useState, useEffect } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  Platform,
  Alert,
} from 'react-native';
import HealthKits, {
  HealthData,
  HealthPermission,
  HealthKitError,
  HealthKitErrorCode,
} from '@mbdayo/react-native-health-kits';

const App = () => {
  const [isAvailable, setIsAvailable] = useState<boolean | null>(null);
  const [permissionsGranted, setPermissionsGranted] = useState(false);
  const [stepsData, setStepsData] = useState<HealthData[]>([]);
  const [heartRateData, setHeartRateData] = useState<HealthData[]>([]);
  const [dailySteps, setDailySteps] = useState<HealthData[]>([]);
  const [aggregateGuardResult, setAggregateGuardResult] = useState<string | null>(
    null
  );
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkAvailability();
  }, []);

  const checkAvailability = async () => {
    const available = await HealthKits.isAvailable();
    setIsAvailable(available);
  };

  const requestPermissions = async () => {
    setLoading(true);
    try {
      const permissions: HealthPermission[] = [
        { type: 'steps', access: 'read' },
        { type: 'heartRate', access: 'read' },
        { type: 'weight', access: 'read' },
        { type: 'weight', access: 'write' },
        { type: 'sleep', access: 'read' },
        { type: 'workout', access: 'read' },
      ];

      const granted = await HealthKits.requestPermissions(permissions);
      setPermissionsGranted(granted);
      
      if (granted) {
        Alert.alert('Success', 'Permissions granted!');
      }
    } catch (error) {
      Alert.alert('Error', `Failed to request permissions: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const readSteps = async () => {
    setLoading(true);
    try {
      const endDate = new Date();
      const startDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 7 days ago

      const data = await HealthKits.readData({
        type: 'steps',
        startDate,
        endDate,
        limit: 100,
      });

      setStepsData(data);
    } catch (error) {
      Alert.alert('Error', `Failed to read steps: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const readHeartRate = async () => {
    setLoading(true);
    try {
      const endDate = new Date();
      const startDate = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago

      const data = await HealthKits.readData({
        type: 'heartRate',
        startDate,
        endDate,
        limit: 50,
      });

      setHeartRateData(data);
    } catch (error) {
      Alert.alert('Error', `Failed to read heart rate: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const writeWeight = async () => {
    setLoading(true);
    try {
      const success = await HealthKits.writeData({
        type: 'weight',
        value: 70.5,
        unit: 'kg',
        date: new Date(),
      });

      if (success) {
        Alert.alert('Success', 'Weight data written successfully!');
      }
    } catch (error) {
      Alert.alert('Error', `Failed to write weight: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  // #8: aggregated read — daily step totals (a cumulative type).
  const readDailySteps = async () => {
    setLoading(true);
    try {
      const data = await HealthKits.readData({
        type: 'steps',
        startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days
        endDate: new Date(),
        aggregate: true,
        aggregateInterval: 'day',
      });
      setDailySteps(data);
    } catch (error) {
      Alert.alert('Error', `Failed to read daily steps: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  // #8: aggregating a non-cumulative type must reject with UNSUPPORTED_DATA_TYPE.
  const testAggregateGuard = async () => {
    setLoading(true);
    setAggregateGuardResult(null);
    try {
      await HealthKits.readData({
        type: 'heartRate',
        startDate: new Date(Date.now() - 24 * 60 * 60 * 1000),
        endDate: new Date(),
        aggregate: true,
        aggregateInterval: 'day',
      });
      setAggregateGuardResult('❌ Expected a rejection, but the call resolved');
    } catch (error) {
      if (
        error instanceof HealthKitError &&
        error.code === HealthKitErrorCode.UNSUPPORTED_DATA_TYPE
      ) {
        setAggregateGuardResult('✅ Rejected with UNSUPPORTED_DATA_TYPE (correct)');
      } else {
        setAggregateGuardResult(`⚠️ Rejected with an unexpected error: ${error}`);
      }
    } finally {
      setLoading(false);
    }
  };

  const openSettings = async () => {
    if (Platform.OS === 'android') {
      await HealthKits.openHealthConnectSettings();
    } else {
      Alert.alert('Info', 'On iOS, please open Settings > Health to manage permissions.');
    }
  };

  const getTotalSteps = () => {
    return stepsData.reduce((total, record) => {
      if ('value' in record) {
        return total + (record.value as number);
      }
      return total;
    }, 0);
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={styles.title}>Health Kits Example</Text>

        {/* Availability Status */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Health Data Availability</Text>
          <Text style={styles.status}>
            {isAvailable === null
              ? 'Checking...'
              : isAvailable
              ? '✅ Available'
              : '❌ Not Available'}
          </Text>
        </View>

        {/* Permissions */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Permissions</Text>
          <Text style={styles.status}>
            {permissionsGranted ? '✅ Granted' : '⏳ Not Requested'}
          </Text>
          <TouchableOpacity
            style={styles.button}
            onPress={requestPermissions}
            disabled={loading || !isAvailable}
          >
            <Text style={styles.buttonText}>Request Permissions</Text>
          </TouchableOpacity>
        </View>

        {/* Steps Data */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Steps (Last 7 Days)</Text>
          <TouchableOpacity
            style={styles.button}
            onPress={readSteps}
            disabled={loading || !permissionsGranted}
          >
            <Text style={styles.buttonText}>Read Steps</Text>
          </TouchableOpacity>
          {stepsData.length > 0 && (
            <View style={styles.dataContainer}>
              <Text style={styles.dataText}>
                Total Steps: {getTotalSteps().toLocaleString()}
              </Text>
              <Text style={styles.dataText}>
                Records: {stepsData.length}
              </Text>
            </View>
          )}
        </View>

        {/* Heart Rate Data */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Heart Rate (Last 24 Hours)</Text>
          <TouchableOpacity
            style={styles.button}
            onPress={readHeartRate}
            disabled={loading || !permissionsGranted}
          >
            <Text style={styles.buttonText}>Read Heart Rate</Text>
          </TouchableOpacity>
          {heartRateData.length > 0 && (
            <View style={styles.dataContainer}>
              <Text style={styles.dataText}>
                Records: {heartRateData.length}
              </Text>
              {heartRateData.slice(0, 5).map((record, index) => (
                <Text key={index} style={styles.dataText}>
                  {'value' in record ? `${record.value} bpm` : '-'}
                </Text>
              ))}
            </View>
          )}
        </View>

        {/* Aggregated Steps (#8) */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Daily Step Totals (Last 30 Days)</Text>
          <TouchableOpacity
            style={styles.button}
            onPress={readDailySteps}
            disabled={loading || !permissionsGranted}
          >
            <Text style={styles.buttonText}>Read Aggregated (daily)</Text>
          </TouchableOpacity>
          {dailySteps.length > 0 && (
            <View style={styles.dataContainer}>
              <Text style={styles.dataText}>Buckets: {dailySteps.length}</Text>
              {dailySteps.slice(0, 5).map((record, index) => (
                <Text key={index} style={styles.dataText}>
                  {record.startDate.slice(0, 10)}:{' '}
                  {'value' in record ? Math.round(record.value as number) : '-'}
                </Text>
              ))}
            </View>
          )}
        </View>

        {/* Aggregation Guard (#8) */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Aggregation Guard</Text>
          <Text style={styles.status}>
            Aggregating a non-cumulative type (heartRate) should reject.
          </Text>
          <TouchableOpacity
            style={styles.button}
            onPress={testAggregateGuard}
            disabled={loading || !permissionsGranted}
          >
            <Text style={styles.buttonText}>
              Test heartRate Aggregate (expect reject)
            </Text>
          </TouchableOpacity>
          {aggregateGuardResult && (
            <View style={styles.dataContainer}>
              <Text style={styles.dataText}>{aggregateGuardResult}</Text>
            </View>
          )}
        </View>

        {/* Write Weight */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Write Data</Text>
          <TouchableOpacity
            style={styles.button}
            onPress={writeWeight}
            disabled={loading || !permissionsGranted}
          >
            <Text style={styles.buttonText}>Write Weight (70.5 kg)</Text>
          </TouchableOpacity>
        </View>

        {/* Settings */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Settings</Text>
          <TouchableOpacity style={styles.button} onPress={openSettings}>
            <Text style={styles.buttonText}>
              {Platform.OS === 'android'
                ? 'Open Health Connect Settings'
                : 'Open Health Settings Info'}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollContent: {
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 20,
    color: '#333',
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
    color: '#333',
  },
  status: {
    fontSize: 16,
    marginBottom: 12,
    color: '#666',
  },
  button: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    padding: 12,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  dataContainer: {
    marginTop: 12,
    padding: 12,
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
  },
  dataText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
});

export default App;
