import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';

// Enums
enum ValueType { integer, decimal }

void main() => runApp(SmartHealthApp());

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHealth - Complete Biometric Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HealthDataPage(),
    );
  }
}

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({super.key});

  @override
  State<HealthDataPage> createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      // Core fitness scopes
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.heart_rate.read',
      'https://www.googleapis.com/auth/fitness.sleep.read',
      'https://www.googleapis.com/auth/fitness.body.read',
      'https://www.googleapis.com/auth/fitness.nutrition.read',
      'https://www.googleapis.com/auth/fitness.oxygen_saturation.read',
      'https://www.googleapis.com/auth/fitness.body_temperature.read',
      'https://www.googleapis.com/auth/fitness.reproductive_health.read',
      // Additional scopes for comprehensive data
      'https://www.googleapis.com/auth/fitness.blood_glucose.read',
      'https://www.googleapis.com/auth/fitness.blood_pressure.read',
      'https://www.googleapis.com/auth/fitness.location.read',
    ],
  );

  GoogleSignInAccount? _user;
  Map<String, List<HealthDataPoint>> _timeSeriesData = {};
  Map<String, HealthSummary> _summaryData = {};
  String _debugMessage = '';
  bool _isLoading = false;
  int _selectedDays = 7;

  // Comprehensive health metrics mapping
  final Map<String, HealthMetric> _metricsToTrack = {
    // Basic Activity Metrics
    'steps': HealthMetric(
      dataType: 'com.google.step_count.delta',
      name: 'Daily Steps',
      unit: 'steps',
      color: Colors.blue,
      icon: Icons.directions_walk,
      valueType: ValueType.integer,
      category: 'Activity',
    ),
    'calories': HealthMetric(
      dataType: 'com.google.calories.expended',
      name: 'Calories Burned',
      unit: 'cal',
      color: Colors.orange,
      icon: Icons.local_fire_department,
      valueType: ValueType.integer,
      category: 'Activity',
    ),
    'distance': HealthMetric(
      dataType: 'com.google.distance.delta',
      name: 'Distance',
      unit: 'km',
      color: Colors.green,
      icon: Icons.straighten,
      valueType: ValueType.decimal,
      category: 'Activity',
    ),
    'active_minutes': HealthMetric(
      dataType: 'com.google.active_minutes',
      name: 'Active Minutes',
      unit: 'min',
      color: Colors.lightGreen,
      icon: Icons.fitness_center,
      valueType: ValueType.integer,
      category: 'Activity',
    ),
    'floors_climbed': HealthMetric(
      dataType: 'com.google.floor_count.delta',
      name: 'Floors Climbed',
      unit: 'floors',
      color: Colors.brown,
      icon: Icons.stairs,
      valueType: ValueType.integer,
      category: 'Activity',
    ),

    // Heart Rate Metrics
    'heart_rate': HealthMetric(
      dataType: 'com.google.heart_rate.bpm',
      name: 'Heart Rate',
      unit: 'bpm',
      color: Colors.red,
      icon: Icons.favorite,
      valueType: ValueType.decimal,
      category: 'Heart',
    ),
    'resting_heart_rate': HealthMetric(
      dataType: 'com.google.heart_rate.bpm',
      name: 'Resting Heart Rate',
      unit: 'bpm',
      color: Colors.redAccent,
      icon: Icons.favorite_border,
      valueType: ValueType.decimal,
      category: 'Heart',
    ),
    'max_heart_rate': HealthMetric(
      dataType: 'com.google.heart_rate.bpm',
      name: 'Max Heart Rate',
      unit: 'bpm',
      color: Colors.deepOrange,
      icon: Icons.favorite_rounded,
      valueType: ValueType.decimal,
      category: 'Heart',
    ),
    'heart_rate_variability': HealthMetric(
      dataType: 'com.google.heart_rate.variability',
      name: 'HRV (RMSSD)',
      unit: 'ms',
      color: Colors.pink,
      icon: Icons.monitor_heart,
      valueType: ValueType.decimal,
      category: 'Heart',
    ),

    // Sleep Metrics
    'sleep_duration': HealthMetric(
      dataType: 'com.google.sleep.segment',
      name: 'Sleep Duration',
      unit: 'hours',
      color: Colors.indigo,
      icon: Icons.bedtime,
      valueType: ValueType.decimal,
      category: 'Sleep',
    ),
    'deep_sleep': HealthMetric(
      dataType: 'com.google.sleep.segment',
      name: 'Deep Sleep',
      unit: '%',
      color: Colors.deepPurple,
      icon: Icons.hotel,
      valueType: ValueType.decimal,
      category: 'Sleep',
    ),
    'rem_sleep': HealthMetric(
      dataType: 'com.google.sleep.segment',
      name: 'REM Sleep',
      unit: '%',
      color: Colors.purple,
      icon: Icons.psychology,
      valueType: ValueType.decimal,
      category: 'Sleep',
    ),
    'sleep_efficiency': HealthMetric(
      dataType: 'com.google.sleep.segment',
      name: 'Sleep Efficiency',
      unit: '%',
      color: Colors.blueGrey,
      icon: Icons.nights_stay,
      valueType: ValueType.decimal,
      category: 'Sleep',
    ),

    // Body Metrics
    'weight': HealthMetric(
      dataType: 'com.google.weight',
      name: 'Weight',
      unit: 'kg',
      color: Colors.purple,
      icon: Icons.monitor_weight,
      valueType: ValueType.decimal,
      category: 'Body',
    ),
    'oxygen_saturation': HealthMetric(
      dataType: 'com.google.oxygen_saturation',
      name: 'Blood Oxygen (SpO2)',
      unit: '%',
      color: Colors.teal,
      icon: Icons.air,
      valueType: ValueType.decimal,
      category: 'Vitals',
    ),
    'skin_temperature': HealthMetric(
      dataType: 'com.google.body.temperature',
      name: 'Skin Temperature',
      unit: '°C',
      color: Colors.amber,
      icon: Icons.thermostat,
      valueType: ValueType.decimal,
      category: 'Vitals',
    ),
    'breathing_rate': HealthMetric(
      dataType: 'com.google.respiratory_rate',
      name: 'Breathing Rate',
      unit: 'bpm',
      color: Colors.cyan,
      icon: Icons.waves,
      valueType: ValueType.decimal,
      category: 'Vitals',
    ),

    // Stress and Recovery
    'stress_score': HealthMetric(
      dataType: 'com.google.stress.level',
      name: 'Stress Score',
      unit: '/100',
      color: Colors.yellow[700]!,
      icon: Icons.psychology_alt,
      valueType: ValueType.decimal,
      category: 'Wellness',
    ),
    'recovery_score': HealthMetric(
      dataType: 'com.google.recovery.score',
      name: 'Recovery Score',
      unit: '/100',
      color: Colors.lightBlue,
      icon: Icons.healing,
      valueType: ValueType.decimal,
      category: 'Wellness',
    ),

    // Blood Pressure (if available)
    'systolic_bp': HealthMetric(
      dataType: 'com.google.blood_pressure',
      name: 'Systolic BP',
      unit: 'mmHg',
      color: Colors.red[800]!,
      icon: Icons.monitor,
      valueType: ValueType.decimal,
      category: 'Vitals',
    ),
    'diastolic_bp': HealthMetric(
      dataType: 'com.google.blood_pressure',
      name: 'Diastolic BP',
      unit: 'mmHg',
      color: Colors.red[600]!,
      icon: Icons.monitor,
      valueType: ValueType.decimal,
      category: 'Vitals',
    ),
  };

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _debugMessage = 'Sign-in cancelled by user');
        return;
      }
      setState(() => _user = account);
      await _fetchComprehensiveHealthData();
    } catch (error) {
      setState(() => _debugMessage = 'Sign-in error: $error');
      debugPrint('Sign-in error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchComprehensiveHealthData() async {
    setState(() {
      _isLoading = true;
      _debugMessage = 'Fetching comprehensive health data...';
    });

    try {
      final auth = await _user?.authentication;
      final accessToken = auth?.accessToken;

      if (accessToken == null) {
        setState(() => _debugMessage = 'No access token available');
        return;
      }

      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: _selectedDays));
      final endTime = now.millisecondsSinceEpoch;
      final startTime = startDate.millisecondsSinceEpoch;

      Map<String, List<HealthDataPoint>> newTimeSeriesData = {};
      Map<String, HealthSummary> newSummaryData = {};

      // Fetch data for each metric category
      await _fetchActivityData(
        accessToken,
        startTime,
        endTime,
        newTimeSeriesData,
        newSummaryData,
      );
      await _fetchHeartRateData(
        accessToken,
        startTime,
        endTime,
        newTimeSeriesData,
        newSummaryData,
      );
      await _fetchSleepData(
        accessToken,
        startTime,
        endTime,
        newTimeSeriesData,
        newSummaryData,
      );
      await _fetchVitalSigns(
        accessToken,
        startTime,
        endTime,
        newTimeSeriesData,
        newSummaryData,
      );
      await _fetchWellnessData(
        accessToken,
        startTime,
        endTime,
        newTimeSeriesData,
        newSummaryData,
      );

      setState(() {
        _timeSeriesData = newTimeSeriesData;
        _summaryData = newSummaryData;
        _debugMessage = 'Loaded data for ${newTimeSeriesData.length} metrics';
      });
    } catch (error) {
      setState(() => _debugMessage = 'Error fetching data: $error');
      debugPrint('Error fetching data: $error');
    } finally {
      setState(() => _isLoading = false);
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
      if (_metricsToTrack.containsKey(key)) {
        try {
          final dataPoints = await _fetchDetailedTimeSeriesData(
            accessToken,
            _metricsToTrack[key]!,
            startTime,
            endTime,
            key,
          );
          if (dataPoints.isNotEmpty) {
            timeSeriesData[key] = dataPoints;
            summaryData[key] = _calculateSummary(dataPoints);
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
      // Fetch detailed heart rate data
      final hrData = await _fetchDetailedTimeSeriesData(
        accessToken,
        _metricsToTrack['heart_rate']!,
        startTime,
        endTime,
        'heart_rate',
      );

      if (hrData.isNotEmpty) {
        timeSeriesData['heart_rate'] = hrData;
        summaryData['heart_rate'] = _calculateSummary(hrData);

        // Calculate derived metrics
        _calculateHeartRateMetrics(hrData, timeSeriesData, summaryData);
      }

      // Try to fetch HRV data separately
      await _fetchHRVData(
        accessToken,
        startTime,
        endTime,
        timeSeriesData,
        summaryData,
      );
    } catch (e) {
      debugPrint('Error fetching heart rate data: $e');
    }
  }

  Future<void> _fetchHRVData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
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

        if (hrvPoints.isNotEmpty) {
          timeSeriesData['heart_rate_variability'] = hrvPoints;
          summaryData['heart_rate_variability'] = _calculateSummary(hrvPoints);
        }
      }
    } catch (e) {
      debugPrint('Error fetching HRV data: $e');
    }
  }

  HealthDataPoint? _parseHRVPoint(Map<String, dynamic> point) {
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

  void _calculateHeartRateMetrics(
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
      summaryData['resting_heart_rate'] = _calculateSummary(restingHRPoints);
    }

    if (maxHRPoints.isNotEmpty) {
      timeSeriesData['max_heart_rate'] = maxHRPoints;
      summaryData['max_heart_rate'] = _calculateSummary(maxHRPoints);
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
        _processSleepData(data, timeSeriesData, summaryData);
      }
    } catch (e) {
      debugPrint('Error fetching sleep data: $e');
    }
  }

  void _processSleepData(
    Map<String, dynamic> data,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) {
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

    if (sleepDurationPoints.isNotEmpty) {
      timeSeriesData['sleep_duration'] = sleepDurationPoints;
      summaryData['sleep_duration'] = _calculateSummary(sleepDurationPoints);
    }

    if (deepSleepPoints.isNotEmpty) {
      timeSeriesData['deep_sleep'] = deepSleepPoints;
      summaryData['deep_sleep'] = _calculateSummary(deepSleepPoints);
    }

    if (remSleepPoints.isNotEmpty) {
      timeSeriesData['rem_sleep'] = remSleepPoints;
      summaryData['rem_sleep'] = _calculateSummary(remSleepPoints);
    }

    if (sleepEfficiencyPoints.isNotEmpty) {
      timeSeriesData['sleep_efficiency'] = sleepEfficiencyPoints;
      summaryData['sleep_efficiency'] = _calculateSummary(
        sleepEfficiencyPoints,
      );
    }
  }

  Map<String, double>? _parseSleepSegment(Map<String, dynamic> point) {
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
      if (_metricsToTrack.containsKey(key)) {
        try {
          final dataPoints = await _fetchDetailedTimeSeriesData(
            accessToken,
            _metricsToTrack[key]!,
            startTime,
            endTime,
            key,
          );
          if (dataPoints.isNotEmpty) {
            timeSeriesData[key] = dataPoints;
            summaryData[key] = _calculateSummary(dataPoints);
          }
        } catch (e) {
          debugPrint('Error fetching $key: $e');
        }
        await Future.delayed(Duration(milliseconds: 200));
      }
    }

    // Fetch blood pressure data
    await _fetchBloodPressureData(
      accessToken,
      startTime,
      endTime,
      timeSeriesData,
      summaryData,
    );
  }

  Future<void> _fetchBloodPressureData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
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
        _processBloodPressureData(data, timeSeriesData, summaryData);
      }
    } catch (e) {
      debugPrint('Error fetching blood pressure data: $e');
    }
  }

  void _processBloodPressureData(
    Map<String, dynamic> data,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
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

    if (systolicPoints.isNotEmpty) {
      timeSeriesData['systolic_bp'] = systolicPoints;
      summaryData['systolic_bp'] = _calculateSummary(systolicPoints);
    }

    if (diastolicPoints.isNotEmpty) {
      timeSeriesData['diastolic_bp'] = diastolicPoints;
      summaryData['diastolic_bp'] = _calculateSummary(diastolicPoints);
    }
  }

  Map<String, dynamic>? _parseBloodPressurePoint(Map<String, dynamic> point) {
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

  Future<void> _fetchWellnessData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    final wellnessMetrics = ['stress_score', 'recovery_score'];

    for (String key in wellnessMetrics) {
      if (_metricsToTrack.containsKey(key)) {
        try {
          final dataPoints = await _fetchDetailedTimeSeriesData(
            accessToken,
            _metricsToTrack[key]!,
            startTime,
            endTime,
            key,
          );
          if (dataPoints.isNotEmpty) {
            timeSeriesData[key] = dataPoints;
            summaryData[key] = _calculateSummary(dataPoints);
          }
        } catch (e) {
          debugPrint('Error fetching $key: $e');
        }
        await Future.delayed(Duration(milliseconds: 200));
      }
    }

    // Fetch weight data
    await _fetchWeightData(
      accessToken,
      startTime,
      endTime,
      timeSeriesData,
      summaryData,
    );
  }

  Future<void> _fetchWeightData(
    String accessToken,
    int startTime,
    int endTime,
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthSummary> summaryData,
  ) async {
    try {
      final dataPoints = await _fetchDetailedTimeSeriesData(
        accessToken,
        _metricsToTrack['weight']!,
        startTime,
        endTime,
        'weight',
      );
      if (dataPoints.isNotEmpty) {
        timeSeriesData['weight'] = dataPoints;
        summaryData['weight'] = _calculateSummary(dataPoints);
      }
    } catch (e) {
      debugPrint('Error fetching weight data: $e');
    }
  }

  Future<List<HealthDataPoint>> _fetchDetailedTimeSeriesData(
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

  List<HealthDataPoint> _parseTimeSeriesData(
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

  HealthDataPoint? _parseDataPoint(
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

  HealthSummary _calculateSummary(List<HealthDataPoint> points) {
    if (points.isEmpty) {
      return HealthSummary(average: 0, min: 0, max: 0, latest: 0, trend: 0);
    }

    final values = points.map((p) => p.value).toList();
    final latest = points.last.value;
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Calculate trend (simple linear regression slope)
    double trend = 0;
    if (points.length > 1) {
      final n = points.length;
      final xSum = List.generate(n, (i) => i).reduce((a, b) => a + b);
      final ySum = values.reduce((a, b) => a + b);
      final xySum = List.generate(
        n,
        (i) => i * values[i],
      ).reduce((a, b) => a + b);
      final x2Sum = List.generate(n, (i) => i * i).reduce((a, b) => a + b);

      trend = (n * xySum - xSum * ySum) / (n * x2Sum - xSum * xSum);
    }

    return HealthSummary(
      average: average,
      min: min,
      max: max,
      latest: latest,
      trend: trend,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SmartHealth Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<int>(
            value: _selectedDays,
            dropdownColor: Colors.blue[700],
            style: TextStyle(color: Colors.white),
            underline: Container(),
            items:
                [7, 14, 30, 90].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text(
                      '$days days',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null && value != _selectedDays) {
                setState(() => _selectedDays = value);
                if (_user != null) {
                  _fetchComprehensiveHealthData();
                }
              }
            },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_user == null) {
      return _buildSignInScreen();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_timeSeriesData.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDashboard();
  }

  Widget _buildSignInScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 80, color: Colors.blue[700]),
          SizedBox(height: 24),
          Text(
            'SmartHealth Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Connect your Google Fit account to view\ncomprehensive health metrics',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSignIn,
            icon: Icon(Icons.login),
            label: Text('Sign in with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          if (_debugMessage.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _debugMessage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          SizedBox(height: 16),
          Text(
            _debugMessage.isNotEmpty ? _debugMessage : 'Loading health data...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_usage_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No health data found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Make sure you have Google Fit data\nfor the selected time period',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchComprehensiveHealthData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
          if (_debugMessage.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                _debugMessage,
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          SizedBox(height: 24),
          _buildMetricCategories(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                _user?.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child:
                _user?.photoUrl == null
                    ? Icon(Icons.person, size: 30, color: Colors.white)
                    : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.displayName ?? 'User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Health data for last $_selectedDays days',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${_timeSeriesData.length} metrics tracked',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchComprehensiveHealthData,
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh data',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCategories() {
    final categories = _groupMetricsByCategory();

    return Column(
      children:
          categories.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(entry.key),
                SizedBox(height: 12),
                _buildMetricGrid(entry.value),
                SizedBox(height: 24),
              ],
            );
          }).toList(),
    );
  }

  Map<String, List<String>> _groupMetricsByCategory() {
    Map<String, List<String>> categories = {};

    for (String key in _timeSeriesData.keys) {
      if (_metricsToTrack.containsKey(key)) {
        String category = _metricsToTrack[key]!.category;
        categories.putIfAbsent(category, () => []).add(key);
      }
    }

    return categories;
  }

  Widget _buildCategoryHeader(String category) {
    final iconMap = {
      'Activity': Icons.directions_run,
      'Heart': Icons.favorite,
      'Sleep': Icons.bedtime,
      'Body': Icons.monitor_weight,
      'Vitals': Icons.monitor_heart,
      'Wellness': Icons.psychology,
    };

    return Row(
      children: [
        Icon(
          iconMap[category] ?? Icons.health_and_safety,
          color: Colors.blue[700],
          size: 24,
        ),
        SizedBox(width: 8),
        Text(
          category,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            margin: EdgeInsets.only(left: 16),
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGrid(List<String> metricKeys) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metricKeys.length,
      itemBuilder: (context, index) {
        final key = metricKeys[index];
        return _buildMetricCard(key);
      },
    );
  }

  Widget _buildMetricCard(String key) {
    final metric = _metricsToTrack[key]!;
    final summary = _summaryData[key];
    final timeSeries = _timeSeriesData[key];

    if (summary == null || timeSeries == null) {
      return Container();
    }

    return GestureDetector(
      onTap: () => _showDetailedView(key, metric, timeSeries),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metric.icon, color: metric.color, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _formatValue(summary.latest, metric),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  summary.trend > 0
                      ? Icons.trending_up
                      : summary.trend < 0
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  size: 16,
                  color:
                      summary.trend > 0
                          ? Colors.green
                          : summary.trend < 0
                          ? Colors.red
                          : Colors.grey,
                ),
                SizedBox(width: 4),
                Text(
                  'Avg: ${_formatValue(summary.average, metric)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildMiniChart(timeSeries, metric.color),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<HealthDataPoint> data, Color color) {
    if (data.length < 2) {
      return SizedBox(
        height: 30,
        child: Center(
          child: Text(
            'Insufficient data',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: data.map((e) => e.value).reduce(min),
          maxY: data.map((e) => e.value).reduce(max),
        ),
      ),
    );
  }

  void _showDetailedView(
    String key,
    HealthMetric metric,
    List<HealthDataPoint> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(metric.icon, color: metric.color, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metric.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${data.length} data points',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildDetailedChart(data, metric),
                            SizedBox(height: 24),
                            _buildDetailedStats(key, metric),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildDetailedChart(List<HealthDataPoint> data, HealthMetric metric) {
    if (data.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('Insufficient data for chart')),
      );
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                (data.map((e) => e.value).reduce(max) -
                    data.map((e) => e.value).reduce(min)) /
                5,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatValue(value, metric),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (data.length / 5).ceil().toDouble(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    final date = data[value.toInt()].timestamp;
                    return Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          lineBarsData: [
            LineChartBarData(
              spots:
                  data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
              isCurved: true,
              color: metric.color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: metric.color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: metric.color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(String key, HealthMetric metric) {
    final summary = _summaryData[key]!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Latest',
                  _formatValue(summary.latest, metric),
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Average',
                  _formatValue(summary.average, metric),
                  Icons.show_chart,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Minimum',
                  _formatValue(summary.min, metric),
                  Icons.south,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Maximum',
                  _formatValue(summary.max, metric),
                  Icons.north,
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildStatItem(
            'Trend',
            summary.trend > 0
                ? 'Increasing'
                : summary.trend < 0
                ? 'Decreasing'
                : 'Stable',
            summary.trend > 0
                ? Icons.trending_up
                : summary.trend < 0
                ? Icons.trending_down
                : Icons.trending_flat,
            summary.trend > 0
                ? Colors.green
                : summary.trend < 0
                ? Colors.red
                : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value, HealthMetric metric) {
    if (metric.unit == 'steps') {
      return '${value.toInt()}';
    } else if (metric.unit == 'km') {
      return '${value.toStringAsFixed(2)} km';
    } else if (metric.unit == 'kcal') {
      return '${value.toInt()} kcal';
    } else if (metric.unit == 'bpm') {
      return '${value.toInt()} bpm';
    } else if (metric.unit == 'mmHg') {
      return '${value.toInt()} mmHg';
    } else if (metric.unit == 'kg') {
      return '${value.toStringAsFixed(1)} kg';
    } else if (metric.unit == 'hours') {
      return '${(value / 60).toStringAsFixed(1)}h';
    } else if (metric.unit == 'minutes') {
      return '${value.toInt()}m';
    } else if (metric.unit == '%') {
      return '${value.toInt()}%';
    } else if (metric.unit == 'score') {
      return '${value.toInt()}';
    } else {
      return value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _googleSignIn.signOut();
    super.dispose();
  }
}

// Data Models
class HealthDataPoint {
  final DateTime timestamp;
  final double value;

  HealthDataPoint({required this.timestamp, required this.value});
}

class HealthSummary {
  final double average;
  final double min;
  final double max;
  final double latest;
  final double trend;

  HealthSummary({
    required this.average,
    required this.min,
    required this.max,
    required this.latest,
    required this.trend,
  });
}

class HealthMetric {
  final String name;
  final String dataType;
  final String unit;
  final String category;
  final IconData icon;
  final Color color;
  final ValueType valueType;

  HealthMetric({
    required this.name,
    required this.dataType,
    required this.unit,
    required this.category,
    required this.icon,
    required this.color,
    required this.valueType,
  });
}
