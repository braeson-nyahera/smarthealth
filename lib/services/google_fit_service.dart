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
        return _parseTimeSeriesData(data, metric);
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

        DateTime dayStart = DateTime.parse('$day 00:00:00');

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
            DateTime date = DateTime.parse('$day 00:00:00');
            sessionPoints.add(
              HealthDataPoint(timestamp: date, value: sessions.toDouble()),
            );
          });

          dailyDuration.forEach((day, duration) {
            DateTime date = DateTime.parse('$day 00:00:00');
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
}
