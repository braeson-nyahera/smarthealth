import 'package:flutter/foundation.dart';
import '../models/health_models.dart';
import 'dart:math' as math;

/// Service to predict blood pressure (systolic and diastolic) using health metrics
/// from Google Fit and FitCloudPro
class BloodPressurePredictionService {
  /// Predict blood pressure based on available health metrics
  ///
  /// Uses multiple health indicators to estimate BP:
  /// - Heart rate (resting and active)
  /// - Physical activity levels (steps, exercise)
  /// - Sleep quality and duration
  /// - Age and BMI (from profile if available)
  /// - Historical BP patterns (if any)
  ///
  /// Returns a map with 'systolic' and 'diastolic' predictions
  static Future<Map<String, dynamic>> predictBloodPressure({
    required Map<String, List<HealthDataPoint>> timeSeriesData,
    int? age,
    double? bmi,
    bool? isSmoker,
    bool? hasHighCholesterol,
    Map<String, double>? historicalBP,
  }) async {
    try {
      debugPrint('🩺 Starting blood pressure prediction...');

      // Extract relevant health metrics
      final heartRateData = timeSeriesData['heart_rate'] ?? [];
      final stepsData = timeSeriesData['steps'] ?? [];
      final sleepData = timeSeriesData['sleep_hours'] ?? [];
      final activeMinutesData = timeSeriesData['active_minutes'] ?? [];
      final restingHRData = timeSeriesData['resting_heart_rate'] ?? [];

      // Calculate average metrics
      final avgHeartRate = _calculateAverage(heartRateData);
      final avgRestingHR =
          restingHRData.isNotEmpty
              ? _calculateAverage(restingHRData)
              : avgHeartRate * 0.85; // Estimate if not available

      final avgSteps = _calculateAverage(stepsData);
      final avgSleep = _calculateAverage(sleepData);
      final avgActiveMinutes = _calculateAverage(activeMinutesData);

      debugPrint('📊 Health metrics:');
      debugPrint('   Avg Heart Rate: ${avgHeartRate.toStringAsFixed(1)} bpm');
      debugPrint('   Avg Resting HR: ${avgRestingHR.toStringAsFixed(1)} bpm');
      debugPrint('   Avg Steps: ${avgSteps.toStringAsFixed(0)} steps/day');
      debugPrint('   Avg Sleep: ${avgSleep.toStringAsFixed(1)} hours');
      debugPrint(
        '   Avg Active Minutes: ${avgActiveMinutes.toStringAsFixed(0)} min/day',
      );

      // Predict systolic BP
      final systolic = _predictSystolic(
        avgHeartRate: avgHeartRate,
        avgRestingHR: avgRestingHR,
        avgSteps: avgSteps,
        avgSleep: avgSleep,
        avgActiveMinutes: avgActiveMinutes,
        age: age,
        bmi: bmi,
        isSmoker: isSmoker,
        hasHighCholesterol: hasHighCholesterol,
        historicalSystolic: historicalBP?['systolic'],
      );

      // Predict diastolic BP
      final diastolic = _predictDiastolic(
        avgHeartRate: avgHeartRate,
        avgRestingHR: avgRestingHR,
        avgSteps: avgSteps,
        avgSleep: avgSleep,
        avgActiveMinutes: avgActiveMinutes,
        age: age,
        bmi: bmi,
        isSmoker: isSmoker,
        hasHighCholesterol: hasHighCholesterol,
        historicalDiastolic: historicalBP?['diastolic'],
        predictedSystolic: systolic,
      );

      // Calculate confidence based on data availability
      final confidence = _calculateConfidence(
        heartRateData.length,
        stepsData.length,
        sleepData.length,
        age != null,
        bmi != null,
        historicalBP != null,
      );

      debugPrint('✅ Blood pressure prediction completed:');
      debugPrint('   Systolic: ${systolic.toStringAsFixed(0)} mmHg');
      debugPrint('   Diastolic: ${diastolic.toStringAsFixed(0)} mmHg');
      debugPrint('   Confidence: ${(confidence * 100).toStringAsFixed(0)}%');

      return {
        'systolic': systolic.round(),
        'diastolic': diastolic.round(),
        'confidence': confidence,
        'timestamp': DateTime.now(),
        'basedOn': _getDataSources(timeSeriesData),
      };
    } catch (e) {
      debugPrint('❌ Error predicting blood pressure: $e');
      // Return default values with low confidence
      return {
        'systolic': 120,
        'diastolic': 80,
        'confidence': 0.3,
        'timestamp': DateTime.now(),
        'basedOn': ['default'],
        'error': e.toString(),
      };
    }
  }

