import 'package:flutter/material.dart';

/// Hypertension risk level classification
enum HypertensionRiskLevel {
  low,
  moderate,
  high,
  veryHigh;

  String get label {
    switch (this) {
      case HypertensionRiskLevel.low:
        return 'Low Risk';
      case HypertensionRiskLevel.moderate:
        return 'Moderate Risk';
      case HypertensionRiskLevel.high:
        return 'High Risk';
      case HypertensionRiskLevel.veryHigh:
        return 'Very High Risk';
    }
  }

  Color get color {
    switch (this) {
      case HypertensionRiskLevel.low:
        return Colors.green;
      case HypertensionRiskLevel.moderate:
        return Colors.orange;
      case HypertensionRiskLevel.high:
        return Colors.deepOrange;
      case HypertensionRiskLevel.veryHigh:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case HypertensionRiskLevel.low:
        return Icons.check_circle;
      case HypertensionRiskLevel.moderate:
        return Icons.warning_amber;
      case HypertensionRiskLevel.high:
        return Icons.error;
      case HypertensionRiskLevel.veryHigh:
        return Icons.dangerous;
    }
  }
}

/// Blood pressure classification based on AHA guidelines
enum BloodPressureCategory {
  normal,
  elevated,
  stage1Hypertension,
  stage2Hypertension,
  hypertensiveCrisis;

  String get label {
    switch (this) {
      case BloodPressureCategory.normal:
        return 'Normal';
      case BloodPressureCategory.elevated:
        return 'Elevated';
      case BloodPressureCategory.stage1Hypertension:
        return 'Stage 1 Hypertension';
      case BloodPressureCategory.stage2Hypertension:
        return 'Stage 2 Hypertension';
      case BloodPressureCategory.hypertensiveCrisis:
        return 'Hypertensive Crisis';
    }
  }

  String get description {
    switch (this) {
      case BloodPressureCategory.normal:
        return 'Your blood pressure is in the healthy range';
      case BloodPressureCategory.elevated:
        return 'Your blood pressure is higher than normal';
      case BloodPressureCategory.stage1Hypertension:
        return 'Lifestyle changes recommended';
      case BloodPressureCategory.stage2Hypertension:
        return 'Medical consultation recommended';
      case BloodPressureCategory.hypertensiveCrisis:
        return 'Seek immediate medical attention';
    }
  }
}

/// Time series data point for prediction
class TimeSeriesDataPoint {
  final DateTime timestamp;
  final double value;
  final String metric;

  TimeSeriesDataPoint({
    required this.timestamp,
    required this.value,
    required this.metric,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'value': value,
    'metric': metric,
  };

  factory TimeSeriesDataPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      value: json['value'],
      metric: json['metric'],
    );
  }
}

/// Hypertension risk factors
class RiskFactors {
  final int age;
  final bool isSmoker;
  final bool hasDiabetes;
  final bool hasHighCholesterol;
  final bool hasFamilyHistory;
  final double bmi;
  final bool isPhysicallyActive;
  final double averageStressLevel; // 0-10 scale

  RiskFactors({
    required this.age,
    this.isSmoker = false,
    this.hasDiabetes = false,
    this.hasHighCholesterol = false,
    this.hasFamilyHistory = false,
    required this.bmi,
    this.isPhysicallyActive = true,
    this.averageStressLevel = 5.0,
  });

  /// Calculate risk score based on factors (0-100 scale)
  double calculateRiskScore() {
    double score = 0.0;

    // Age factor (0-25 points)
    if (age < 40) {
      score += 0;
    } else if (age < 50) {
      score += 5;
    } else if (age < 60) {
      score += 10;
    } else if (age < 70) {
      score += 15;
    } else {
      score += 25;
    }

    // Smoking (0-20 points)
    if (isSmoker) score += 20;

    // Diabetes (0-15 points)
    if (hasDiabetes) score += 15;

    // High cholesterol (0-10 points)
    if (hasHighCholesterol) score += 10;

    // Family history (0-10 points)
    if (hasFamilyHistory) score += 10;

    // BMI factor (0-15 points)
    if (bmi < 25) {
      score += 0;
    } else if (bmi < 30) {
      score += 5;
    } else if (bmi < 35) {
      score += 10;
    } else {
      score += 15;
    }

    // Physical activity (0-5 points)
    if (!isPhysicallyActive) score += 5;

    // Stress level (0-5 points)
    score += (averageStressLevel / 10) * 5;

    return score.clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
    'age': age,
    'isSmoker': isSmoker,
    'hasDiabetes': hasDiabetes,
    'hasHighCholesterol': hasHighCholesterol,
    'hasFamilyHistory': hasFamilyHistory,
    'bmi': bmi,
    'isPhysicallyActive': isPhysicallyActive,
    'averageStressLevel': averageStressLevel,
  };
}

