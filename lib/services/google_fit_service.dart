import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/health_models.dart';
import '../utils/health_utils.dart';
import '../constants/health_metrics.dart';

class GoogleFitService {
  static Future<List<HealthDataPoint>> fetchDetailedTimeSeriesData(
    String accessToken,
    HealthMetric metric,
    int startTime,
    int endTime,
    String debugName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": metric.dataType},
          ],
          "bucketByTime": {"durationMillis": 3600000}, // Hourly buckets
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (debugName == 'heart_rate') {
          debugPrint(
            'Heart rate API response: ${data.toString().substring(0, 500)}...',
          );
        }
        return _parseTimeSeriesData(data, metric);
      } else if (response.statusCode == 400) {
        // Handle missing data sources gracefully
        final errorData = jsonDecode(response.body);
        if (errorData['error']?['message']?.contains(
              'no default datasource found',
            ) ==
            true) {
          // This is expected for some metrics that aren't available on all devices
          // Silently ignore missing data sources
        } else {
          debugPrint(
            'Error response for $debugName: ${response.statusCode} - ${response.body}',
          );
        }
        return [];
      } else {
        debugPrint(
          'Error response for $debugName: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching $debugName data: $e');
      return [];
    }
  }

  static List<HealthDataPoint> _parseTimeSeriesData(
    Map<String, dynamic> data,
    HealthMetric metric,
  ) {
    List<HealthDataPoint> points = [];

    if (data['bucket'] != null) {
      for (var bucket in data['bucket']) {
        if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
          for (var dataset in bucket['dataset']) {
            if (dataset['point'] != null && dataset['point'].isNotEmpty) {
              for (var point in dataset['point']) {
                final healthPoint = _parseDataPoint(point, metric);
                if (healthPoint != null) {
                  points.add(healthPoint);
                }
              }
            }
          }
        }
      }
    }

    return points;
  }

  static HealthDataPoint? _parseDataPoint(
    Map<String, dynamic> point,
    HealthMetric metric,
  ) {
    try {
      if (point['value'] == null || point['value'].isEmpty) return null;

      final value = point['value'][0];
      double? parsedValue;

      // Parse based on value type
      if (value['intVal'] != null) {
        parsedValue = value['intVal'].toDouble();
      } else if (value['fpVal'] != null) {
        parsedValue = value['fpVal'].toDouble();
      } else if (value['stringVal'] != null) {
        parsedValue = double.tryParse(value['stringVal']);
      }

      if (parsedValue == null) return null;

      // Convert units if needed
      if (metric.unit == 'km' && parsedValue > 1000) {
        // Convert meters to kilometers
        parsedValue = parsedValue / 1000;
      }

      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.parse(point['startTimeNanos']) ~/ 1000000,
      );

      return HealthDataPoint(timestamp: timestamp, value: parsedValue);
    } catch (e) {
      debugPrint('Error parsing data point: $e');
      return null;
    }
  }

  static Future<List<HealthDataPoint>> fetchHRVData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.heart_rate.variability"},
          ],
          "bucketByTime": {"durationMillis": 86400000}, // Daily
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<HealthDataPoint> hrvPoints = [];

        if (data['bucket'] != null) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null && dataset['point'].isNotEmpty) {
                  for (var point in dataset['point']) {
                    final hrvPoint = _parseHRVPoint(point);
                    if (hrvPoint != null) {
                      hrvPoints.add(hrvPoint);
                    }
                  }
                }
              }
            }
          }
        }

        return hrvPoints;
      }
    } catch (e) {
      debugPrint('Error fetching HRV data: $e');
    }
    return [];
  }

  static HealthDataPoint? _parseHRVPoint(Map<String, dynamic> point) {
    try {
      if (point['value'] == null || point['value'].isEmpty) return null;

      final value = point['value'][0];
      double? rmssd;

      // HRV data structure can vary, look for RMSSD value
      if (value['mapVal'] != null) {
        for (var mapEntry in value['mapVal']) {
          if (mapEntry['key'] == 'rmssd' &&
              mapEntry['value']['fpVal'] != null) {
            rmssd = mapEntry['value']['fpVal'].toDouble();
            break;
          }
        }
      } else if (value['fpVal'] != null) {
        rmssd = value['fpVal'].toDouble();
      }

      if (rmssd == null) return null;

      final startTime = int.parse(point['startTimeNanos']) ~/ 1000000;
      return HealthDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(startTime),
        value: rmssd,
      );
    } catch (e) {
      debugPrint('Error parsing HRV point: $e');
      return null;
    }
  }

  static void calculateHeartRateMetrics(
    List<HealthDataPoint> hrData,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) {
    if (hrData.isEmpty) return;

    // Create synthetic data points for these metrics
    List<HealthDataPoint> restingHRPoints = [];
    List<HealthDataPoint> maxHRPoints = [];

    // Group by day and calculate daily resting and max HR
    Map<String, List<HealthDataPoint>> dailyHR = {};
    for (var point in hrData) {
      String dayKey =
          '${point.timestamp.year}-${point.timestamp.month}-${point.timestamp.day}';
      dailyHR.putIfAbsent(dayKey, () => []).add(point);
    }

    dailyHR.forEach((day, points) {
      if (points.isNotEmpty) {
        points.sort((a, b) => a.value.compareTo(b.value));

        // Daily resting HR (lowest 20% of the day)
        int dailyRestingCount = (points.length * 0.2).ceil();
        double dailyRestingHR =
            points
                .take(dailyRestingCount)
                .map((e) => e.value)
                .reduce((a, b) => a + b) /
            dailyRestingCount;

        // Daily max HR
        double dailyMaxHR = points.last.value;

        // Parse the day string more safely
        final dayParts = day.split('-');
        final year = int.parse(dayParts[0]);
        final month = int.parse(dayParts[1]);
        final dayOfMonth = int.parse(dayParts[2]);
        DateTime dayStart = DateTime(year, month, dayOfMonth);

        restingHRPoints.add(
          HealthDataPoint(timestamp: dayStart, value: dailyRestingHR),
        );

        maxHRPoints.add(
          HealthDataPoint(timestamp: dayStart, value: dailyMaxHR),
        );
      }
    });

    if (restingHRPoints.isNotEmpty) {
      timeSeriesData['resting_heart_rate'] = restingHRPoints;
      summaryData['resting_heart_rate'] = HealthUtils.calculateSummary(
        restingHRPoints,
      );
    }

    if (maxHRPoints.isNotEmpty) {
      timeSeriesData['max_heart_rate'] = maxHRPoints;
      summaryData['max_heart_rate'] = HealthUtils.calculateSummary(maxHRPoints);
    }
  }

  static Future<Map<String, dynamic>> fetchSleepData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.sleep.segment"},
          ],
          "bucketByTime": {"durationMillis": 86400000}, // Daily
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processSleepData(data);
      }
    } catch (e) {
      debugPrint('Error fetching sleep data: $e');
    }
    return {};
  }

  static Map<String, dynamic> _processSleepData(Map<String, dynamic> data) {
    List<HealthDataPoint> sleepDurationPoints = [];
    List<HealthDataPoint> deepSleepPoints = [];
    List<HealthDataPoint> remSleepPoints = [];
    List<HealthDataPoint> sleepEfficiencyPoints = [];

    if (data['bucket'] != null) {
      for (var bucket in data['bucket']) {
        DateTime bucketStart = DateTime.fromMillisecondsSinceEpoch(
          int.parse(bucket['startTimeMillis']),
        );

        double totalSleepMinutes = 0;
        double deepSleepMinutes = 0;
        double remSleepMinutes = 0;

        if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
          for (var dataset in bucket['dataset']) {
            if (dataset['point'] != null) {
              for (var point in dataset['point']) {
                final sleepSegment = _parseSleepSegment(point);
                if (sleepSegment != null) {
                  totalSleepMinutes += sleepSegment['duration']!;

                  switch (sleepSegment['type']) {
                    case 4: // Deep sleep
                      deepSleepMinutes += sleepSegment['duration']!;
                      break;
                    case 5: // REM sleep
                      remSleepMinutes += sleepSegment['duration']!;
                      break;
                    case 3: // Light sleep
                      // Light sleep is tracked but not used in calculations
                      break;
                  }
                }
              }
            }
          }
        }

        if (totalSleepMinutes > 0) {
          // Sleep duration in hours
          sleepDurationPoints.add(
            HealthDataPoint(
              timestamp: bucketStart,
              value: totalSleepMinutes / 60,
            ),
          );

          // Deep sleep percentage
          deepSleepPoints.add(
            HealthDataPoint(
              timestamp: bucketStart,
              value: (deepSleepMinutes / totalSleepMinutes) * 100,
            ),
          );

          // REM sleep percentage
          remSleepPoints.add(
            HealthDataPoint(
              timestamp: bucketStart,
              value: (remSleepMinutes / totalSleepMinutes) * 100,
            ),
          );

          // Sleep efficiency (assuming 8 hours in bed)
          double timeInBed = 8 * 60; // 8 hours in minutes
          double efficiency = (totalSleepMinutes / timeInBed) * 100;
          sleepEfficiencyPoints.add(
            HealthDataPoint(
              timestamp: bucketStart,
              value: efficiency.clamp(0, 100),
            ),
          );
        }
      }
    }

    return {
      'sleep_duration': sleepDurationPoints,
      'deep_sleep': deepSleepPoints,
      'rem_sleep': remSleepPoints,
      'sleep_efficiency': sleepEfficiencyPoints,
    };
  }

  static Map<String, double>? _parseSleepSegment(Map<String, dynamic> point) {
    try {
      if (point['value'] == null || point['value'].isEmpty) return null;

      final value = point['value'][0];
      final startTime = int.parse(point['startTimeNanos']) ~/ 1000000;
      final endTime = int.parse(point['endTimeNanos']) ~/ 1000000;
      final duration =
          (endTime - startTime) / (1000 * 60); // Duration in minutes

      int sleepType = 1; // Default to light sleep
      if (value['intVal'] != null) {
        sleepType = value['intVal'];
      }

      return {'duration': duration, 'type': sleepType.toDouble()};
    } catch (e) {
      debugPrint('Error parsing sleep segment: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchBloodPressureData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.blood_pressure"},
          ],
          "bucketByTime": {"durationMillis": 86400000},
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processBloodPressureData(data);
      }
    } catch (e) {
      debugPrint('Error fetching blood pressure data: $e');
    }
    return {};
  }

  static Map<String, dynamic> _processBloodPressureData(
    Map<String, dynamic> data,
  ) {
    List<HealthDataPoint> systolicPoints = [];
    List<HealthDataPoint> diastolicPoints = [];

    if (data['bucket'] != null) {
      for (var bucket in data['bucket']) {
        if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
          for (var dataset in bucket['dataset']) {
            if (dataset['point'] != null) {
              for (var point in dataset['point']) {
                final bpData = _parseBloodPressurePoint(point);
                if (bpData != null) {
                  systolicPoints.add(
                    HealthDataPoint(
                      timestamp: bpData['timestamp']!,
                      value: bpData['systolic']!,
                    ),
                  );
                  diastolicPoints.add(
                    HealthDataPoint(
                      timestamp: bpData['timestamp']!,
                      value: bpData['diastolic']!,
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    return {'systolic_bp': systolicPoints, 'diastolic_bp': diastolicPoints};
  }

  static Map<String, dynamic>? _parseBloodPressurePoint(
    Map<String, dynamic> point,
  ) {
    try {
      if (point['value'] == null || point['value'].isEmpty) return null;

      final value = point['value'][0];
      double? systolic, diastolic;

      if (value['mapVal'] != null) {
        for (var mapEntry in value['mapVal']) {
          if (mapEntry['key'] == 'systolic' &&
              mapEntry['value']['fpVal'] != null) {
            systolic = mapEntry['value']['fpVal'].toDouble();
          } else if (mapEntry['key'] == 'diastolic' &&
              mapEntry['value']['fpVal'] != null) {
            diastolic = mapEntry['value']['fpVal'].toDouble();
          }
        }
      }

      if (systolic == null || diastolic == null) return null;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.parse(point['startTimeNanos']) ~/ 1000000,
      );

      return {
        'timestamp': timestamp,
        'systolic': systolic,
        'diastolic': diastolic,
      };
    } catch (e) {
      debugPrint('Error parsing blood pressure point: $e');
      return null;
    }
  }

  // Enhanced Smartwatch Data Methods
  static Future<List<HealthDataPoint>> fetchStressData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.fitness.heart.variability"},
          ],
          "bucketByTime": {"durationMillis": 3600000}, // Hourly
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<HealthDataPoint> stressPoints = [];

        if (data['bucket'] != null) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null && dataset['point'].isNotEmpty) {
                  for (var point in dataset['point']) {
                    final stressPoint = _parseStressPoint(point);
                    if (stressPoint != null) {
                      stressPoints.add(stressPoint);
                    }
                  }
                }
              }
            }
          }
        }

        return stressPoints;
      }
    } catch (e) {
      debugPrint('Error fetching stress data: $e');
    }
    return [];
  }

  static HealthDataPoint? _parseStressPoint(Map<String, dynamic> point) {
    try {
      if (point['value'] == null || point['value'].isEmpty) return null;

      final value = point['value'][0];
      double? stressLevel;

      // Calculate stress from HRV data (simplified calculation)
      if (value['fpVal'] != null) {
        double hrv = value['fpVal'].toDouble();
        // Higher HRV typically means lower stress (inverse relationship)
        stressLevel = 100 - (hrv / 50 * 100).clamp(0, 100);
      }

      if (stressLevel == null) return null;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.parse(point['startTimeNanos']) ~/ 1000000,
      );

      return HealthDataPoint(timestamp: timestamp, value: stressLevel);
    } catch (e) {
      debugPrint('Error parsing stress point: $e');
      return null;
    }
  }

  static Future<List<HealthDataPoint>> fetchVO2MaxData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.fitness.aerobic.capacity"},
          ],
          "bucketByTime": {"durationMillis": 86400000}, // Daily
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<HealthDataPoint> vo2Points = [];

        if (data['bucket'] != null) {
          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null && dataset['point'].isNotEmpty) {
                  for (var point in dataset['point']) {
                    final vo2Point = _parseVO2Point(point);
                    if (vo2Point != null) {
                      vo2Points.add(vo2Point);
                    }
                  }
                }
              }
            }
          }
        }

        return vo2Points;
      }
    } catch (e) {
      debugPrint('Error fetching VO2 Max data: $e');
    }
    return [];
  }

  static HealthDataPoint? _parseVO2Point(Map<String, dynamic> point) {
    try {
      if (point['value'] == null || point['value'].isEmpty) return null;

      final value = point['value'][0];
      double? vo2Max;

      if (value['fpVal'] != null) {
        vo2Max = value['fpVal'].toDouble();
      }

      if (vo2Max == null) return null;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.parse(point['startTimeNanos']) ~/ 1000000,
      );

      return HealthDataPoint(timestamp: timestamp, value: vo2Max);
    } catch (e) {
      debugPrint('Error parsing VO2 point: $e');
      return null;
    }
  }

  static Future<Map<String, List<HealthDataPoint>>> fetchWorkoutData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.activity.segment"},
          ],
          "bucketByTime": {"durationMillis": 86400000}, // Daily
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<HealthDataPoint> sessionPoints = [];
        List<HealthDataPoint> durationPoints = [];

        if (data['bucket'] != null) {
          Map<String, int> dailySessions = {};
          Map<String, double> dailyDuration = {};

          for (var bucket in data['bucket']) {
            if (bucket['dataset'] != null && bucket['dataset'].isNotEmpty) {
              for (var dataset in bucket['dataset']) {
                if (dataset['point'] != null && dataset['point'].isNotEmpty) {
                  for (var point in dataset['point']) {
                    final workoutData = _parseWorkoutPoint(point);
                    if (workoutData != null) {
                      final dayKey =
                          '${workoutData['date'].year}-${workoutData['date'].month}-${workoutData['date'].day}';
                      dailySessions[dayKey] = (dailySessions[dayKey] ?? 0) + 1;
                      dailyDuration[dayKey] =
                          (dailyDuration[dayKey] ?? 0) +
                          workoutData['duration'];
                    }
                  }
                }
              }
            }
          }

          // Convert to daily aggregates
          dailySessions.forEach((day, sessions) {
            // Parse the day string more safely
            final dayParts = day.split('-');
            final year = int.parse(dayParts[0]);
            final month = int.parse(dayParts[1]);
            final dayOfMonth = int.parse(dayParts[2]);
            DateTime date = DateTime(year, month, dayOfMonth);
            sessionPoints.add(
              HealthDataPoint(timestamp: date, value: sessions.toDouble()),
            );
          });

          dailyDuration.forEach((day, duration) {
            // Parse the day string more safely
            final dayParts = day.split('-');
            final year = int.parse(dayParts[0]);
            final month = int.parse(dayParts[1]);
            final dayOfMonth = int.parse(dayParts[2]);
            DateTime date = DateTime(year, month, dayOfMonth);
            durationPoints.add(
              HealthDataPoint(timestamp: date, value: duration),
            );
          });
        }

        return {
          'workout_sessions': sessionPoints,
          'workout_duration': durationPoints,
        };
      }
    } catch (e) {
      debugPrint('Error fetching workout data: $e');
    }
    return {};
  }

  static Map<String, dynamic>? _parseWorkoutPoint(Map<String, dynamic> point) {
    try {
      if (point['value'] == null || point['value'].isEmpty) return null;

      final value = point['value'][0];
      int? activityType;
      double duration = 0;

      if (value['intVal'] != null) {
        activityType = value['intVal'];
      }

      // Calculate duration from start and end times
      final startTime = int.parse(point['startTimeNanos']) ~/ 1000000;
      final endTime = int.parse(point['endTimeNanos']) ~/ 1000000;
      duration = (endTime - startTime) / 60000.0; // Convert to minutes

      final date = DateTime.fromMillisecondsSinceEpoch(startTime);

      return {'date': date, 'activityType': activityType, 'duration': duration};
    } catch (e) {
      debugPrint('Error parsing workout point: $e');
      return null;
    }
  }

  static Future<List<HealthDataPoint>> fetchHydrationData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.hydration"},
          ],
          "bucketByTime": {"durationMillis": 86400000}, // Daily
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseTimeSeriesData(
          data,
          HealthMetrics.metricsToTrack['hydration']!,
        );
      }
    } catch (e) {
      debugPrint('Error fetching hydration data: $e');
    }
    return [];
  }

  // Method to list available data sources for debugging
  static Future<void> listAvailableDataSources(String accessToken) async {
    try {
      debugPrint('Checking available data sources...');
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/fitness/v1/users/me/dataSources'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataSources = data['dataSource'] ?? [];
        debugPrint('Available data sources: ${dataSources.length}');

        // Group and analyze FitCloudPro sources specifically
        final fitCloudProSources = <Map<String, dynamic>>[];

        for (var source in dataSources) {
          final dataType = source['dataType']['name'];
          final appPackageName =
              source['application']?['packageName'] ?? 'Unknown';
          final streamId = source['dataStreamId'] ?? 'Unknown';
          final streamName = source['dataStreamName'] ?? 'Unknown';

          debugPrint('Data source: $dataType from $appPackageName');

          if (appPackageName.contains('fitcloudpro') ||
              appPackageName.contains('topstep')) {
            fitCloudProSources.add({
              'dataType': dataType,
              'streamId': streamId,
              'streamName': streamName,
              'source': source,
            });
          }
        }

        // Detailed analysis of FitCloudPro sources
        if (fitCloudProSources.isNotEmpty) {
          debugPrint('\n=== FITCLOUDPRO DATA SOURCES ANALYSIS ===');
          debugPrint(
            'Found ${fitCloudProSources.length} FitCloudPro data sources:',
          );

          for (var fitSource in fitCloudProSources) {
            debugPrint('  • ${fitSource['dataType']}');
            debugPrint('    Stream ID: ${fitSource['streamId']}');
            debugPrint('    Stream Name: ${fitSource['streamName']}');

            // Try to fetch recent data from this source
            await _fetchDataFromSpecificSource(
              accessToken,
              fitSource['source'],
              fitSource['dataType'],
            );
          }

          // Check for potentially available data types
          debugPrint('\n📋 AVAILABLE DATA TYPES CHECK:');
          final expectedDataTypes = [
            'com.google.sleep.segment',
            'com.google.calories.expended',
          ];
          final foundDataTypes =
              fitCloudProSources.map((s) => s['dataType']).toList();

          for (var expectedType in expectedDataTypes) {
            if (!foundDataTypes.contains(expectedType)) {
              debugPrint('  ❌ Missing: $expectedType');
            } else {
              debugPrint('  ✅ Found: $expectedType');
            }
          }

          // Check for these data types in ALL data sources
          debugPrint('\n🔍 CHECKING ALL DATA SOURCES:');
          for (var expectedType in expectedDataTypes) {
            for (var source in dataSources) {
              final dataType = source['dataType']['name'];
              final appPackageName =
                  source['application']?['packageName'] ?? 'Unknown';

              if (dataType == expectedType) {
                debugPrint('  ✨ Found $expectedType from $appPackageName');
              }
            }
          }

          debugPrint('=== END FITCLOUDPRO ANALYSIS ===\n');
        } else {
          debugPrint('No FitCloudPro data sources found');
        }
      } else {
        debugPrint('Error listing data sources: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error listing available data sources: $e');
    }
  }

  // Method to fetch data from a specific data source
  static Future<void> _fetchDataFromSpecificSource(
    String accessToken,
    Map<String, dynamic> dataSource,
    String dataType,
  ) async {
    try {
      final streamId = dataSource['dataStreamId'];
      final now = DateTime.now();

      // Try multiple time ranges to find data
      final timeRanges = [
        {'days': 1, 'label': 'last 24h'},
        {'days': 3, 'label': 'last 3 days'},
        {'days': 7, 'label': 'last 7 days'},
        {'days': 30, 'label': 'last 30 days'},
      ];

      debugPrint('    Checking data availability for $dataType...');

      for (var timeRange in timeRanges) {
        final startTime = now.subtract(
          Duration(days: timeRange['days'] as int),
        );

        final response = await http.get(
          Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataSources/$streamId/datasets/${startTime.millisecondsSinceEpoch * 1000000}-${now.millisecondsSinceEpoch * 1000000}',
          ),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final points = data['point'] ?? [];

          if (points.isNotEmpty) {
            debugPrint(
              '    ✅ Found ${points.length} data points in ${timeRange['label']}',
            );

            // Show sample data points
            final samplePoints = points.take(3).toList();
            for (var point in samplePoints) {
              final value = point['value']?[0];
              final timestamp = point['startTimeNanos'];
              if (value != null && timestamp != null) {
                final time = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(timestamp) ~/ 1000000,
                );
                final val =
                    value['fpVal'] ?? value['intVal'] ?? value['stringVal'];
                debugPrint(
                  '      Sample: $val at ${time.toString().substring(0, 19)}',
                );
              }
            }
            return; // Found data, stop checking other ranges
          }
        } else if (response.statusCode == 400) {
          debugPrint(
            '    ⚠️  No data available for ${timeRange['label']} (400)',
          );
        } else {
          debugPrint(
            '    ❌ Error ${response.statusCode} for ${timeRange['label']}: ${response.body}',
          );
        }
      }

      // If no data found in any time range
      debugPrint('    ❌ No data found in any time range (24h, 3d, 7d, 30d)');

      // Try to get the earliest and latest data points available
      await _checkDataSourceBounds(accessToken, streamId, dataType);
    } catch (e) {
      debugPrint('    ❌ Error fetching from $dataType: $e');
    }
  }

  // Method to check when data source has any data at all
  static Future<void> _checkDataSourceBounds(
    String accessToken,
    String streamId,
    String dataType,
  ) async {
    try {
      debugPrint('    🔍 Checking data source bounds for $dataType...');

      // Try a very wide range (last year) to see if any data exists
      final now = DateTime.now();
      final yearAgo = now.subtract(Duration(days: 365));

      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataSources/$streamId/datasets/${yearAgo.millisecondsSinceEpoch * 1000000}-${now.millisecondsSinceEpoch * 1000000}',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final points = data['point'] ?? [];

        if (points.isNotEmpty) {
          debugPrint(
            '    📊 Found ${points.length} total data points in last year',
          );

          // Find earliest and latest timestamps
          int? earliestTime;
          int? latestTime;

          for (var point in points) {
            final timestamp = int.tryParse(point['startTimeNanos'] ?? '0');
            if (timestamp != null) {
              final timeMs = timestamp ~/ 1000000;
              if (earliestTime == null || timeMs < earliestTime) {
                earliestTime = timeMs;
              }
              if (latestTime == null || timeMs > latestTime) {
                latestTime = timeMs;
              }
            }
          }

          if (earliestTime != null && latestTime != null) {
            final earliest = DateTime.fromMillisecondsSinceEpoch(earliestTime);
            final latest = DateTime.fromMillisecondsSinceEpoch(latestTime);
            debugPrint(
              '    📅 Data range: ${earliest.toString().substring(0, 19)} to ${latest.toString().substring(0, 19)}',
            );

            // Check how recent the latest data is
            final daysSinceLatest = now.difference(latest).inDays;
            if (daysSinceLatest > 1) {
              debugPrint(
                '    ⚠️  Latest data is $daysSinceLatest days old - sync issue?',
              );
            }
          }
        } else {
          debugPrint(
            '    ❌ No data found even in last year - source may be inactive',
          );
        }
      } else {
        debugPrint('    ❌ Error checking bounds: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('    ❌ Error checking data source bounds: $e');
    }
  }

  static Future<List<HealthDataPoint>> fetchRespiratoryRateData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.respiratory_rate"},
          ],
          "bucketByTime": {"durationMillis": 3600000}, // Hourly
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseTimeSeriesData(
          data,
          HealthMetrics.metricsToTrack['respiratory_rate']!,
        );
      }
    } catch (e) {
      debugPrint('Error fetching respiratory rate data: $e');
    }
    return [];
  }

  // Method to specifically fetch heart rate data from FitCloudPro
  static Future<List<HealthDataPoint>> fetchFitCloudProHeartRate(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('Fetching FitCloudPro heart rate data...');

      // First, get all data sources to find FitCloudPro heart rate streams
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/fitness/v1/users/me/dataSources'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataSources = data['dataSource'] ?? [];

        // Find FitCloudPro heart rate sources
        for (var source in dataSources) {
          final dataType = source['dataType']['name'];
          final appPackageName = source['application']?['packageName'] ?? '';
          final streamId = source['dataStreamId'];

          if ((appPackageName.contains('fitcloudpro') ||
                  appPackageName.contains('topstep')) &&
              dataType == 'com.google.heart_rate.bpm') {
            debugPrint('Found FitCloudPro HR stream: $streamId');

            // Fetch data directly from this stream
            final hrResponse = await http.get(
              Uri.parse(
                'https://www.googleapis.com/fitness/v1/users/me/dataSources/$streamId/datasets/${startTime * 1000000}-${endTime * 1000000}',
              ),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              },
            );

            if (hrResponse.statusCode == 200) {
              final hrData = jsonDecode(hrResponse.body);
              final points = hrData['point'] ?? [];

              debugPrint('FitCloudPro HR response: ${points.length} points');

              if (points.isNotEmpty) {
                final healthPoints = <HealthDataPoint>[];

                for (var point in points) {
                  try {
                    final value = point['value']?[0];
                    final timestamp = point['startTimeNanos'];

                    if (value != null && timestamp != null) {
                      final hrValue =
                          (value['fpVal'] ?? value['intVal'])?.toDouble();
                      if (hrValue != null && hrValue > 0) {
                        final time = DateTime.fromMillisecondsSinceEpoch(
                          int.parse(timestamp) ~/ 1000000,
                        );
                        healthPoints.add(
                          HealthDataPoint(timestamp: time, value: hrValue),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Error parsing FitCloudPro HR point: $e');
                  }
                }

                debugPrint(
                  'Successfully parsed ${healthPoints.length} FitCloudPro HR points',
                );
                if (healthPoints.isNotEmpty) {
                  return healthPoints;
                }
              }
            } else {
              debugPrint(
                'FitCloudPro HR fetch error: ${hrResponse.statusCode}',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching FitCloudPro heart rate: $e');
    }

    return [];
  }

  // Method to fetch all available data from FitCloudPro sources
  static Future<Map<String, List<HealthDataPoint>>> fetchAllFitCloudProData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    final result = <String, List<HealthDataPoint>>{};

    try {
      debugPrint('\n=== FETCHING ALL FITCLOUDPRO DATA ===');
      debugPrint(
        'Time range: ${DateTime.fromMillisecondsSinceEpoch(startTime)} to ${DateTime.fromMillisecondsSinceEpoch(endTime)}',
      );

      final response = await http.get(
        Uri.parse('https://www.googleapis.com/fitness/v1/users/me/dataSources'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataSources = data['dataSource'] ?? [];

        for (var source in dataSources) {
          final dataType = source['dataType']['name'];
          final appPackageName = source['application']?['packageName'] ?? '';
          final streamId = source['dataStreamId'];

          if (appPackageName.contains('fitcloudpro') ||
              appPackageName.contains('topstep')) {
            debugPrint('Fetching data from FitCloudPro source: $dataType');

            // Try multiple time ranges for each data type
            final timeRanges = [
              {'start': startTime, 'end': endTime, 'label': 'requested range'},
              {
                'start':
                    DateTime.now()
                        .subtract(Duration(days: 7))
                        .millisecondsSinceEpoch,
                'end': DateTime.now().millisecondsSinceEpoch,
                'label': 'last 7 days',
              },
              {
                'start':
                    DateTime.now()
                        .subtract(Duration(days: 30))
                        .millisecondsSinceEpoch,
                'end': DateTime.now().millisecondsSinceEpoch,
                'label': 'last 30 days',
              },
            ];

            bool foundData = false;
            for (var timeRange in timeRanges) {
              if (foundData) break;

              try {
                final startMs = (timeRange['start'] as int) * 1000000;
                final endMs = (timeRange['end'] as int) * 1000000;

                final dataResponse = await http.get(
                  Uri.parse(
                    'https://www.googleapis.com/fitness/v1/users/me/dataSources/$streamId/datasets/$startMs-$endMs',
                  ),
                  headers: {
                    'Authorization': 'Bearer $accessToken',
                    'Content-Type': 'application/json',
                  },
                );

                if (dataResponse.statusCode == 200) {
                  final responseData = jsonDecode(dataResponse.body);
                  final points = responseData['point'] ?? [];

                  debugPrint(
                    '  📊 ${timeRange['label']}: ${points.length} raw points',
                  );

                  if (points.isNotEmpty) {
                    final healthPoints = <HealthDataPoint>[];

                    for (var point in points) {
                      try {
                        final value = point['value']?[0];
                        final timestamp = point['startTimeNanos'];

                        if (value != null && timestamp != null) {
                          final pointValue =
                              (value['fpVal'] ?? value['intVal'])?.toDouble();
                          if (pointValue != null && pointValue > 0) {
                            final time = DateTime.fromMillisecondsSinceEpoch(
                              int.parse(timestamp) ~/ 1000000,
                            );
                            healthPoints.add(
                              HealthDataPoint(
                                timestamp: time,
                                value: pointValue,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('Error parsing point for $dataType: $e');
                      }
                    }

                    if (healthPoints.isNotEmpty) {
                      result[dataType] = healthPoints;
                      debugPrint(
                        '✅ $dataType: ${healthPoints.length} valid points from ${timeRange['label']}',
                      );

                      // Show sample values with timestamps
                      final samples = healthPoints.take(3);
                      for (var sample in samples) {
                        debugPrint(
                          '  📈 Sample: ${sample.value} at ${sample.timestamp.toString().substring(0, 19)}',
                        );
                      }

                      // Show data age
                      final latestTime = healthPoints
                          .map((p) => p.timestamp)
                          .reduce((a, b) => a.isAfter(b) ? a : b);
                      final age = DateTime.now().difference(latestTime);
                      debugPrint(
                        '  📅 Latest data is ${age.inHours}h ${age.inMinutes % 60}m old',
                      );

                      foundData = true;
                    }
                  }
                } else {
                  debugPrint(
                    '  ❌ ${timeRange['label']}: HTTP ${dataResponse.statusCode}',
                  );
                  if (dataResponse.statusCode == 400) {
                    final errorBody = jsonDecode(dataResponse.body);
                    debugPrint(
                      '  📋 Error details: ${errorBody['error']?['message']}',
                    );
                  }
                }
              } catch (e) {
                debugPrint(
                  '  ❌ Error fetching $dataType from ${timeRange['label']}: $e',
                );
              }
            }

            if (!foundData) {
              debugPrint('  ⚠️  No data found for $dataType in any time range');
            }
          }
        }
      }

      debugPrint('=== FITCLOUDPRO DATA SUMMARY ===');
      if (result.isEmpty) {
        debugPrint('❌ No FitCloudPro data retrieved');
        debugPrint('💡 Possible reasons:');
        debugPrint('   • Smartwatch not syncing to Google Fit');
        debugPrint('   • Data sync disabled in FitCloudPro app');
        debugPrint('   • Recent data not yet uploaded');
        debugPrint('   • Permission issues with data sharing');
      } else {
        result.forEach((key, value) {
          debugPrint('✅ $key: ${value.length} data points');
        });
      }
      debugPrint('=== END FITCLOUDPRO FETCH ===\n');
    } catch (e) {
      debugPrint('Error in fetchAllFitCloudProData: $e');
    }

    return result;
  }

  // Method to fetch blood pressure data from FitCloudPro
  static Future<List<HealthDataPoint>> fetchFitCloudProBloodPressureData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('Fetching FitCloudPro blood pressure data...');
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.blood_pressure"},
          ],
          "bucketByTime": {"durationMillis": 86400000}, // Daily buckets
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('FitCloudPro blood pressure API response received');
        return _parseFitCloudProBloodPressureData(data);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching FitCloudPro blood pressure data: $e');
      return [];
    }
  }

  // Method to fetch body temperature data from FitCloudPro
  static Future<List<HealthDataPoint>> fetchFitCloudProBodyTemperatureData(
    String accessToken,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('Fetching FitCloudPro body temperature data...');
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "aggregateBy": [
            {"dataTypeName": "com.google.body_temperature"},
          ],
          "bucketByTime": {"durationMillis": 3600000}, // Hourly buckets
          "startTimeMillis": startTime,
          "endTimeMillis": endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('FitCloudPro body temperature API response received');
        return _parseFitCloudProTemperatureData(data);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching FitCloudPro body temperature data: $e');
      return [];
    }
  }

  // Helper method to parse FitCloudPro blood pressure data
  static List<HealthDataPoint> _parseFitCloudProBloodPressureData(
    Map<String, dynamic> data,
  ) {
    final dataPoints = <HealthDataPoint>[];

    try {
      final buckets = data['bucket'] ?? [];
      for (var bucket in buckets) {
        final datasets = bucket['dataset'] ?? [];
        for (var dataset in datasets) {
          final points = dataset['point'] ?? [];
          for (var point in points) {
            final startTime = int.parse(point['startTimeNanos']) ~/ 1000000;
            final values = point['value'] ?? [];

            if (values.length >= 2) {
              // Blood pressure has systolic and diastolic values
              final systolic = values[0]['fpVal']?.toDouble() ?? 0.0;
              final diastolic = values[1]['fpVal']?.toDouble() ?? 0.0;

              if (systolic > 0 && diastolic > 0) {
                dataPoints.add(
                  HealthDataPoint(
                    timestamp: DateTime.fromMillisecondsSinceEpoch(startTime),
                    value: systolic, // Store systolic as primary value
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing FitCloudPro blood pressure data: $e');
    }

    debugPrint(
      'Parsed ${dataPoints.length} FitCloudPro blood pressure data points',
    );
    return dataPoints;
  }

  // Helper method to parse FitCloudPro temperature data
  static List<HealthDataPoint> _parseFitCloudProTemperatureData(
    Map<String, dynamic> data,
  ) {
    final dataPoints = <HealthDataPoint>[];

    try {
      final buckets = data['bucket'] ?? [];
      for (var bucket in buckets) {
        final datasets = bucket['dataset'] ?? [];
        for (var dataset in datasets) {
          final points = dataset['point'] ?? [];
          for (var point in points) {
            final startTime = int.parse(point['startTimeNanos']) ~/ 1000000;
            final values = point['value'] ?? [];

            if (values.isNotEmpty) {
              final temperature = values[0]['fpVal']?.toDouble() ?? 0.0;

              if (temperature > 0) {
                dataPoints.add(
                  HealthDataPoint(
                    timestamp: DateTime.fromMillisecondsSinceEpoch(startTime),
                    value: temperature,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing FitCloudPro temperature data: $e');
    }

    debugPrint(
      'Parsed ${dataPoints.length} FitCloudPro temperature data points',
    );
    return dataPoints;
  }
}