  /// Predict systolic blood pressure
  static double _predictSystolic({
    required double avgHeartRate,
    required double avgRestingHR,
    required double avgSteps,
    required double avgSleep,
    required double avgActiveMinutes,
    int? age,
    double? bmi,
    bool? isSmoker,
    bool? hasHighCholesterol,
    double? historicalSystolic,
  }) {
    // Base systolic BP (normal range: 90-120)
    double systolic = 110.0;

    // Heart rate impact (higher HR often correlates with higher BP)
    if (avgRestingHR > 0) {
      // Resting HR: 60-100 bpm is normal
      // Each 10 bpm above 70 adds ~5 mmHg
      final hrDiff = avgRestingHR - 70;
      systolic += (hrDiff / 10) * 5;
    }

    // Physical activity impact (more activity = lower BP)
    if (avgSteps > 0) {
      // 10,000 steps is ideal
      // Less activity increases BP
      if (avgSteps < 5000) {
        systolic += 8; // Sedentary lifestyle
      } else if (avgSteps < 7500) {
        systolic += 4; // Low activity
      } else if (avgSteps > 12000) {
        systolic -= 5; // Very active
      }
    }

    // Sleep impact (poor sleep increases BP)
    if (avgSleep > 0) {
      // 7-9 hours is ideal
      if (avgSleep < 6) {
        systolic += 6; // Sleep deprived
      } else if (avgSleep < 7) {
        systolic += 3; // Insufficient sleep
      } else if (avgSleep > 9) {
        systolic += 2; // Too much sleep
      }
    }

    // Active minutes impact
    if (avgActiveMinutes > 0) {
      // 30+ minutes recommended
      if (avgActiveMinutes < 15) {
        systolic += 5;
      } else if (avgActiveMinutes >= 30) {
        systolic -= 3;
      }
    }

    // Age impact (BP increases with age)
    if (age != null) {
      // Add ~0.5 mmHg per year after 30
      if (age > 30) {
        systolic += (age - 30) * 0.5;
      }
    }

    // BMI impact
    if (bmi != null) {
      // Normal BMI: 18.5-24.9
      if (bmi > 25 && bmi < 30) {
        systolic += 5; // Overweight
      } else if (bmi >= 30) {
        systolic += 12; // Obese
      } else if (bmi < 18.5) {
        systolic -= 5; // Underweight
      }
    }

    // Smoking impact
    if (isSmoker == true) {
      systolic += 8;
    }

    // High cholesterol impact
    if (hasHighCholesterol == true) {
      systolic += 6;
    }

    // Use historical data if available (weighted average)
    if (historicalSystolic != null) {
      // 60% historical, 40% predicted
      systolic = (historicalSystolic * 0.6) + (systolic * 0.4);
    }

    // Ensure realistic range (90-180 mmHg)
    return systolic.clamp(90.0, 180.0);
  }

  /// Predict diastolic blood pressure
  static double _predictDiastolic({
    required double avgHeartRate,
    required double avgRestingHR,
    required double avgSteps,
    required double avgSleep,
    required double avgActiveMinutes,
    required double predictedSystolic,
    int? age,
    double? bmi,
    bool? isSmoker,
    bool? hasHighCholesterol,
    double? historicalDiastolic,
  }) {
    // Base diastolic BP (normal range: 60-80)
    double diastolic = 75.0;

    // Typically, diastolic is about 60-70% of systolic
    // Use predicted systolic as reference
    diastolic = predictedSystolic * 0.65;

    // Heart rate impact
    if (avgRestingHR > 0) {
      final hrDiff = avgRestingHR - 70;
      diastolic += (hrDiff / 10) * 3;
    }

    // Physical activity impact
    if (avgSteps > 0) {
      if (avgSteps < 5000) {
        diastolic += 5;
      } else if (avgSteps < 7500) {
        diastolic += 2;
      } else if (avgSteps > 12000) {
        diastolic -= 3;
      }
    }

    // Sleep impact
    if (avgSleep > 0) {
      if (avgSleep < 6) {
        diastolic += 4;
      } else if (avgSleep < 7) {
        diastolic += 2;
      }
    }

    // Active minutes impact
    if (avgActiveMinutes >= 30) {
      diastolic -= 2;
    }

    // Age impact (less pronounced than systolic)
    if (age != null && age > 30) {
      diastolic += (age - 30) * 0.3;
    }

    // BMI impact
    if (bmi != null) {
      if (bmi > 25 && bmi < 30) {
        diastolic += 3;
      } else if (bmi >= 30) {
        diastolic += 8;
      }
    }

    // Smoking impact
    if (isSmoker == true) {
      diastolic += 5;
    }

    // High cholesterol impact
    if (hasHighCholesterol == true) {
      diastolic += 4;
    }

    // Use historical data if available
    if (historicalDiastolic != null) {
      diastolic = (historicalDiastolic * 0.6) + (diastolic * 0.4);
    }

    // Ensure realistic range (50-120 mmHg)
    diastolic = diastolic.clamp(50.0, 120.0);

    // Ensure diastolic < systolic (with margin)
    if (diastolic >= predictedSystolic - 20) {
      diastolic = predictedSystolic - 25;
    }

    return diastolic;
  }

