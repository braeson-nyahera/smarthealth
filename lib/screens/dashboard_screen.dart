import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../widgets/user_header.dart';
import '../widgets/smartwatch_stats_card.dart';
import '../widgets/prediction_scheduler_status.dart';
import '../models/health_models.dart';
import '../services/prediction_scheduler_service.dart';

class DashboardScreen extends StatelessWidget {
  final dynamic user;
  final int selectedDays;
  final Map<String, List<HealthDataPoint>> timeSeriesData;
  final Map<String, HealthSummary> summaryData;
  final VoidCallback onRefresh;
  final void Function(String, HealthMetric, List<HealthDataPoint>) onShowDetail;
  final VoidCallback? onProfileTap;
  final PredictionSchedulerService? predictionScheduler;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.selectedDays,
    required this.timeSeriesData,
    required this.summaryData,
    required this.onRefresh,
    required this.onShowDetail,
    this.onProfileTap,
    this.predictionScheduler,
  });

  @override
  Widget build(BuildContext context) {
    // Debug logging
    debugPrint(
      '🏠 Dashboard build - predictionScheduler is ${predictionScheduler == null ? "null" : "not null"}',
    );
    if (predictionScheduler != null) {
      debugPrint('   Scheduler running: ${predictionScheduler!.isRunning}');
      debugPrint(
        '   Has prediction: ${predictionScheduler!.latestPrediction != null}',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserHeader(
            user: user,
            selectedDays: selectedDays,
            metricsCount: timeSeriesData.length,
            onRefresh: onRefresh,
            onProfileTap: onProfileTap,
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Show prediction scheduler status if active
          if (predictionScheduler != null)
            PredictionSchedulerStatus(scheduler: predictionScheduler!),
          if (predictionScheduler != null)
            const SizedBox(height: AppTheme.spacingM),
          SmartwatchStatsCard(
            user: user,
            timeSeriesData: timeSeriesData,
            summaryData: summaryData,
            selectedDays: selectedDays,
          ),
        ],
      ),
    );
  }
}
