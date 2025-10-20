import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../widgets/user_header.dart';
import '../widgets/smartwatch_stats_card.dart';
import '../widgets/category_header.dart';
import '../widgets/metric_card.dart';
import '../widgets/prediction_scheduler_status.dart';
import '../models/health_models.dart';
import '../utils/health_utils.dart';
import '../constants/health_metrics.dart';
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
          const SizedBox(height: AppTheme.spacingXL),
          _buildMetricCategories(),
        ],
      ),
    );
  }

  Widget _buildMetricCategories() {
    final categories = HealthUtils.groupMetricsByCategory(
      timeSeriesData,
      HealthMetrics.metricsToTrack,
    );

    return Column(
      children:
          categories.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryHeader(category: entry.key),
                const SizedBox(height: AppTheme.spacingM),
                _buildMetricGrid(entry.value),
                const SizedBox(height: AppTheme.spacingXL),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildMetricGrid(List<String> metricKeys) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        final childAspectRatio = constraints.maxWidth > 600 ? 0.75 : 1.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppTheme.spacingM,
            mainAxisSpacing: AppTheme.spacingM,
          ),
          itemCount: metricKeys.length,
          itemBuilder: (context, index) {
            final key = metricKeys[index];
            final metric = HealthMetrics.metricsToTrack[key]!;
            final summary = summaryData[key];
            final timeSeries = timeSeriesData[key];

            if (summary == null || timeSeries == null) {
              return Container();
            }

            return MetricCard(
              metricKey: key,
              metric: metric,
              summary: summary,
              timeSeries: timeSeries,
              onTap: () => onShowDetail(key, metric, timeSeries),
            );
          },
        );
      },
    );
  }
}