  /// Calculate average from health data points
  static double _calculateAverage(List<HealthDataPoint> data) {
    if (data.isEmpty) return 0.0;

    final sum = data.fold<double>(0.0, (sum, point) => sum + point.value);
    return sum / data.length;
  }

  /// Calculate confidence score based on data availability
  static double _calculateConfidence(
    int heartRatePoints,
    int stepsPoints,
    int sleepPoints,
    bool hasAge,
    bool hasBMI,
    bool hasHistoricalBP,
  ) {
    double confidence = 0.0;

    // Data availability contributes to confidence
    if (heartRatePoints > 0) confidence += 0.15;
    if (heartRatePoints > 7) confidence += 0.10; // Week of data
    if (heartRatePoints > 30) confidence += 0.05; // Month of data

    if (stepsPoints > 0) confidence += 0.15;
    if (stepsPoints > 7) confidence += 0.10;

    if (sleepPoints > 0) confidence += 0.10;
    if (sleepPoints > 7) confidence += 0.05;

    // Profile data contributes
    if (hasAge) confidence += 0.10;
    if (hasBMI) confidence += 0.10;

    // Historical BP data is most valuable
    if (hasHistoricalBP) confidence += 0.20;

    return confidence.clamp(0.0, 1.0);
  }

  /// Get list of data sources used in prediction
  static List<String> _getDataSources(Map<String, List<HealthDataPoint>> data) {
    final sources = <String>[];

    if (data['heart_rate']?.isNotEmpty ?? false) sources.add('Heart Rate');
    if (data['resting_heart_rate']?.isNotEmpty ?? false) {
      sources.add('Resting HR');
    }
    if (data['steps']?.isNotEmpty ?? false) sources.add('Steps');
    if (data['sleep_hours']?.isNotEmpty ?? false) sources.add('Sleep');
    if (data['active_minutes']?.isNotEmpty ?? false) sources.add('Activity');

    return sources.isNotEmpty ? sources : ['Limited Data'];
  }

  /// Generate BP data points from prediction for time series
  static List<HealthDataPoint> generateBPDataPoints({
    required int systolic,
    required int diastolic,
    required DateTime timestamp,
    int numberOfDays = 7,
    bool useSystolic = true,
  }) {
    final dataPoints = <HealthDataPoint>[];
    final baseValue = useSystolic ? systolic : diastolic;
    final variationRange =
        useSystolic ? 6 : 4; // ±3 mmHg for systolic, ±2 for diastolic

    // Generate historical predictions (going backwards in time)
    for (int i = 0; i < numberOfDays; i++) {
      final date = timestamp.subtract(Duration(days: i));

      // Add slight variation to make it realistic
      final random = math.Random(date.millisecondsSinceEpoch);
      final variation = random.nextInt(variationRange) - (variationRange ~/ 2);

      dataPoints.add(
        HealthDataPoint(
          value: (baseValue + variation).toDouble(),
          timestamp: date,
        ),
      );
    }

    return dataPoints.reversed.toList();
  }

  /// Create summary for BP prediction
  static Map<String, dynamic> createBPSummary({
    required int systolic,
    required int diastolic,
    required double confidence,
  }) {
    // Classify BP
    String category;
    String description;
    String recommendation;

    if (systolic < 120 && diastolic < 80) {
      category = 'Normal';
      description = 'Your blood pressure is in the healthy range';
      recommendation = 'Maintain your healthy lifestyle';
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      category = 'Elevated';
      description = 'Your blood pressure is higher than normal';
      recommendation = 'Focus on lifestyle changes to prevent hypertension';
    } else if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) {
      category = 'Stage 1 Hypertension';
      description = 'High blood pressure requiring attention';
      recommendation = 'Consult with a healthcare provider';
    } else if (systolic >= 140 || diastolic >= 90) {
      category = 'Stage 2 Hypertension';
      description = 'Significantly elevated blood pressure';
      recommendation = 'Seek medical attention promptly';
    } else {
      category = 'Hypotension';
      description = 'Low blood pressure';
      recommendation = 'Monitor and consult if you have symptoms';
    }

    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'confidence': confidence,
      'category': category,
      'description': description,
      'recommendation': recommendation,
      'timestamp': DateTime.now(),
      'isPredicted': true,
    };
  }
}