/// Prediction result from the time series model
class HypertensionPrediction {
  final HypertensionRiskLevel riskLevel;
  final double riskScore; // 0-100
  final double confidence; // 0-1
  final DateTime predictionDate;
  final List<String> contributingFactors;
  final List<String> recommendations;
  final Map<String, double> futureProjections; // Next 7/30/90 days
  final String method; // 'ml_model' or 'rule_based' or 'clinical_override'
  final String? clinicalReason; // Clinical reasoning for the prediction

  HypertensionPrediction({
    required this.riskLevel,
    required this.riskScore,
    required this.confidence,
    required this.predictionDate,
    required this.contributingFactors,
    required this.recommendations,
    required this.futureProjections,
    this.method = 'ml_model',
    this.clinicalReason,
  });

  /// Get model health status
  String get modelHealth {
    if (method == 'clinical_override') {
      return 'Clinical Validation';
    }
    if (method == 'ml_model') {
      if (confidence >= 0.85) {
        return 'Excellent';
      } else if (confidence >= 0.70) {
        return 'Good';
      } else {
        return 'Fair';
      }
    } else {
      return 'Rule-Based Fallback';
    }
  }

  /// Get model health color
  Color get modelHealthColor {
    if (method == 'clinical_override') {
      return Colors.purple;
    }
    if (method == 'rule_based') {
      return Colors.amber;
    }
    if (confidence >= 0.85) {
      return Colors.green;
    } else if (confidence >= 0.70) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  Map<String, dynamic> toJson() => {
    'riskLevel': riskLevel.name,
    'riskScore': riskScore,
    'confidence': confidence,
    'predictionDate': predictionDate.toIso8601String(),
    'contributingFactors': contributingFactors,
    'recommendations': recommendations,
    'futureProjections': futureProjections,
    'method': method,
    'clinicalReason': clinicalReason,
  };
}

/// Blood pressure reading with classification
class BloodPressureReading {
  final DateTime timestamp;
  final int systolic;
  final int diastolic;
  final int? heartRate;

  BloodPressureReading({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    this.heartRate,
  });

  /// Classify blood pressure based on AHA guidelines
  BloodPressureCategory get category {
    if (systolic < 120 && diastolic < 80) {
      return BloodPressureCategory.normal;
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return BloodPressureCategory.elevated;
    } else if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) {
      return BloodPressureCategory.stage1Hypertension;
    } else if (systolic >= 140 || diastolic >= 90) {
      return BloodPressureCategory.stage2Hypertension;
    } else if (systolic > 180 || diastolic > 120) {
      return BloodPressureCategory.hypertensiveCrisis;
    }
    return BloodPressureCategory.normal;
  }

  bool get isHypertensive =>
      category == BloodPressureCategory.stage1Hypertension ||
      category == BloodPressureCategory.stage2Hypertension ||
      category == BloodPressureCategory.hypertensiveCrisis;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'systolic': systolic,
    'diastolic': diastolic,
    'heartRate': heartRate,
  };
}

/// Training data for the model
class ModelTrainingData {
  final List<TimeSeriesDataPoint> bloodPressureData;
  final List<TimeSeriesDataPoint> heartRateData;
  final List<TimeSeriesDataPoint> activityData;
  final List<TimeSeriesDataPoint> sleepData;
  final RiskFactors riskFactors;

  ModelTrainingData({
    required this.bloodPressureData,
    required this.heartRateData,
    required this.activityData,
    required this.sleepData,
    required this.riskFactors,
  });

  /// Check if there's enough data for reliable prediction
  /// 
  /// Minimal requirements for real-time predictions (runs every 3 hours):
  /// - Heart rate: at least 1 data point (required)
  /// - Blood pressure OR activity: at least 1 data point (at least one required)
  /// 
  /// This allows immediate predictions as soon as data is available,
  /// rather than waiting for days of accumulated data.
  bool get hasEnoughData {
    final hasHeartRate = heartRateData.isNotEmpty;
    final hasBloodPressure = bloodPressureData.isNotEmpty;
    final hasActivity = activityData.isNotEmpty;
    
    // Must have heart rate AND at least one other metric for basic prediction
    return hasHeartRate && (hasBloodPressure || hasActivity);
  }

  int get totalDataPoints =>
      bloodPressureData.length +
      heartRateData.length +
      activityData.length +
      sleepData.length;
}
