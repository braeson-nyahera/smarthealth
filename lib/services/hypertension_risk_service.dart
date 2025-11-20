import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_profile.dart';

/// Service for predicting hypertension risk using the ML model
///
/// Model inputs:
/// - gender: 0 = male, 1 = female
/// - age: integer
/// - diabetes: 0 = none, 1 = diabetic
/// - systolic_bp: systolic blood pressure (mmHg)
/// - diastolic_bp: diastolic blood pressure (mmHg)
/// - bmi: Body Mass Index
/// - heart_rate: beats per minute
///
/// Model output:
/// - 0 = low risk
/// - 1 = high risk
class HypertensionRiskService {
  /// Predict hypertension risk
  ///
  /// Returns a map with:
  /// - 'risk_level': 0 (low risk) or 1 (high risk)
  /// - 'risk_label': 'Low Risk' or 'High Risk'
  /// - 'confidence': percentage (if available from model)
  static Future<Map<String, dynamic>> predictRisk({
    required UserProfile profile,
    required double systolicBP,
    required double diastolicBP,
    required double heartRate,
  }) async {
    // Validate inputs
    if (profile.age == null) {
      throw Exception('Age is required for risk prediction');
    }
    if (profile.gender == null) {
      throw Exception('Gender is required for risk prediction');
    }
    if (profile.bmi == null) {
      throw Exception(
        'BMI is required for risk prediction (need height and weight)',
      );
    }

    // Prepare model inputs
    final int genderValue = profile.genderValue!; // 0 = male, 1 = female
    final int age = profile.age!;
    final int diabetesValue =
        profile.diabetesState == DiabetesState.diabetic ? 1 : 0;
    final double bmi = profile.bmi!;

    debugPrint('[HypertensionRisk] Predicting with:');
    debugPrint('  Gender: $genderValue (${profile.genderDisplay})');
    debugPrint('  Age: $age');
    debugPrint('  Diabetes: $diabetesValue (${profile.diabetesStateDisplay})');
    debugPrint('  Systolic BP: $systolicBP');
    debugPrint('  Diastolic BP: $diastolicBP');
    debugPrint('  BMI: ${bmi.toStringAsFixed(1)}');
    debugPrint('  Heart Rate: $heartRate');

    try {
      // Option 1: Call local Python server (if running)
      final prediction = await _callPythonModel(
        gender: genderValue,
        age: age,
        diabetes: diabetesValue,
        systolicBP: systolicBP,
        diastolicBP: diastolicBP,
        bmi: bmi,
        heartRate: heartRate,
      );

      return prediction;
    } catch (e) {
      debugPrint(
        '[HypertensionRisk] Python server not available, using rule-based fallback: $e',
      );

      // Option 2: Fallback to rule-based prediction
      return _ruleBasedPrediction(
        gender: genderValue,
        age: age,
        diabetes: diabetesValue,
        systolicBP: systolicBP,
        diastolicBP: diastolicBP,
        bmi: bmi,
        heartRate: heartRate,
      );
    }
  }

  /// Call FastAPI server running the ML model
  ///
  /// Server URL: http://56.228.80.187:1234/
  /// The API is deployed and running on a remote server.
  static Future<Map<String, dynamic>> _callPythonModel({
    required int gender,
    required int age,
    required int diabetes,
    required double systolicBP,
    required double diastolicBP,
    required double bmi,
    required double heartRate,
  }) async {
    const String serverUrl = 'http://56.228.80.187:1234/predict';

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(serverUrl));
      request.headers.set('Content-Type', 'application/json');

      // Request body matches the FastAPI schema:
      // male (int), age (int), diabetes (int), sysBP (float), diaBP (float), BMI (float), heartRate (int)
      final body = jsonEncode({
        'male': gender,
        'age': age,
        'diabetes': diabetes,
        'sysBP': systolicBP,
        'diaBP': diastolicBP,
        'BMI': bmi,
        'heartRate': heartRate,
      });

