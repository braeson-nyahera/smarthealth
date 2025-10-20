import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/hypertension_risk_models.dart';

/// Time series prediction service for hypertension risk
/// Uses statistical analysis and pattern recognition
class HypertensionPredictionService {
  /// Predict hypertension risk based on time series data
  static Future<HypertensionPrediction> predictRisk({
    required ModelTrainingData trainingData,
  }) async {
    debugPrint('🔮 Starting hypertension risk prediction...');

    // Check if we have enough data
    if (!trainingData.hasEnoughData) {
      debugPrint('⚠️ Insufficient data for prediction');
      return _createInsufficientDataPrediction();
    }

    // Extract features from time series data
    final features = _extractFeatures(trainingData);
    debugPrint('📊 Extracted ${features.length} features');

    // Calculate risk score
    final riskScore = _calculateRiskScore(features, trainingData.riskFactors);
    debugPrint('📈 Calculated risk score: ${riskScore.toStringAsFixed(1)}');

    // Determine risk level
    final riskLevel = _determineRiskLevel(riskScore);

    // Calculate confidence based on data quality and quantity
    final confidence = _calculateConfidence(trainingData);

    // Identify contributing factors
    final contributingFactors = _identifyContributingFactors(
      features,
      trainingData.riskFactors,
    );

    // Generate recommendations
    final recommendations = _generateRecommendations(
      riskLevel,
      features,
      trainingData.riskFactors,
    );

    // Project future trends
    final futureProjections = _projectFutureTrends(
      trainingData.bloodPressureData,
    );

    return HypertensionPrediction(
      riskLevel: riskLevel,
      riskScore: riskScore,
      confidence: confidence,
      predictionDate: DateTime.now(),
      contributingFactors: contributingFactors,
      recommendations: recommendations,
      futureProjections: futureProjections,
    );
  }

  /// Extract statistical features from time series data
  static Map<String, double> _extractFeatures(ModelTrainingData data) {
    final features = <String, double>{};

    // Blood Pressure Features
    if (data.bloodPressureData.isNotEmpty) {
      final bpValues = data.bloodPressureData.map((d) => d.value).toList();
      features['bp_mean'] = _calculateMean(bpValues);
      features['bp_std'] = _calculateStdDev(bpValues);
      features['bp_trend'] = _calculateTrend(bpValues);
      features['bp_max'] = bpValues.reduce(max);
      features['bp_min'] = bpValues.reduce(min);
      features['bp_variability'] = _calculateVariability(bpValues);
      features['bp_spike_frequency'] = _detectSpikes(bpValues);
    }

    // Heart Rate Features
    if (data.heartRateData.isNotEmpty) {
      final hrValues = data.heartRateData.map((d) => d.value).toList();
      features['hr_mean'] = _calculateMean(hrValues);
      features['hr_std'] = _calculateStdDev(hrValues);
      features['hr_resting'] = _calculateRestingHeartRate(hrValues);
      features['hr_variability'] = _calculateVariability(hrValues);
    }

    // Activity Features
    if (data.activityData.isNotEmpty) {
      final activityValues = data.activityData.map((d) => d.value).toList();
      features['activity_mean'] = _calculateMean(activityValues);
      features['activity_trend'] = _calculateTrend(activityValues);
      features['sedentary_days'] = _countSedentaryDays(activityValues);
    }

    // Sleep Features
    if (data.sleepData.isNotEmpty) {
      final sleepValues = data.sleepData.map((d) => d.value).toList();
      features['sleep_mean'] = _calculateMean(sleepValues);
      features['sleep_consistency'] = _calculateConsistency(sleepValues);
      features['poor_sleep_frequency'] = _countPoorSleepDays(sleepValues);
    }

    return features;
  }

  /// Calculate overall risk score (0-100)
  static double _calculateRiskScore(
    Map<String, double> features,
    RiskFactors riskFactors,
  ) {
    double score = 0.0;

    // Base risk from demographic factors (0-40 points)
    score += riskFactors.calculateRiskScore() * 0.4;

    // Blood pressure patterns (0-30 points)
    if (features.containsKey('bp_mean')) {
      final bpMean = features['bp_mean']!;
      if (bpMean < 120) {
        score += 0;
      } else if (bpMean < 130) {
        score += 5;
      } else if (bpMean < 140) {
        score += 15;
      } else if (bpMean < 160) {
        score += 25;
      } else {
        score += 30;
      }
    }

    // Blood pressure trend (0-15 points)
    if (features.containsKey('bp_trend')) {
      final trend = features['bp_trend']!;
      if (trend > 0.5) {
        score += 15; // Increasing trend is concerning
      } else if (trend > 0) {
        score += 5;
      }
    }

    // Blood pressure variability (0-10 points)
    if (features.containsKey('bp_variability')) {
      final variability = features['bp_variability']!;
      if (variability > 20) {
        score += 10;
      } else if (variability > 10) {
        score += 5;
      }
    }

    // Heart rate factors (0-10 points)
    if (features.containsKey('hr_resting')) {
      final restingHR = features['hr_resting']!;
      if (restingHR > 80) {
        score += 10;
      } else if (restingHR > 70) {
        score += 5;
      }
    }

    // Activity level (0-10 points)
    if (features.containsKey('sedentary_days')) {
      final sedentaryDays = features['sedentary_days']!;
      if (sedentaryDays > 5) {
        score += 10;
      } else if (sedentaryDays > 3) {
        score += 5;
      }
    }

    // Sleep quality (0-5 points)
    if (features.containsKey('poor_sleep_frequency')) {
      final poorSleepDays = features['poor_sleep_frequency']!;
      if (poorSleepDays > 3) {
        score += 5;
      }
    }

    return score.clamp(0, 100);
  }

