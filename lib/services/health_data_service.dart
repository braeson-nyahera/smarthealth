import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/health_models.dart';
import '../constants/health_metrics.dart';
import '../utils/health_utils.dart';
import 'google_fit_service.dart';

class HealthDataService {
  late GoogleSignIn _googleSignIn;

  HealthDataService() {
    _googleSignIn = GoogleSignIn(scopes: HealthMetrics.googleFitScopes);
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

      return {
        'timeSeriesData': newTimeSeriesData,
        'summaryData': newSummaryData,
        'message': 'Loaded data for ${newTimeSeriesData.length} metrics',
      };
    } catch (error) {
      throw Exception('Error fetching data: $error');
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
      // Fetch detailed heart rate data
      final hrData = await GoogleFitService.fetchDetailedTimeSeriesData(
        accessToken,
        HealthMetrics.metricsToTrack['heart_rate']!,
        startTime,
        endTime,
        'heart_rate',
      );

      if (hrData.isNotEmpty) {
        timeSeriesData['heart_rate'] = hrData;
        summaryData['heart_rate'] = HealthUtils.calculateSummary(hrData);

        // Calculate derived metrics
        GoogleFitService.calculateHeartRateMetrics(
          hrData,
          timeSeriesData,
          summaryData,
        );
      }

      // Try to fetch HRV data separately
      final hrvData = await GoogleFitService.fetchHRVData(
        accessToken,
        startTime,
        endTime,
      );

      if (hrvData.isNotEmpty) {
        timeSeriesData['heart_rate_variability'] = hrvData;
        summaryData['heart_rate_variability'] = HealthUtils.calculateSummary(
          hrvData,
        );
      }
    } catch (e) {
      debugPrint('Error fetching heart rate data: $e');
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
}
