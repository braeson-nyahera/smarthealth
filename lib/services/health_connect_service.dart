import 'dart:developer' as developer;
import 'package:health/health.dart';

/// Service for accessing health data from Android Health Connect and iOS HealthKit
/// This provides universal access to health data from any compatible smartwatch/device
/// including Oraimo, Samsung, Fitbit, Garmin, Apple Watch, and 50+ other brands
class HealthConnectService {
  static final HealthConnectService _instance =
      HealthConnectService._internal();
  factory HealthConnectService() => _instance;
  HealthConnectService._internal();

  Health? _health;
  bool _isInitialized = false;

  /// All supported health data types we want to access
  static const List<HealthDataType> _healthDataTypes = [
    // Core vitals
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_OXYGEN,

    // Activity data
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,

    // Sleep data
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,

    // Body metrics
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_MASS_INDEX,

    // Exercise data
    HealthDataType.WORKOUT,
  ];

  /// Initialize Health Connect service and request permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _health = Health();

      // Request permissions for health data access
      bool permissionsGranted = await _health!.requestAuthorization(
        _healthDataTypes,
      );

      if (!permissionsGranted) {
        developer.log(
          'Health Connect permissions not granted',
          name: 'HealthConnect',
        );
        return false;
      }

      _isInitialized = true;
      developer.log(
        'Health Connect initialized successfully',
        name: 'HealthConnect',
      );
      return true;
    } catch (e) {
      developer.log(
        'Failed to initialize Health Connect: $e',
        name: 'HealthConnect',
      );
      return false;
    }
  }

  /// Check if Health Connect is available on this device
  Future<bool> isAvailable() async {
    try {
      _health ??= Health();

      // Try to configure Health Connect - this will tell us if it's available
      _health!.configure();

      // Try a simple permission check to verify Health Connect is responsive
      final hasStepsPermission = await _health!.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );

      developer.log(
        'Health Connect available: ${hasStepsPermission != null}',
        name: 'HealthConnect',
      );

      // If hasPermissions returns null, Health Connect is not available
      // If it returns true/false, Health Connect is available (just not authorized yet)
      return hasStepsPermission != null;
    } catch (e) {
      developer.log('Health Connect not available: $e', name: 'HealthConnect');
      return false;
    }
  }

  /// Get health data for the specified time period
  Future<Map<String, dynamic>> getHealthData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) {
        return _getEmptyHealthData();
      }
    }

    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 7));
    final end = endDate ?? now;

    try {
      // Fetch health data from Health Connect
      List<HealthDataPoint> healthData = await _health!.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _healthDataTypes,
      );

      developer.log(
        'Retrieved ${healthData.length} health data points from Health Connect',
        name: 'HealthConnect',
      );

      // Process and organize the data
      return _processHealthData(healthData);
    } catch (e) {
      developer.log('Error fetching health data: $e', name: 'HealthConnect');
      return _getEmptyHealthData();
    }
  }

  /// Process raw health data into organized format
  Map<String, dynamic> _processHealthData(List<HealthDataPoint> healthData) {
    final Map<String, dynamic> organizedData = _getEmptyHealthData();

    // Group data by type
    for (HealthDataPoint point in healthData) {
      final value = point.value;
      final timestamp = point.dateFrom;

      switch (point.type) {
        case HealthDataType.STEPS:
          if (value is NumericHealthValue) {
            organizedData['steps'] =
                (organizedData['steps'] as int) + value.numericValue.toInt();
          }
          break;

        case HealthDataType.HEART_RATE:
          if (value is NumericHealthValue) {
            (organizedData['heart_rate'] as List<Map<String, dynamic>>).add({
              'value': value.numericValue.toInt(),
              'timestamp': timestamp.toIso8601String(),
            });
          }
          break;

        case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
          if (value is NumericHealthValue) {
            _addBloodPressureReading(
              organizedData,
              'systolic',
              value.numericValue.toInt(),
              timestamp,
            );
          }
          break;

        case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
          if (value is NumericHealthValue) {
            _addBloodPressureReading(
              organizedData,
              'diastolic',
              value.numericValue.toInt(),
              timestamp,
            );
          }
          break;

        case HealthDataType.BLOOD_OXYGEN:
          if (value is NumericHealthValue) {
            (organizedData['oxygen_saturation'] as List<Map<String, dynamic>>)
                .add({
                  'value': value.numericValue.toInt(),
                  'timestamp': timestamp.toIso8601String(),
                });
          }
          break;

        case HealthDataType.ACTIVE_ENERGY_BURNED:
          if (value is NumericHealthValue) {
            organizedData['calories'] =
                (organizedData['calories'] as int) + value.numericValue.toInt();
          }
          break;

        case HealthDataType.DISTANCE_WALKING_RUNNING:
          if (value is NumericHealthValue) {
            organizedData['distance'] =
                organizedData['distance'] +
                (value.numericValue / 1000); // Convert to km
          }
          break;

        case HealthDataType.SLEEP_ASLEEP:
        case HealthDataType.SLEEP_DEEP:
        case HealthDataType.SLEEP_LIGHT:
        case HealthDataType.SLEEP_REM:
          if (value is NumericHealthValue) {
            organizedData['sleep_hours'] =
                organizedData['sleep_hours'] +
                (value.numericValue / 60); // Convert to hours
          }
          break;

        default:
          // Handle other data types as needed
          break;
      }
    }

    // Calculate averages for heart rate and oxygen saturation
    _calculateAverages(organizedData);

    return organizedData;
  }

  /// Add blood pressure reading, handling pairing of systolic/diastolic
  void _addBloodPressureReading(
    Map<String, dynamic> data,
    String type,
    int value,
    DateTime timestamp,
  ) {
    final bloodPressureList =
        data['blood_pressure'] as List<Map<String, dynamic>>;
    final timestampStr = timestamp.toIso8601String();

    // Try to find existing reading for this timestamp
    final existingIndex = bloodPressureList.indexWhere(
      (reading) => reading['timestamp'] == timestampStr,
    );

    if (existingIndex != -1) {
      // Update existing reading
      bloodPressureList[existingIndex][type] = value;
    } else {
      // Create new reading
      bloodPressureList.add({'timestamp': timestampStr, type: value});
    }
  }

  /// Calculate averages for metrics that have multiple readings
  void _calculateAverages(Map<String, dynamic> data) {
    // Heart rate average
    final heartRateList = data['heart_rate'] as List<Map<String, dynamic>>;
    if (heartRateList.isNotEmpty) {
      final average =
          heartRateList
              .map((reading) => reading['value'] as int)
              .reduce((a, b) => a + b) /
          heartRateList.length;
      data['heart_rate_avg'] = average.round();
    }

    // Oxygen saturation average
    final oxygenList = data['oxygen_saturation'] as List<Map<String, dynamic>>;
    if (oxygenList.isNotEmpty) {
      final average =
          oxygenList
              .map((reading) => reading['value'] as int)
              .reduce((a, b) => a + b) /
          oxygenList.length;
      data['oxygen_saturation_avg'] = average.round();
    }

    // Blood pressure averages
    final bpList = data['blood_pressure'] as List<Map<String, dynamic>>;
    if (bpList.isNotEmpty) {
      final systolicReadings =
          bpList
              .where((reading) => reading.containsKey('systolic'))
              .map((reading) => reading['systolic'] as int)
              .toList();

      final diastolicReadings =
          bpList
              .where((reading) => reading.containsKey('diastolic'))
              .map((reading) => reading['diastolic'] as int)
              .toList();

      if (systolicReadings.isNotEmpty) {
        data['blood_pressure_systolic_avg'] =
            (systolicReadings.reduce((a, b) => a + b) / systolicReadings.length)
                .round();
      }

      if (diastolicReadings.isNotEmpty) {
        data['blood_pressure_diastolic_avg'] =
            (diastolicReadings.reduce((a, b) => a + b) /
                    diastolicReadings.length)
                .round();
      }
    }
  }

  /// Get empty health data structure
  Map<String, dynamic> _getEmptyHealthData() {
    return {
      'steps': 0,
      'heart_rate': <Map<String, dynamic>>[],
      'heart_rate_avg': 0,
      'blood_pressure': <Map<String, dynamic>>[],
      'blood_pressure_systolic_avg': 0,
      'blood_pressure_diastolic_avg': 0,
      'oxygen_saturation': <Map<String, dynamic>>[],
      'oxygen_saturation_avg': 0,
      'calories': 0,
      'distance': 0.0,
      'sleep_hours': 0.0,
      'data_source': 'Health Connect',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Get supported data types on this device
  Future<List<HealthDataType>> getSupportedTypes() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check which types are actually supported
      List<HealthDataType> supportedTypes = [];
      for (HealthDataType type in _healthDataTypes) {
        bool hasPermission = await _health!.hasPermissions([type]) ?? false;
        if (hasPermission) {
          supportedTypes.add(type);
        }
      }
      return supportedTypes;
    } catch (e) {
      developer.log(
        'Error checking supported types: $e',
        name: 'HealthConnect',
      );
      return [];
    }
  }

  /// Get data source information
  Future<Map<String, dynamic>> getDataSources() async {
    return {
      'service_name': 'Health Connect',
      'description':
          'Universal health data from Android Health Connect & iOS HealthKit',
      'supported_devices': [
        'Oraimo smartwatches',
        'Samsung Galaxy Watch',
        'Fitbit devices',
        'Garmin watches',
        'Wear OS devices',
        'iPhone Health app',
        'Google Fit',
        'And 50+ other health apps and devices',
      ],
      'blood_pressure_support': true,
      'real_time_sync': true,
      'platform': 'Universal (Android/iOS)',
    };
  }
}
