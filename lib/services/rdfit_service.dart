import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/health_models.dart';

/// Service to integrate with RDfit API for additional health data
/// Currently uses mock data as fallback since RDfit endpoints are not available
class RDfitService {
  // RDfit API configuration
  static const String _baseUrl = 'https://api.rdfit.com';
  static const String _apiVersion = 'v1';

  // API Endpoints
  static const String _heartRateEndpoint = '/heart-rate';
  static const String _stepsEndpoint = '/steps';
  static const String _caloriesEndpoint = '/calories';
  static const String _sleepEndpoint = '/sleep';
  static const String _oxygenSaturationEndpoint = '/oxygen-saturation';

  /// Fetch heart rate data from RDfit API
  static Future<List<HealthDataPoint>> fetchHeartRateData(
    String apiKey,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('🔄 Fetching RDfit heart rate data...');

      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiVersion$_heartRateEndpoint').replace(
          queryParameters: {
            'start_time': startTime.toString(),
            'end_time': endTime.toString(),
            'limit': '1000',
          },
        ),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // TODO: Parse real API data when endpoints are working
        debugPrint('✅ RDfit heart rate: API responded with real data');
        final data = response.body;
        debugPrint('📄 Response body: $data');
        return []; // Return empty for now until we can parse real data
      } else {
        debugPrint('⚠️ RDfit heart rate API error: ${response.statusCode}');
        debugPrint('📄 Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching RDfit heart rate data: $e');
      return [];
    }
  }

  /// Fetch steps data from RDfit API
  static Future<List<HealthDataPoint>> fetchStepsData(
    String apiKey,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('🔄 Fetching RDfit steps data...');

      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiVersion$_stepsEndpoint').replace(
          queryParameters: {
            'start_time': startTime.toString(),
            'end_time': endTime.toString(),
            'limit': '1000',
          },
        ),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ RDfit steps: API responded with real data');
        final data = response.body;
        debugPrint('📄 Response body: $data');
        return []; // Return empty for now until we can parse real data
      } else {
        debugPrint('⚠️ RDfit steps API error: ${response.statusCode}');
        debugPrint('📄 Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching RDfit steps data: $e');
      return [];
    }
  }

  /// Fetch calories data from RDfit API
  static Future<List<HealthDataPoint>> fetchCaloriesData(
    String apiKey,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('🔄 Fetching RDfit calories data...');

      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiVersion$_caloriesEndpoint').replace(
          queryParameters: {
            'start_time': startTime.toString(),
            'end_time': endTime.toString(),
            'limit': '1000',
          },
        ),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ RDfit calories: API responded with real data');
        final data = response.body;
        debugPrint('📄 Response body: $data');
        return []; // Return empty for now until we can parse real data
      } else {
        debugPrint('⚠️ RDfit calories API error: ${response.statusCode}');
        debugPrint('📄 Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching RDfit calories data: $e');
      return [];
    }
  }

  /// Fetch sleep data from RDfit API
  static Future<List<HealthDataPoint>> fetchSleepData(
    String apiKey,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('🔄 Fetching RDfit sleep data...');

      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiVersion$_sleepEndpoint').replace(
          queryParameters: {
            'start_time': startTime.toString(),
            'end_time': endTime.toString(),
            'limit': '1000',
          },
        ),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ RDfit sleep: API responded with real data');
        final data = response.body;
        debugPrint('📄 Response body: $data');
        return []; // Return empty for now until we can parse real data
      } else {
        debugPrint('⚠️ RDfit sleep API error: ${response.statusCode}');
        debugPrint('📄 Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching RDfit sleep data: $e');
      return [];
    }
  }

  /// Fetch oxygen saturation data from RDfit API
  static Future<List<HealthDataPoint>> fetchOxygenSaturationData(
    String apiKey,
    int startTime,
    int endTime,
  ) async {
    try {
      debugPrint('🔄 Fetching RDfit oxygen saturation data...');

      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiVersion$_oxygenSaturationEndpoint').replace(
          queryParameters: {
            'start_time': startTime.toString(),
            'end_time': endTime.toString(),
            'limit': '1000',
          },
        ),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ RDfit oxygen saturation: API responded with real data');
        final data = response.body;
        debugPrint('📄 Response body: $data');
        return []; // Return empty for now until we can parse real data
      } else {
        debugPrint(
          '⚠️ RDfit oxygen saturation API error: ${response.statusCode}',
        );
        debugPrint('📄 Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching RDfit oxygen saturation data: $e');
      return [];
    }
  }

  /// Fetch all available data from RDfit API
  static Future<Map<String, List<HealthDataPoint>>> fetchAllRDfitData(
    String apiKey,
    int startTime,
    int endTime,
  ) async {
    debugPrint('\n=== FETCHING ALL RDFIT DATA ===');
    debugPrint(
      'Time range: ${DateTime.fromMillisecondsSinceEpoch(startTime)} to ${DateTime.fromMillisecondsSinceEpoch(endTime)}',
    );

    final Map<String, List<HealthDataPoint>> allData = {};

    // Fetch all data types in parallel for better performance
    final futures = await Future.wait([
      fetchHeartRateData(apiKey, startTime, endTime),
      fetchStepsData(apiKey, startTime, endTime),
      fetchCaloriesData(apiKey, startTime, endTime),
      fetchSleepData(apiKey, startTime, endTime),
      fetchOxygenSaturationData(apiKey, startTime, endTime),
    ]);

    allData['heart_rate'] = futures[0];
    allData['steps'] = futures[1];
    allData['calories'] = futures[2];
    allData['sleep_hours'] = futures[3];
    allData['oxygen_saturation'] = futures[4];

    debugPrint('=== RDFIT DATA SUMMARY ===');
    int totalPoints = 0;
    for (var entry in allData.entries) {
      final count = entry.value.length;
      totalPoints += count;
      if (count > 0) {
        debugPrint('✅ ${entry.key}: $count data points');
      } else {
        debugPrint('⚠️ ${entry.key}: No data');
      }
    }
    debugPrint('📊 Total RDfit data points: $totalPoints');
    debugPrint('=== END RDFIT SUMMARY ===\n');

    return allData;
  }

  /// Test RDfit API connectivity
  static Future<bool> testConnection(String apiKey) async {
    try {
      debugPrint('🔄 Testing RDfit API connection...');

      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiVersion/status'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ RDfit API connection successful');
        return true;
      } else {
        debugPrint('⚠️ RDfit API connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ RDfit API connection error: $e');
      return false;
    }
  }
}
