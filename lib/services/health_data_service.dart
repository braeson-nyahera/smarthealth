import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/health_models.dart';
import '../constants/health_metrics.dart';
import '../utils/health_utils.dart';
import '../config/google_config.dart';
import 'google_fit_service.dart';

class HealthDataService {
  late GoogleSignIn _googleSignIn;

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
  String _mapFitCloudProDataType(String fitCloudProDataType) {
    switch (fitCloudProDataType) {
      case 'com.google.heart_rate.bpm':
        return 'heart_rate';
      case 'com.google.step_count.delta':
        return 'steps';
      case 'com.google.oxygen_saturation':
        return 'oxygen_saturation';
      case 'com.google.sleep.segment':
        return 'sleep_hours';
      case 'com.google.calories.expended':
        return 'calories';
      case 'com.google.distance.delta':
        return 'distance';
      case 'com.google.active_minutes':
        return 'active_minutes';
      default:
        debugPrint('Unmapped FitCloudPro data type: $fitCloudProDataType');
        return '';
    }
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
}
