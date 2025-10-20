import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/hypertension_risk_models.dart';
import 'hypertension_prediction_service.dart';
import 'health_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to automatically run hypertension predictions every 3 hours
class PredictionSchedulerService {
  static final PredictionSchedulerService _instance = PredictionSchedulerService._internal();
  factory PredictionSchedulerService() => _instance;
  PredictionSchedulerService._internal();

  Timer? _scheduledTimer;
  HypertensionPrediction? _latestPrediction;
  DateTime? _lastPredictionTime;
  bool _isRunning = false;

  // Callback to notify listeners of new predictions
  final List<Function(HypertensionPrediction)> _listeners = [];

  // Schedule interval: 3 hours
  static const Duration _scheduleInterval = Duration(hours: 3);
  
  // Minimum interval between predictions (prevent too frequent calls)
  static const Duration _minInterval = Duration(hours: 2, minutes: 45);

  /// Get the latest prediction
  HypertensionPrediction? get latestPrediction => _latestPrediction;

  /// Get the last prediction time
  DateTime? get lastPredictionTime => _lastPredictionTime;

  /// Check if scheduler is running
  bool get isRunning => _isRunning;

  /// Get time until next prediction
  Duration? get timeUntilNextPrediction {
    if (_lastPredictionTime == null) return null;
    final nextTime = _lastPredictionTime!.add(_scheduleInterval);
    final remaining = nextTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Add a listener for prediction updates
  void addListener(Function(HypertensionPrediction) callback) {
    _listeners.add(callback);
  }

  /// Remove a listener
  void removeListener(Function(HypertensionPrediction) callback) {
    _listeners.remove(callback);
  }

  /// Notify all listeners of a new prediction
  void _notifyListeners(HypertensionPrediction prediction) {
    for (final listener in _listeners) {
      try {
        listener(prediction);
      } catch (e) {
        debugPrint('Error notifying listener: $e');
      }
    }
  }

  /// Start the automatic prediction scheduler
  Future<void> startScheduler({
    required HealthDataService healthDataService,
    dynamic user,
    bool runImmediately = false,
  }) async {
    if (_isRunning) {
      debugPrint('⏰ Prediction scheduler already running');
      return;
    }

    debugPrint('🚀 Starting prediction scheduler (every 3 hours)');
    _isRunning = true;

    // Load last prediction from storage
    await _loadLastPrediction();

    // Run immediately if requested and enough time has passed
    if (runImmediately) {
      final canRunNow = _lastPredictionTime == null ||
          DateTime.now().difference(_lastPredictionTime!) >= _minInterval;
      
      if (canRunNow) {
        await _runPrediction(healthDataService, user);
      } else {
        debugPrint('⏳ Skipping immediate run - too soon since last prediction');
      }
    }

    // Schedule periodic predictions
    _scheduledTimer = Timer.periodic(_scheduleInterval, (_) async {
      final canRun = _lastPredictionTime == null ||
          DateTime.now().difference(_lastPredictionTime!) >= _minInterval;
      
      if (canRun) {
        await _runPrediction(healthDataService, user);
      } else {
        debugPrint('⏳ Skipping scheduled run - minimum interval not reached');
      }
    });

    debugPrint('✅ Prediction scheduler started successfully');
  }

  /// Stop the prediction scheduler
  void stopScheduler() {
    if (!_isRunning) return;

    debugPrint('🛑 Stopping prediction scheduler');
    _scheduledTimer?.cancel();
    _scheduledTimer = null;
    _isRunning = false;
    debugPrint('✅ Prediction scheduler stopped');
  }

  /// Manually trigger a prediction (bypasses interval check)
  Future<HypertensionPrediction?> runPredictionNow({
    required HealthDataService healthDataService,
    dynamic user,
  }) async {
    debugPrint('🔄 Running manual prediction...');
    return await _runPrediction(healthDataService, user);
  }

  /// Internal method to run the prediction
  Future<HypertensionPrediction?> _runPrediction(
    HealthDataService healthDataService,
    dynamic user,
  ) async {
    try {
      debugPrint('🔮 Running scheduled hypertension prediction...');
      
      // Collect training data
      final trainingData = await _collectTrainingData(healthDataService, user);
      
      if (!trainingData.hasEnoughData) {
        debugPrint('⚠️ Insufficient data for prediction');
        return null;
      }

      // Generate prediction
      final prediction = await HypertensionPredictionService.predictRisk(
        trainingData: trainingData,
      );

      // Store prediction
      _latestPrediction = prediction;
      _lastPredictionTime = DateTime.now();
      
      // Save to persistent storage
      await _savePrediction(prediction);

      debugPrint('✅ Prediction completed successfully');
      debugPrint('   Risk Level: ${prediction.riskLevel.label}');
      debugPrint('   Risk Score: ${prediction.riskScore.toStringAsFixed(1)}/100');
      debugPrint('   Confidence: ${(prediction.confidence * 100).toStringAsFixed(0)}%');
      debugPrint('   Next prediction: ${_lastPredictionTime!.add(_scheduleInterval)}');

      // Notify listeners
      _notifyListeners(prediction);

      return prediction;
    } catch (e) {
      debugPrint('❌ Error running prediction: $e');
      return null;
    }
  }

  /// Collect training data from health services
  Future<ModelTrainingData> _collectTrainingData(
    HealthDataService healthDataService,
    dynamic user,
  ) async {
    debugPrint('📊 Collecting health data for prediction...');

    // Get health data for last 30 days
    final result = await healthDataService.fetchComprehensiveHealthData(
      user,
      30,
    );

    final timeSeriesData = result['timeSeriesData'] as Map<String, List<dynamic>>? ?? {};

    // Convert to time series data points
    final bloodPressureData = <TimeSeriesDataPoint>[];
    final heartRateData = <TimeSeriesDataPoint>[];
    final activityData = <TimeSeriesDataPoint>[];
    final sleepData = <TimeSeriesDataPoint>[];

    // Blood pressure (systolic)
    if (timeSeriesData.containsKey('blood_pressure_systolic')) {
      final bpList = timeSeriesData['blood_pressure_systolic'] as List<dynamic>;
      for (final point in bpList) {
        bloodPressureData.add(TimeSeriesDataPoint(
          timestamp: point.timestamp,
          value: point.value,
          metric: 'blood_pressure_systolic',
        ));
      }
    }

    // Heart rate
    if (timeSeriesData.containsKey('heart_rate')) {
      final hrList = timeSeriesData['heart_rate'] as List<dynamic>;
      for (final point in hrList) {
        heartRateData.add(TimeSeriesDataPoint(
          timestamp: point.timestamp,
          value: point.value,
          metric: 'heart_rate',
        ));
      }
    }

    // Activity (steps)
    if (timeSeriesData.containsKey('steps')) {
      final stepsList = timeSeriesData['steps'] as List<dynamic>;
      for (final point in stepsList) {
        activityData.add(TimeSeriesDataPoint(
          timestamp: point.timestamp,
          value: point.value,
          metric: 'steps',
        ));
      }
    }

    // Sleep
    if (timeSeriesData.containsKey('sleep_hours')) {
      final sleepList = timeSeriesData['sleep_hours'] as List<dynamic>;
      for (final point in sleepList) {
        sleepData.add(TimeSeriesDataPoint(
          timestamp: point.timestamp,
          value: point.value,
          metric: 'sleep_hours',
        ));
      }
    }

    // Get user profile for risk factors
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    
    RiskFactors riskFactors;
    if (profileJson != null) {
      final profile = jsonDecode(profileJson);
      riskFactors = RiskFactors(
        age: profile['age'] ?? 30,
        isSmoker: profile['isSmoker'] ?? false,
        hasDiabetes: profile['hasDiabetes'] ?? false,
        hasHighCholesterol: profile['hasHighCholesterol'] ?? false,
        hasFamilyHistory: profile['hasFamilyHistory'] ?? false,
        bmi: (profile['bmi'] ?? 25.0).toDouble(),
        isPhysicallyActive: profile['isActive'] ?? true,
        averageStressLevel: (profile['stressLevel'] ?? 5.0).toDouble(),
      );
    } else {
      // Default risk factors
      riskFactors = RiskFactors(
        age: 30,
        bmi: 25.0,
      );
    }

    debugPrint('   Blood pressure points: ${bloodPressureData.length}');
    debugPrint('   Heart rate points: ${heartRateData.length}');
    debugPrint('   Activity points: ${activityData.length}');
    debugPrint('   Sleep points: ${sleepData.length}');

    return ModelTrainingData(
      bloodPressureData: bloodPressureData,
      heartRateData: heartRateData,
      activityData: activityData,
      sleepData: sleepData,
      riskFactors: riskFactors,
    );
  }

  /// Save prediction to persistent storage
  Future<void> _savePrediction(HypertensionPrediction prediction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_prediction', jsonEncode(prediction.toJson()));
      await prefs.setString('last_prediction_time', _lastPredictionTime!.toIso8601String());
      debugPrint('💾 Prediction saved to storage');
    } catch (e) {
      debugPrint('❌ Error saving prediction: $e');
    }
  }