      request.write(body);
      request.contentLength = utf8.encode(body).length;

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        debugPrint(
          '[HypertensionRisk] Model prediction: ${data['risk_label']}',
        );
        return {
          'risk_level': data['risk'],
          'risk_label': data['risk_label'],
          'confidence': (data['probability'] as num).toDouble(),
          'method': 'ml_model',
          'clinical_reason': data['clinical_reason'] ?? 'Assessment complete',
          'recommendations': data['recommendations'] ?? '',
          'model_used': data['model_used'] ?? 'scikit-learn',
        };
      } else {
        throw Exception(
          'Server returned ${response.statusCode}: $responseBody',
        );
      }
    } finally {
      client.close();
    }
  }

  /// Rule-based fallback prediction using medical guidelines
  ///
  /// This is used when the ML model server is not available.
  /// Based on AHA/ACC guidelines for hypertension risk factors.
  static Map<String, dynamic> _ruleBasedPrediction({
    required int gender,
    required int age,
    required int diabetes,
    required double systolicBP,
    required double diastolicBP,
    required double bmi,
    required double heartRate,
  }) {
    int riskScore = 0;

    // Age risk (higher age = higher risk)
    if (age >= 65) {
      riskScore += 3;
    } else if (age >= 45) {
      riskScore += 2;
    } else if (age >= 35) {
      riskScore += 1;
    }

    // Blood pressure risk (AHA/ACC guidelines)
    // Stage 2 Hypertension: ≥140/90
    if (systolicBP >= 140 || diastolicBP >= 90) {
      riskScore += 4;
    }
    // Stage 1 Hypertension: 130-139/80-89
    else if (systolicBP >= 130 || diastolicBP >= 80) {
      riskScore += 3;
    }
    // Elevated: 120-129/<80
    else if (systolicBP >= 120 && diastolicBP < 80) {
      riskScore += 2;
    }

    // BMI risk (obesity is a major risk factor)
    if (bmi >= 35) {
      riskScore += 3; // Severe obesity
    } else if (bmi >= 30) {
      riskScore += 2; // Obesity
    } else if (bmi >= 25) {
      riskScore += 1; // Overweight
    }

    // Diabetes risk (major risk factor)
    if (diabetes == 1) {
      riskScore += 3;
    }

    // Heart rate risk (tachycardia can indicate issues)
    if (heartRate > 100) {
      riskScore += 2;
    } else if (heartRate > 90) {
      riskScore += 1;
    }

    // Gender risk (males typically have slightly higher risk)
    if (gender == 0) {
      // male
      riskScore += 1;
    }

    // Determine risk level
    // High risk threshold: score >= 7
    final bool isHighRisk = riskScore >= 7;
    final int riskLevel = isHighRisk ? 1 : 0;
    final String riskLabel = isHighRisk ? 'High Risk' : 'Low Risk';

    // Calculate confidence based on how clear the risk is
    double confidence = 0.0;
    if (riskScore >= 10) {
      confidence = 0.95; // Very high risk
    } else if (riskScore >= 7) {
      confidence = 0.80; // High risk
    } else if (riskScore >= 4) {
      confidence = 0.70; // Moderate (low risk)
    } else {
      confidence = 0.85; // Low risk
    }

    debugPrint('[HypertensionRisk] Rule-based prediction:');
    debugPrint('  Risk Score: $riskScore');
    debugPrint('  Risk Level: $riskLabel');
    debugPrint('  Confidence: ${(confidence * 100).toStringAsFixed(0)}%');

    return {
      'risk_level': riskLevel,
      'risk_label': riskLabel,
      'confidence': confidence,
      'risk_score': riskScore,
      'method': 'rule_based',
    };
  }

  /// Get risk color based on risk level
  static Color getRiskColor(int riskLevel) {
    return riskLevel == 1 ? Colors.red.shade600 : Colors.green.shade600;
  }

  /// Get risk icon based on risk level
  static IconData getRiskIcon(int riskLevel) {
    return riskLevel == 1 ? Icons.warning_rounded : Icons.check_circle_rounded;
  }

  /// Get risk message with recommendations
  static String getRiskMessage(int riskLevel, Map<String, dynamic> prediction) {
    if (riskLevel == 1) {
      return 'High risk of hypertension detected. Please consult with your healthcare provider for a comprehensive evaluation and personalized treatment plan.';
    } else {
      return 'Low risk of hypertension. Continue maintaining a healthy lifestyle with regular exercise, balanced diet, and routine check-ups.';
    }
  }

  /// Get actionable recommendations based on risk factors
  static List<String> getRecommendations(
    Map<String, dynamic> prediction, {
    required double systolicBP,
    required double diastolicBP,
    required double bmi,
    required int age,
  }) {
    final List<String> recommendations = [];

    // Blood pressure recommendations
    if (systolicBP >= 140 || diastolicBP >= 90) {
      recommendations.add(
        '🩺 Consult a doctor immediately - Stage 2 Hypertension detected',
      );
    } else if (systolicBP >= 130 || diastolicBP >= 80) {
      recommendations.add(
        '⚠️ Monitor blood pressure regularly - Stage 1 Hypertension',
      );
    } else if (systolicBP >= 120) {
      recommendations.add('📊 Track your blood pressure weekly');
    }

    // BMI recommendations
    if (bmi >= 30) {
      recommendations.add('🏃 Consider a weight management program');
      recommendations.add('🥗 Consult a nutritionist for a heart-healthy diet');
    } else if (bmi >= 25) {
      recommendations.add('💪 Increase physical activity to 150 min/week');
    }

    // Age-based recommendations
    if (age >= 45) {
      recommendations.add('📅 Schedule regular cardiac check-ups');
    }

    // General recommendations
    recommendations.add('🧂 Reduce sodium intake to <2,300mg/day');
    recommendations.add('🚭 Avoid smoking and limit alcohol consumption');
    recommendations.add('😴 Ensure 7-9 hours of quality sleep per night');
    recommendations.add('🧘 Practice stress management techniques');

    return recommendations;
  }
}
