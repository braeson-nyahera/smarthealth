import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/health_models.dart';
import '../constants/health_metrics.dart';
import '../utils/health_utils.dart';
import '../config/google_config.dart';
import 'google_fit_service.dart';
import 'health_connect_service.dart';
import 'blood_pressure_prediction_service.dart';
import 'user_profile_service.dart';

class HealthDataService {
  late GoogleSignIn _googleSignIn;
  final HealthConnectService _healthConnectService = HealthConnectService();

  HealthDataService() {
    _googleSignIn = GoogleSignIn(
      scopes: HealthMetrics.googleFitScopes,
      // Add web-specific configuration
      clientId: kIsWeb ? GoogleConfig.webClientId : null,
    );
  }

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<Map<String, dynamic>> fetchComprehensiveHealthData(
    GoogleSignInAccount user,
    int selectedDays,
  ) async {
    try {
      final auth = await user.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: selectedDays));
      final endTime = now.millisecondsSinceEpoch;
      final startTime = startDate.millisecondsSinceEpoch;

      Map<String, List<HealthDataPoint>> newTimeSeriesData = {};
      Map<String, HealthSummary> newSummaryData = {};

      // Fetch data for each metric category with individual error handling
      try {
        await _fetchActivityData(
          accessToken,
          startTime,
          endTime,
          newTimeSeriesData,
          newSummaryData,
        );
      } catch (e) {
        debugPrint('Error fetching activity data: $e');
      }