  /// Determine risk level from score
  static HypertensionRiskLevel _determineRiskLevel(double score) {
    if (score < 25) {
      return HypertensionRiskLevel.low;
    } else if (score < 50) {
      return HypertensionRiskLevel.moderate;
    } else if (score < 75) {
      return HypertensionRiskLevel.high;
    } else {
      return HypertensionRiskLevel.veryHigh;
    }
  }

  /// Calculate prediction confidence based on data quality
  static double _calculateConfidence(ModelTrainingData data) {
    double confidence = 0.0;

    // Data quantity factor (0-0.4)
    final dataPoints = data.totalDataPoints;
    if (dataPoints < 30) {
      confidence += 0.1;
    } else if (dataPoints < 100) {
      confidence += 0.2;
    } else if (dataPoints < 300) {
      confidence += 0.3;
    } else {
      confidence += 0.4;
    }

    // Data diversity factor (0-0.3)
    int dataTypeCount = 0;
    if (data.bloodPressureData.isNotEmpty) dataTypeCount++;
    if (data.heartRateData.isNotEmpty) dataTypeCount++;
    if (data.activityData.isNotEmpty) dataTypeCount++;
    if (data.sleepData.isNotEmpty) dataTypeCount++;
    confidence += (dataTypeCount / 4) * 0.3;

    // Data recency factor (0-0.3)
    final latestBP =
        data.bloodPressureData.isNotEmpty
            ? data.bloodPressureData.last.timestamp
            : DateTime.now().subtract(Duration(days: 365));
    final daysSinceLastReading = DateTime.now().difference(latestBP).inDays;
    if (daysSinceLastReading < 1) {
      confidence += 0.3;
    } else if (daysSinceLastReading < 7) {
      confidence += 0.2;
    } else if (daysSinceLastReading < 30) {
      confidence += 0.1;
    }

    return confidence.clamp(0, 1);
  }

  /// Identify key contributing factors
  static List<String> _identifyContributingFactors(
    Map<String, double> features,
    RiskFactors riskFactors,
  ) {
    final factors = <String>[];

    // Check blood pressure
    if (features['bp_mean'] != null && features['bp_mean']! >= 130) {
      factors.add(
        'Elevated average blood pressure (${features['bp_mean']!.toStringAsFixed(0)} mmHg)',
      );
    }

    // Check BP trend
    if (features['bp_trend'] != null && features['bp_trend']! > 0.3) {
      factors.add('Increasing blood pressure trend');
    }

    // Check variability
    if (features['bp_variability'] != null &&
        features['bp_variability']! > 15) {
      factors.add('High blood pressure variability');
    }

    // Check age
    if (riskFactors.age >= 60) {
      factors.add('Age factor (${riskFactors.age} years)');
    }

    // Check BMI
    if (riskFactors.bmi >= 30) {
      factors.add('Obesity (BMI: ${riskFactors.bmi.toStringAsFixed(1)})');
    }

    // Check lifestyle factors
    if (riskFactors.isSmoker) {
      factors.add('Smoking habit');
    }

    if (riskFactors.hasDiabetes) {
      factors.add('Diabetes condition');
    }

    // Check activity
    if (features['sedentary_days'] != null && features['sedentary_days']! > 4) {
      factors.add(
        'Low physical activity (${features['sedentary_days']!.toStringAsFixed(0)} sedentary days/week)',
      );
    }

    // Check sleep
    if (features['poor_sleep_frequency'] != null &&
        features['poor_sleep_frequency']! > 2) {
      factors.add(
        'Poor sleep quality (${features['poor_sleep_frequency']!.toStringAsFixed(0)} nights/week)',
      );
    }

    return factors;
  }