  /// Load last prediction from persistent storage
  Future<void> _loadLastPrediction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final predictionJson = prefs.getString('last_prediction');
      final timeString = prefs.getString('last_prediction_time');

      if (predictionJson != null && timeString != null) {
        _lastPredictionTime = DateTime.parse(timeString);
        
        // Reconstruct prediction (simplified - you may need to expand this)
        final data = jsonDecode(predictionJson);
        final riskLevelString = data['riskLevel'] as String;
        final riskLevel = HypertensionRiskLevel.values.firstWhere(
          (e) => e.name == riskLevelString,
          orElse: () => HypertensionRiskLevel.moderate,
        );

        _latestPrediction = HypertensionPrediction(
          riskLevel: riskLevel,
          riskScore: (data['riskScore'] as num).toDouble(),
          confidence: (data['confidence'] as num).toDouble(),
          predictionDate: DateTime.parse(data['predictionDate']),
          contributingFactors: List<String>.from(data['contributingFactors']),
          recommendations: List<String>.from(data['recommendations']),
          futureProjections: Map<String, double>.from(
            (data['futureProjections'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            ),
          ),
        );

        debugPrint('📂 Loaded last prediction from storage');
        debugPrint('   Time: $_lastPredictionTime');
        debugPrint('   Risk: ${_latestPrediction!.riskLevel.label}');
      }
    } catch (e) {
      debugPrint('⚠️ Could not load last prediction: $e');
    }
  }

  /// Get prediction history summary
  String getPredictionSummary() {
    if (_latestPrediction == null) {
      return 'No predictions yet';
    }

    final timeSince = DateTime.now().difference(_lastPredictionTime!);
    final hoursAgo = timeSince.inHours;
    final minutesAgo = timeSince.inMinutes % 60;

    final nextPrediction = timeUntilNextPrediction;
    final hoursUntilNext = nextPrediction?.inHours ?? 0;
    final minutesUntilNext = (nextPrediction?.inMinutes ?? 0) % 60;

    return '''
Last Prediction: $hoursAgo hours, $minutesAgo minutes ago
Risk Level: ${_latestPrediction!.riskLevel.label}
Risk Score: ${_latestPrediction!.riskScore.toStringAsFixed(1)}/100
Next Prediction: in $hoursUntilNext hours, $minutesUntilNext minutes
Scheduler Status: ${_isRunning ? "Running" : "Stopped"}
''';
  }

  /// Clear stored predictions
  Future<void> clearPredictions() async {
    _latestPrediction = null;
    _lastPredictionTime = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_prediction');
    await prefs.remove('last_prediction_time');
    
    debugPrint('🗑️ Predictions cleared');
  }
}