      try {
        // List available data sources for debugging (only once per session)
        await GoogleFitService.listAvailableDataSources(accessToken);

        // Fetch FitCloudPro data first for more comprehensive data
        final fitCloudProData = await GoogleFitService.fetchAllFitCloudProData(
          accessToken,
          startTime,
          endTime,
        );

        // Add FitCloudPro data to the data structures
        for (var entry in fitCloudProData.entries) {
          final dataType = entry.key;
          final points = entry.value;

          if (points.isNotEmpty) {
            String mappedKey = _mapFitCloudProDataType(dataType);
            if (mappedKey.isNotEmpty) {
              debugPrint(
                'Added FitCloudPro data: $mappedKey (${points.length} points)',
              );
              // Add to time series data
              newTimeSeriesData[mappedKey] = points;
              // Create summary data
              if (points.isNotEmpty) {
                final values = points.map((p) => p.value).toList();
                values.sort();
                final average =
                    values.fold(0.0, (a, b) => a + b) / values.length;
                final min = values.first;
                final max = values.last;
                final latest = points.last.value;
                final trend =
                    points.length > 1 ? (latest - points.first.value) : 0.0;

                final summary = HealthSummary(
                  average: average,
                  min: min,
                  max: max,
                  latest: latest,
                  trend: trend,
                );
                newSummaryData[mappedKey] = summary;
              }
            }
          }
        }

        // Explicitly try to fetch missing data types from FitCloudPro
        try {
          // Only try to fetch data types that are actually available or potentially available

          // Try sleep data from general Google Fit sources (not FitCloudPro specific)
          if (newTimeSeriesData['sleep_hours']?.isEmpty ?? true) {
            debugPrint(
              'Attempting to fetch sleep data from Google Fit sources...',
            );
            final sleepData = await GoogleFitService.fetchSleepData(
              accessToken,
              startTime,
              endTime,
            );
            if (sleepData.isNotEmpty && sleepData['sleep_duration'] != null) {
              final sleepPoints =
                  sleepData['sleep_duration'] as List<HealthDataPoint>;
              if (sleepPoints.isNotEmpty) {
                debugPrint(
                  '✅ Found ${sleepPoints.length} sleep data points from Google Fit',
                );
                newTimeSeriesData['sleep_hours'] = sleepPoints;
                final values = sleepPoints.map((p) => p.value).toList();
                values.sort();
                final summary = HealthSummary(
                  average: values.fold(0.0, (a, b) => a + b) / values.length,
                  min: values.first,
                  max: values.last,
                  latest: sleepPoints.last.value,
                  trend:
                      sleepPoints.length > 1
                          ? (sleepPoints.last.value - sleepPoints.first.value)
                          : 0.0,
                );
                newSummaryData['sleep_hours'] = summary;
              }
            }
          }
        } catch (e) {
          debugPrint('Error during explicit data type fetching: $e');
        }

        // Check specifically for available data types
        debugPrint('\n🔍 CHECKING AVAILABLE DATA TYPES:');
        final importantDataTypes = [
          'heart_rate',
          'oxygen_saturation',
          'blood_pressure',
          'sleep_hours',
          'calories',
        ];

        for (var dataType in importantDataTypes) {
          final points = newTimeSeriesData[dataType] ?? [];
          if (points.isEmpty) {
            debugPrint('  ❌ $dataType: No data found');
          } else {
            debugPrint('  ✅ $dataType: ${points.length} data points');
          }
        }

        // Provide guidance only for potentially available data types
        if ((newTimeSeriesData['blood_pressure'] ?? []).isEmpty) {
          debugPrint('\n💡 BLOOD PRESSURE DATA GUIDANCE:');
          debugPrint('  🩺 Blood pressure may need configuration:');
          debugPrint('     • Check if your smartwatch supports BP measurement');
          debugPrint('     • Enable BP tracking in FitCloudPro app settings');
          debugPrint('     • Ensure BP data sync is enabled to Google Fit');
          debugPrint('     • Take manual BP readings to generate data');
          debugPrint('     • Some smartwatches require external BP cuff');
        }

        if ((newTimeSeriesData['sleep_hours'] ?? []).isEmpty) {
          debugPrint('\n💡 SLEEP DATA GUIDANCE:');
          debugPrint('  😴 Sleep tracking may need configuration:');
          debugPrint(
            '     • Check if sleep tracking is enabled in FitCloudPro app',
          );
          debugPrint('     • Ensure you wear your smartwatch while sleeping');
          debugPrint('     • Try manual sync in FitCloudPro app');
        }

        // Final summary
        debugPrint('📊 FITCLOUDPRO DATA SUMMARY:');
        final totalAvailable =
            newTimeSeriesData.values
                .where((points) => points.isNotEmpty)
                .length;
        final totalExpected = importantDataTypes.length;
        debugPrint('   Available: $totalAvailable/$totalExpected data types');

        final availableTypes =
            newTimeSeriesData.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) => entry.key)
                .toList();

        if (availableTypes.isNotEmpty) {
          debugPrint('   ✅ Working: ${availableTypes.join(', ')}');
        }

        final missingTypes =
            importantDataTypes
                .where((type) => (newTimeSeriesData[type] ?? []).isEmpty)
                .toList();

        if (missingTypes.isNotEmpty) {
          debugPrint('   ❌ Missing: ${missingTypes.join(', ')}');
        }

        debugPrint(''); // Add spacing

        await _fetchHeartRateData(
          accessToken,
          startTime,
          endTime,
          newTimeSeriesData,
          newSummaryData,
        );
      } catch (e) {
        debugPrint('Error fetching heart rate data: $e');
      }

      try {
        await _fetchSleepData(
          accessToken,
          startTime,
          endTime,
          newTimeSeriesData,
          newSummaryData,
        );
      } catch (e) {
        debugPrint('Error fetching sleep data: $e');
      }

      try {
        await _fetchVitalSigns(
          accessToken,
          startTime,
          endTime,
          newTimeSeriesData,
          newSummaryData,
        );
      } catch (e) {
        debugPrint('Error fetching vital signs: $e');
      }

      try {
        await _fetchWellnessData(
          accessToken,
          startTime,
          endTime,
          newTimeSeriesData,
          newSummaryData,
        );
      } catch (e) {
        debugPrint('Error fetching wellness data: $e');
      }

      try {
        await _fetchEnhancedSmartwatchData(
          accessToken,
          startTime,
          endTime,
          newTimeSeriesData,
          newSummaryData,
        );
      } catch (e) {
        debugPrint('Error fetching smartwatch data: $e');
      }

      final totalDataPoints = newTimeSeriesData.values.fold(
        0,
        (sum, list) => sum + list.length,
      );

      // Predict blood pressure if not available or insufficient data
      await _addPredictedBloodPressure(newTimeSeriesData, newSummaryData);

      final message =
          'Successfully fetched $totalDataPoints data points from ${newTimeSeriesData.length} different metrics';

      return {
        'timeSeriesData': newTimeSeriesData,
        'summaryData': newSummaryData,
        'message': message,
      };
    } catch (e) {
      debugPrint('Error in fetchComprehensiveHealthData: $e');
      return {
        'timeSeriesData': <String, List<HealthDataPoint>>{},
        'summaryData': <String, HealthSummary>{},
        'message': 'Error fetching health data: $e',
      };
    }
  }

  // Map FitCloudPro data types to our standard keys
  String _mapFitCloudProDataType(String dataType) {
    debugPrint('🔄 Mapping FitCloudPro data type: $dataType');
    
    // Check standard Google Fit data types
    switch (dataType) {
      case 'com.google.heart_rate.bpm':
        return 'heart_rate';
      case 'com.google.oxygen_saturation':
        return 'oxygen_saturation';
      case 'com.google.blood_pressure':
        return 'blood_pressure';
      case 'com.google.step_count.delta':
        return 'steps';
      case 'com.google.calories.expended':
        return 'calories';
      case 'com.google.distance.delta':
        return 'distance';
      case 'com.google.active_minutes':
        return 'active_minutes';
    }
    
    // Check for FitCloudPro specific data types (with source identifier)
    if (dataType.contains('heart_rate') && dataType.contains('fitcloudpro')) {
      debugPrint('✅ Identified FitCloudPro heart rate data');
      return 'heart_rate';
    }
    if (dataType.contains('blood_pressure') && dataType.contains('fitcloudpro')) {
      debugPrint('✅ Identified FitCloudPro blood pressure data');
      return 'blood_pressure';
    }
    if (dataType.contains('step') && dataType.contains('fitcloudpro')) {
      debugPrint('✅ Identified FitCloudPro step data');
      return 'steps';
    }
    if (dataType.contains('oxygen') && dataType.contains('fitcloudpro')) {
      debugPrint('✅ Identified FitCloudPro oxygen saturation data');
      return 'oxygen_saturation';
    }
    
    debugPrint('⚠️  Unknown FitCloudPro data type: $dataType');
    return '';
  }

  Future<void> _fetchActivityData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    final activityMetrics = [
      'steps',
      'calories',
      'distance',
      'active_minutes',
      'floors_climbed',
    ];

    for (String key in activityMetrics) {
      if (HealthMetrics.metricsToTrack.containsKey(key)) {
        try {
          final dataPoints = await GoogleFitService.fetchDetailedTimeSeriesData(
            accessToken,
            HealthMetrics.metricsToTrack[key]!,
            startTime,
            endTime,
            key,
          );
          if (dataPoints.isNotEmpty) {
            timeSeriesData[key] = dataPoints;
            summaryData[key] = HealthUtils.calculateSummary(dataPoints);
          }
        } catch (e) {
          debugPrint('Error fetching $key: $e');
        }
        await Future.delayed(Duration(milliseconds: 200));
      }
    }
  }

  Future<void> _fetchHeartRateData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    try {
      debugPrint('Attempting to fetch heart rate data...');

      List<HealthDataPoint> hrData = [];

      // First try the standard aggregate method
      try {
        final metric = HealthMetrics.metricsToTrack['heart_rate']!;
        hrData = await GoogleFitService.fetchDetailedTimeSeriesData(
          accessToken,
          metric,
          startTime,
          endTime,
          'heart_rate_standard',
        );

        if (hrData.isNotEmpty) {
          debugPrint(
            'Found heart rate data via standard method: ${hrData.length} points',
          );
        }
      } catch (e) {
        debugPrint('Standard heart rate fetch failed: $e');
      }

      // If standard method failed, try direct dataset query
      if (hrData.isEmpty) {
        debugPrint('Trying direct dataset query for heart rate...');
        hrData = await _fetchHeartRateFromDataset(
          accessToken,
          startTime,
          endTime,
        );
      }

      // If still no data, try FitCloudPro specific approach
      if (hrData.isEmpty) {
        debugPrint('Trying FitCloudPro specific heart rate fetch...');
        hrData = await GoogleFitService.fetchFitCloudProHeartRate(
          accessToken,
          startTime,
          endTime,
        );
      }

      if (hrData.isNotEmpty) {
        debugPrint('Heart rate data fetched: ${hrData.length} data points');
        debugPrint(
          'Sample HR values: ${hrData.take(3).map((e) => '${e.value} bpm').toList()}',
        );
        timeSeriesData['heart_rate'] = hrData;
        summaryData['heart_rate'] = HealthUtils.calculateSummary(hrData);

        // Calculate derived metrics
        GoogleFitService.calculateHeartRateMetrics(
          hrData,
          timeSeriesData,
          summaryData,
        );
      } else {
        debugPrint('No heart rate data found from any method');
      }

      // Try to fetch HRV data separately
      final hrvData = await GoogleFitService.fetchHRVData(
        accessToken,
        startTime,
        endTime,
      );

      if (hrvData.isNotEmpty) {
        debugPrint('HRV data fetched: ${hrvData.length} data points');
        timeSeriesData['heart_rate_variability'] = hrvData;
        summaryData['heart_rate_variability'] = HealthUtils.calculateSummary(
          hrvData,
        );
      }
    } catch (e) {
      debugPrint('Error fetching heart rate data: $e');
    }
  }

  Future<List<HealthDataPoint>> _fetchHeartRateFromDataset(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      // Try to fetch from all available heart rate data sources
      final dataSources = [
        'derived:com.google.heart_rate.bpm:com.google.android.gms:merge_heart_rate_bpm',
        'raw:com.google.heart_rate.bpm:com.google.android.gms:unknown',
        'raw:com.google.heart_rate.bpm:com.topstep.fitcloudpro:',
        'raw:com.google.heart_rate.bpm:com.google.android.apps.fitness:',
      ];

      for (String dataSource in dataSources) {
        try {
          debugPrint('Trying heart rate from data source: $dataSource');
          final dataPoints = await _queryDataSource(
            accessToken,
            dataSource,
            startTime,
            endTime,
          );

          if (dataPoints.isNotEmpty) {
            debugPrint(
              'Found ${dataPoints.length} heart rate points from $dataSource',
            );
            return dataPoints;
          }
        } catch (e) {
          debugPrint('Failed to fetch from $dataSource: $e');
        }
      }

      return [];
    } catch (e) {
      debugPrint('Error in _fetchHeartRateFromDataset: $e');
      return [];
    }
  }

  Future<List<HealthDataPoint>> _queryDataSource(
    String accessToken,
    String dataSourceId,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataSources/$dataSourceId/datasets/${startTime}000000-${endTime}000000',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final points = <HealthDataPoint>[];

        if (data['point'] != null) {
          for (var point in data['point']) {
            try {
              final value = point['value']?[0];
              if (value != null) {
                double? hrValue;
                if (value['fpVal'] != null) {
                  hrValue = value['fpVal'].toDouble();
                } else if (value['intVal'] != null) {
                  hrValue = value['intVal'].toDouble();
                }

                if (hrValue != null && hrValue > 0 && hrValue < 300) {
                  final timestamp = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(point['startTimeNanos']) ~/ 1000000,
                  );
                  points.add(
                    HealthDataPoint(timestamp: timestamp, value: hrValue),
                  );
                }
              }
            } catch (e) {
              debugPrint('Error parsing heart rate point: $e');
            }
          }
        }

        return points;
      } else {
        debugPrint('Data source query failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error querying data source: $e');
      return [];
    }
  }

  Future<void> _fetchSleepData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    try {
      final sleepData = await GoogleFitService.fetchSleepData(
        accessToken,
        startTime,
        endTime,
      );

      sleepData.forEach((key, value) {
        if (value is List<HealthDataPoint> && value.isNotEmpty) {
          timeSeriesData[key] = value;
          summaryData[key] = HealthUtils.calculateSummary(value);
        }
      });
    } catch (e) {
      debugPrint('Error fetching sleep data: $e');
    }
  }

  Future<void> _fetchVitalSigns(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    final vitalMetrics = [
      'oxygen_saturation',
      'skin_temperature',
      'breathing_rate',
    ];

    for (String key in vitalMetrics) {
      if (HealthMetrics.metricsToTrack.containsKey(key)) {
        try {
          final dataPoints = await GoogleFitService.fetchDetailedTimeSeriesData(
            accessToken,
            HealthMetrics.metricsToTrack[key]!,
            startTime,
            endTime,
            key,
          );
          if (dataPoints.isNotEmpty) {
            timeSeriesData[key] = dataPoints;
            summaryData[key] = HealthUtils.calculateSummary(dataPoints);
          }
        } catch (e) {
          debugPrint('Error fetching $key: $e');
        }
        await Future.delayed(Duration(milliseconds: 200));
      }
    }

    // Fetch blood pressure data
    try {
      final bpData = await GoogleFitService.fetchBloodPressureData(
        accessToken,
        startTime,
        endTime,
      );

      bpData.forEach((key, value) {
        if (value is List<HealthDataPoint> && value.isNotEmpty) {
          timeSeriesData[key] = value;
          summaryData[key] = HealthUtils.calculateSummary(value);
        }
      });
    } catch (e) {
      debugPrint('Error fetching blood pressure data: $e');
    }
  }

  Future<void> _fetchWellnessData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    final wellnessMetrics = ['stress_score', 'recovery_score'];

    for (String key in wellnessMetrics) {
      if (HealthMetrics.metricsToTrack.containsKey(key)) {
        try {
          final dataPoints = await GoogleFitService.fetchDetailedTimeSeriesData(
            accessToken,
            HealthMetrics.metricsToTrack[key]!,
            startTime,
            endTime,
            key,
          );
          if (dataPoints.isNotEmpty) {
            timeSeriesData[key] = dataPoints;
            summaryData[key] = HealthUtils.calculateSummary(dataPoints);
          }
        } catch (e) {
          debugPrint('Error fetching $key: $e');
        }
        await Future.delayed(Duration(milliseconds: 200));
      }
    }

    // Fetch weight data
    try {
      final dataPoints = await GoogleFitService.fetchDetailedTimeSeriesData(
        accessToken,
        HealthMetrics.metricsToTrack['weight']!,
        startTime,
        endTime,
        'weight',
      );
      if (dataPoints.isNotEmpty) {
        timeSeriesData['weight'] = dataPoints;
        summaryData['weight'] = HealthUtils.calculateSummary(dataPoints);
      }
    } catch (e) {
      debugPrint('Error fetching weight data: $e');
    }
  }

  Future<void> _fetchEnhancedSmartwatchData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    // Fetch stress level data
    try {
      final stressData = await GoogleFitService.fetchStressData(
        accessToken,
        startTime,
        endTime,
      );
      if (stressData.isNotEmpty) {
        timeSeriesData['stress_level'] = stressData;
        summaryData['stress_level'] = HealthUtils.calculateSummary(stressData);
      }
    } catch (e) {
      debugPrint('Error fetching stress data: $e');
    }

    // Fetch VO2 Max data
    try {
      final vo2Data = await GoogleFitService.fetchVO2MaxData(
        accessToken,
        startTime,
        endTime,
      );
      if (vo2Data.isNotEmpty) {
        timeSeriesData['vo2_max'] = vo2Data;
        summaryData['vo2_max'] = HealthUtils.calculateSummary(vo2Data);
      }
    } catch (e) {
      debugPrint('Error fetching VO2 Max data: $e');
    }

    // Fetch workout data
    try {
      final workoutData = await GoogleFitService.fetchWorkoutData(
        accessToken,
        startTime,
        endTime,
      );

      if (workoutData['workout_sessions']?.isNotEmpty == true) {
        timeSeriesData['workout_sessions'] = workoutData['workout_sessions']!;
        summaryData['workout_sessions'] = HealthUtils.calculateSummary(
          workoutData['workout_sessions']!,
        );
      }

      if (workoutData['workout_duration']?.isNotEmpty == true) {
        timeSeriesData['workout_duration'] = workoutData['workout_duration']!;
        summaryData['workout_duration'] = HealthUtils.calculateSummary(
          workoutData['workout_duration']!,
        );
      }
    } catch (e) {
      debugPrint('Error fetching workout data: $e');
    }

    // Fetch hydration data
    try {
      final hydrationData = await GoogleFitService.fetchHydrationData(
        accessToken,
        startTime,
        endTime,
      );
      if (hydrationData.isNotEmpty) {
        timeSeriesData['hydration'] = hydrationData;
        summaryData['hydration'] = HealthUtils.calculateSummary(hydrationData);
      }
    } catch (e) {
      debugPrint('Error fetching hydration data: $e');
    }

    // Fetch respiratory rate data
    try {
      final respiratoryData = await GoogleFitService.fetchRespiratoryRateData(
        accessToken,
        startTime,
        endTime,
      );
      if (respiratoryData.isNotEmpty) {
        timeSeriesData['respiratory_rate'] = respiratoryData;
        summaryData['respiratory_rate'] = HealthUtils.calculateSummary(
          respiratoryData,
        );
      }
    } catch (e) {
      debugPrint('Error fetching respiratory rate data: $e');
    }

    // Fetch move minutes (enhanced activity tracking)
    try {
      final moveMinutesData =
          await GoogleFitService.fetchDetailedTimeSeriesData(
            accessToken,
            HealthMetrics.metricsToTrack['move_minutes']!,
            startTime,
            endTime,
            'move_minutes',
          );
      if (moveMinutesData.isNotEmpty) {
        timeSeriesData['move_minutes'] = moveMinutesData;
        summaryData['move_minutes'] = HealthUtils.calculateSummary(
          moveMinutesData,
        );
      }
    } catch (e) {
      debugPrint('Error fetching move minutes data: $e');
    }

    // Fetch hourly steps for activity pattern analysis
    try {
      final hourlyStepsData =
          await GoogleFitService.fetchDetailedTimeSeriesData(
            accessToken,
            HealthMetrics.metricsToTrack['steps']!,
            startTime,
            endTime,
            'hourly_steps',
          );
      if (hourlyStepsData.isNotEmpty) {
        timeSeriesData['hourly_steps'] = hourlyStepsData;
        summaryData['hourly_steps'] = HealthUtils.calculateSummary(
          hourlyStepsData,
        );
      }
    } catch (e) {
      debugPrint('Error fetching hourly steps data: $e');
    }
  }

  /// Fetch health data from Health Connect (universal smartwatch support)
  /// This includes Oraimo, Samsung, Fitbit, Garmin, Apple Watch, and 50+ other brands
  Future<Map<String, dynamic>> fetchHealthConnectData({
    int selectedDays = 7,
  }) async {
    try {
      // Initialize Health Connect if not already done
      bool isInitialized = await _healthConnectService.initialize();
      if (!isInitialized) {
        debugPrint('Health Connect not available on this device');
        return {};
      }

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: selectedDays));

      // Fetch health data from Health Connect
      final healthData = await _healthConnectService.getHealthData(
        startDate: startDate,
        endDate: now,
      );

      debugPrint('Health Connect data retrieved: ${healthData['data_source']}');
      debugPrint(
        'Steps: ${healthData['steps']}, Heart Rate: ${healthData['heart_rate_avg']}, BP: ${healthData['blood_pressure_systolic_avg']}/${healthData['blood_pressure_diastolic_avg']}',
      );

      return healthData;
    } catch (e) {
      debugPrint('Error fetching Health Connect data: $e');
      return {};
    }
  }

  /// Check if Health Connect is available and supported
  Future<bool> isHealthConnectAvailable() async {
    try {
      return await _healthConnectService.isAvailable();
    } catch (e) {
      debugPrint('Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// Get comprehensive health data from all sources (Google Fit + Health Connect)
  /// Returns full time series data format instead of summary statistics
  /// Health Connect provides universal smartwatch support including blood pressure
  Future<Map<String, dynamic>> fetchUniversalHealthData(
    GoogleSignInAccount? user,
    int selectedDays,
  ) async {
    debugPrint('🚀 fetchUniversalHealthData: Starting data collection...');

    // Always prioritize full Google Fit data if user is signed in
    // to preserve the 400+ time series data points
    if (user != null) {
      try {
        debugPrint('📊 Attempting Google Fit data (preserves time series)...');
        final googleFitData = await fetchComprehensiveHealthData(
          user,
          selectedDays,
        );

        // Check if we have substantial time series data
        final timeSeriesData =
            googleFitData['timeSeriesData']
                as Map<String, List<HealthDataPoint>>?;
        final totalPoints =
            timeSeriesData?.values.fold(0, (sum, list) => sum + list.length) ??
            0;

        debugPrint('📈 Google Fit time series points: $totalPoints');

        if (totalPoints > 10) {
          // If we have good time series data, use it
          debugPrint('✅ Using Google Fit data ($totalPoints data points)');

          // Try to supplement with Health Connect blood pressure if available
          try {
            final healthConnectData = await fetchHealthConnectData(
              selectedDays: selectedDays,
            );
            if (healthConnectData.isNotEmpty) {
              final hasBP =
                  (healthConnectData['blood_pressure_systolic_avg'] as num? ??
                          0) >
                      0 ||
                  (healthConnectData['blood_pressure_diastolic_avg'] as num? ??
                          0) >
                      0;

              if (hasBP) {
                debugPrint('🩺 Adding Health Connect blood pressure data');
                googleFitData['health_connect_bp'] = healthConnectData;
              }
            }
          } catch (e) {
            debugPrint('Health Connect BP supplement failed: $e');
          }

          return googleFitData;
        }
      } catch (e) {
        debugPrint('Google Fit data error: $e');
      }
    }

    // Fallback to Health Connect summary data only if Google Fit fails
    debugPrint('📱 Falling back to Health Connect summary data...');
    Map<String, dynamic> combinedData = {};

    try {
      final healthConnectData = await fetchHealthConnectData(
        selectedDays: selectedDays,
      );

      if (healthConnectData.isNotEmpty) {
        combinedData['health_connect'] = healthConnectData;
        debugPrint(
          '✅ Health Connect data available - Universal smartwatch support active',
        );
      }
    } catch (e) {
      debugPrint('Health Connect not available: $e');
    }

    // Create unified data structure (summary format)
    return _unifyHealthData(combinedData);
  }

  /// Unify data from multiple sources, prioritizing Health Connect for blood pressure
  Map<String, dynamic> _unifyHealthData(Map<String, dynamic> sources) {
    Map<String, dynamic> unified = {
      'steps': 0,
      'heart_rate_avg': 0,
      'blood_pressure_systolic': 0,
      'blood_pressure_diastolic': 0,
      'oxygen_saturation_avg': 0,
      'calories': 0,
      'distance': 0.0,
      'sleep_hours': 0.0,
      'data_sources': <String>[],
      'blood_pressure_available': false,
      'last_updated': DateTime.now().toIso8601String(),
    };

    debugPrint('🔄 Unifying data from sources: ${sources.keys.toList()}');

    // Prioritize Health Connect data (universal smartwatch support)
    if (sources.containsKey('health_connect')) {
      final hcData = sources['health_connect'] as Map<String, dynamic>;
      debugPrint('📱 Health Connect steps data: ${hcData['steps']}');

      unified['steps'] = hcData['steps'] ?? 0;
      unified['heart_rate_avg'] = hcData['heart_rate_avg'] ?? 0;
      unified['blood_pressure_systolic'] =
          hcData['blood_pressure_systolic_avg'] ?? 0;
      unified['blood_pressure_diastolic'] =
          hcData['blood_pressure_diastolic_avg'] ?? 0;
      unified['oxygen_saturation_avg'] = hcData['oxygen_saturation_avg'] ?? 0;
      unified['calories'] = hcData['calories'] ?? 0;
      unified['distance'] = hcData['distance'] ?? 0.0;
      unified['sleep_hours'] = hcData['sleep_hours'] ?? 0.0;

      (unified['data_sources'] as List<String>).add(
        'Health Connect (Universal)',
      );

      // Check if blood pressure data is available
      if ((unified['blood_pressure_systolic'] as num) > 0 ||
          (unified['blood_pressure_diastolic'] as num) > 0) {
        unified['blood_pressure_available'] = true;
      }
    }

    // Supplement with Google Fit data if Health Connect values are missing
    if (sources.containsKey('google_fit')) {
      final gfData = sources['google_fit'] as Map<String, dynamic>;

      // Only use Google Fit data if Health Connect didn't provide it
      if (unified['steps'] == 0 && gfData.containsKey('summaryData')) {
        final summaryData = gfData['summaryData'] as Map<String, dynamic>;
        debugPrint('🔄 Health Connect steps = 0, checking Google Fit fallback');
        if (summaryData.containsKey('steps')) {
          final stepsData = summaryData['steps'] as HealthSummary?;
          final stepsValue = stepsData?.latest;
          debugPrint('📊 Google Fit steps available: $stepsValue');
          if (stepsValue != null) {
            unified['steps'] = stepsValue.toInt();
            debugPrint('✅ Using Google Fit steps: ${unified['steps']}');
          }
        }
        if (summaryData.containsKey('heart_rate')) {
          final heartRateData = summaryData['heart_rate'] as HealthSummary?;
          final heartRateValue = heartRateData?.average;
          if (heartRateValue != null) {
            unified['heart_rate_avg'] = heartRateValue.toInt();
          }
        }
        if (summaryData.containsKey('calories')) {
          final caloriesData = summaryData['calories'] as HealthSummary?;
          final caloriesValue = caloriesData?.latest;
          if (caloriesValue != null) {
            unified['calories'] = caloriesValue.toInt();
          }
        }
      }

      (unified['data_sources'] as List<String>).add('Google Fit');
    }

    return unified;
  }

  /// Predict and add blood pressure data if not available or insufficient
  Future<void> _addPredictedBloodPressure(
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    try {
      // Check if we have actual BP data
      final systolicData = timeSeriesData['blood_pressure_systolic'] ?? [];
      final diastolicData = timeSeriesData['blood_pressure_diastolic'] ?? [];

      // Only predict if we have no BP data or very limited data
      if (systolicData.length < 3 && diastolicData.length < 3) {
        debugPrint('🩺 Insufficient BP data detected. Running prediction...');

        // Load user profile for age and BMI
        final profile = await UserProfileService.loadProfile();

        // Get historical BP if available
        Map<String, double>? historicalBP;
        if (systolicData.isNotEmpty && diastolicData.isNotEmpty) {
          final avgSystolic =
              systolicData.fold<double>(
                0.0,
                (sum, point) => sum + point.value,
              ) /
              systolicData.length;
          final avgDiastolic =
              diastolicData.fold<double>(
                0.0,
                (sum, point) => sum + point.value,
              ) /
              diastolicData.length;

          historicalBP = {'systolic': avgSystolic, 'diastolic': avgDiastolic};
        }

        // Run BP prediction
        final prediction =
            await BloodPressurePredictionService.predictBloodPressure(
              timeSeriesData: timeSeriesData,
              age: profile?.age,
              bmi: profile?.bmi,
              isSmoker: false, // Not available in profile
              hasHighCholesterol: false, // Not available in profile
              historicalBP: historicalBP,
            );

        final systolic = prediction['systolic'] as int;
        final diastolic = prediction['diastolic'] as int;
        final confidence = prediction['confidence'] as double;
        final timestamp = prediction['timestamp'] as DateTime;

        debugPrint(
          '✅ BP Prediction: $systolic/$diastolic mmHg (${(confidence * 100).toStringAsFixed(0)}% confidence)',
        );

        // Generate BP data points for visualization
        final systolicPoints =
            BloodPressurePredictionService.generateBPDataPoints(
              systolic: systolic,
              diastolic: diastolic,
              timestamp: timestamp,
              numberOfDays: 7,
              useSystolic: true,
            );

        final diastolicPoints =
            BloodPressurePredictionService.generateBPDataPoints(
              systolic: systolic,
              diastolic: diastolic,
              timestamp: timestamp,
              numberOfDays: 7,
              useSystolic: false,
            );

        // Add to time series data (merge with existing if any)
        timeSeriesData['blood_pressure_systolic'] = [
          ...systolicData,
          ...systolicPoints,
        ];

        timeSeriesData['blood_pressure_diastolic'] = [
          ...diastolicData,
          ...diastolicPoints,
        ];

        // Create summary data
        final bpSummary = BloodPressurePredictionService.createBPSummary(
          systolic: systolic,
          diastolic: diastolic,
          confidence: confidence,
        );

        summaryData['blood_pressure_systolic'] = HealthSummary(
          latest: systolic.toDouble(),
          average: systolic.toDouble(),
          min: (systolic - 5).toDouble(),
          max: (systolic + 5).toDouble(),
          trend: 0.0,
        );

        summaryData['blood_pressure_diastolic'] = HealthSummary(
          latest: diastolic.toDouble(),
          average: diastolic.toDouble(),
          min: (diastolic - 3).toDouble(),
          max: (diastolic + 3).toDouble(),
          trend: 0.0,
        );

        // Store prediction metadata
        summaryData['bp_prediction_metadata'] = HealthSummary(
          latest: confidence,
          average: confidence,
          min: confidence,
          max: confidence,
          trend: 0.0,
        );

        debugPrint('📊 Added predicted BP data points to time series');
        debugPrint('   Category: ${bpSummary['category']}');
        debugPrint('   Recommendation: ${bpSummary['recommendation']}');
      } else {
        debugPrint(
          '✅ Sufficient BP data available (${systolicData.length} points). No prediction needed.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding predicted blood pressure: $e');
      // Don't throw - just log the error and continue
    }
  }
}
