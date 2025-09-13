import 'package:flutter/material.dart';
import '../models/health_models.dart';

class HealthMetrics {
  static final Map<String, HealthMetric> metricsToTrack = {
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

  static const List<String> googleFitScopes = [
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
  ];

  static const Map<String, IconData> categoryIcons = {
    'Activity': Icons.directions_run,
    'Heart': Icons.favorite,
    'Sleep': Icons.bedtime,
    'Body': Icons.monitor_weight,
    'Vitals': Icons.monitor_heart,
    'Wellness': Icons.psychology,
  };
}