  /// Generate personalized recommendations
  static List<String> _generateRecommendations(
    HypertensionRiskLevel riskLevel,
    Map<String, double> features,
    RiskFactors riskFactors,
  ) {
    final recommendations = <String>[];

    // Critical recommendation for high risk
    if (riskLevel == HypertensionRiskLevel.high ||
        riskLevel == HypertensionRiskLevel.veryHigh) {
      recommendations.add('⚠️ Consult a healthcare provider immediately');
      recommendations.add('📋 Schedule regular blood pressure monitoring');
    }

    // Blood pressure specific
    if (features['bp_mean'] != null && features['bp_mean']! >= 130) {
      recommendations.add(
        '🩺 Monitor blood pressure daily at consistent times',
      );
      recommendations.add('🧂 Reduce sodium intake (<2,300mg/day)');
    }

    // Activity recommendations
    if (features['sedentary_days'] != null && features['sedentary_days']! > 3) {
      recommendations.add(
        '🏃 Aim for 150 minutes of moderate exercise per week',
      );
      recommendations.add('🚶 Take regular breaks from sitting every hour');
    }

    // Weight management
    if (riskFactors.bmi >= 25) {
      recommendations.add('⚖️ Work towards achieving healthy BMI (18.5-24.9)');
      recommendations.add('🥗 Follow DASH diet for blood pressure management');
    }

    // Sleep recommendations
    if (features['poor_sleep_frequency'] != null &&
        features['poor_sleep_frequency']! > 2) {
      recommendations.add('😴 Maintain consistent sleep schedule (7-9 hours)');
      recommendations.add('🌙 Create relaxing bedtime routine');
    }

    // Stress management
    if (riskFactors.averageStressLevel > 6) {
      recommendations.add('🧘 Practice stress reduction (meditation, yoga)');
      recommendations.add('🎵 Engage in relaxing activities daily');
    }

    // Lifestyle modifications
    if (riskFactors.isSmoker) {
      recommendations.add('🚭 Quit smoking - seek cessation support');
    }

    // General healthy habits
    recommendations.add('💧 Stay hydrated (8 glasses of water daily)');
    recommendations.add('☕ Limit caffeine and alcohol consumption');

    return recommendations.take(8).toList(); // Return top 8 recommendations
  }

  /// Project future blood pressure trends
  static Map<String, double> _projectFutureTrends(
    List<TimeSeriesDataPoint> bpData,
  ) {
    if (bpData.length < 7) {
      return {'7_days': 0, '30_days': 0, '90_days': 0};
    }

    // Simple linear regression for trend projection
    final values = bpData.map((d) => d.value).toList();
    final trend = _calculateTrend(values);
    final currentAvg = _calculateMean(values);

    return {
      '7_days': currentAvg + (trend * 7),
      '30_days': currentAvg + (trend * 30),
      '90_days': currentAvg + (trend * 90),
    };
  }

  /// Create prediction for insufficient data case
  static HypertensionPrediction _createInsufficientDataPrediction() {
    return HypertensionPrediction(
      riskLevel: HypertensionRiskLevel.moderate,
      riskScore: 50.0,
      confidence: 0.2,
      predictionDate: DateTime.now(),
      contributingFactors: ['Insufficient data for accurate prediction'],
      recommendations: [
        '📊 Continue tracking blood pressure daily',
        '❤️ Monitor heart rate regularly',
        '🏃 Track daily physical activity',
        '😴 Record sleep patterns',
        '📈 Collect at least 2 weeks of data for better predictions',
      ],
      futureProjections: {},
    );
  }

  // Statistical helper methods

  static double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _calculateMean(values);
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  static double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;

    // Simple linear regression slope
    final n = values.length;
    final xMean = (n - 1) / 2;
    final yMean = _calculateMean(values);

    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      numerator += (i - xMean) * (values[i] - yMean);
      denominator += pow(i - xMean, 2);
    }

    return denominator != 0 ? numerator / denominator : 0;
  }

  static double _calculateVariability(List<double> values) {
    if (values.length < 2) return 0;
    return _calculateStdDev(values);
  }

  static double _detectSpikes(List<double> values) {
    if (values.length < 3) return 0;

    final mean = _calculateMean(values);
    final stdDev = _calculateStdDev(values);
    final threshold = mean + (2 * stdDev);

    return values.where((v) => v > threshold).length.toDouble();
  }

  static double _calculateRestingHeartRate(List<double> hrValues) {
    if (hrValues.isEmpty) return 0;
    final sorted = List<double>.from(hrValues)..sort();
    return _calculateMean(sorted.take((sorted.length * 0.2).ceil()).toList());
  }

  static double _countSedentaryDays(List<double> activityValues) {
    if (activityValues.isEmpty) return 0;
    return activityValues.where((v) => v < 5000).length.toDouble();
  }

  static double _calculateConsistency(List<double> values) {
    if (values.isEmpty) return 0;
    final stdDev = _calculateStdDev(values);
    final mean = _calculateMean(values);
    return mean != 0 ? 1 - (stdDev / mean).clamp(0, 1) : 0;
  }

  static double _countPoorSleepDays(List<double> sleepValues) {
    if (sleepValues.isEmpty) return 0;
    return sleepValues.where((v) => v < 6 || v > 9).length.toDouble();
  }
}
