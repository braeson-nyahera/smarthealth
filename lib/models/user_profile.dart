import 'package:flutter/material.dart';

enum DiabetesState { none, diabetic }

enum Gender { male, female }

class UserProfile {
  final int? age;
  final Gender? gender;
  final DiabetesState diabetesState;
  final double? weight; // in kg
  final double? height; // in cm
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.age,
    this.gender,
    this.diabetesState = DiabetesState.none,
    this.weight,
    this.height,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    int? age,
    Gender? gender,
    DiabetesState? diabetesState,
    double? weight,
    double? height,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      diabetesState: diabetesState ?? this.diabetesState,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Calculate BMI if height and weight are available
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  // Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';

    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal weight';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  // Get diabetes state display name
  String get diabetesStateDisplay {
    switch (diabetesState) {
      case DiabetesState.none:
        return 'Not diabetic';
      case DiabetesState.diabetic:
        return 'Diabetic';
    }
  }

  // Get gender display name
  String get genderDisplay {
    if (gender == null) return 'Not specified';
    return gender == Gender.male ? 'Male' : 'Female';
  }

  // Get gender value for ML model (0 = male, 1 = female)
  int? get genderValue {
    if (gender == null) return null;
    return gender == Gender.male ? 0 : 1;
  }

  // Get diabetes state color
  Color get diabetesStateColor {
    switch (diabetesState) {
      case DiabetesState.none:
        return Colors.green;
      case DiabetesState.diabetic:
        return Colors.red;
    }
  }

  // Check if profile is complete
  bool get isComplete {
    return age != null && gender != null && weight != null && height != null;
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'gender': gender?.index,
      'diabetesState': diabetesState.index,
      'weight': weight,
      'height': height,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      age: map['age']?.toInt(),
      gender: map['gender'] != null ? Gender.values[map['gender']] : null,
      diabetesState: DiabetesState.values[map['diabetesState'] ?? 0],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'])
              : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(age: $age, gender: $genderDisplay, diabetesState: $diabetesState, weight: $weight, height: $height, bmi: ${bmi?.toStringAsFixed(1)})';
  }
}
