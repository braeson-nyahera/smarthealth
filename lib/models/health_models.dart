import 'package:flutter/material.dart';

// Enums
enum ValueType { integer, decimal, string }

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
