import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/health_models.dart';
import '../utils/health_utils.dart';
import '../constants/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String metricKey;
  final HealthMetric metric;
  final HealthSummary summary;
  final List<HealthDataPoint> timeSeries;
  final VoidCallback onTap;

  const MetricCard({
    super.key,
    required this.metricKey,
    required this.metric,
    required this.summary,
    required this.timeSeries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.borderLight, width: 1),
          boxShadow: AppTheme.shadowSoft,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and mini chart
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 18),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(child: _buildMiniChart(timeSeries, metric.color)),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingM,
                    0,
                    AppTheme.spacingM,
                    AppTheme.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metric name
                      Text(
                        metric.name,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppTheme.spacingXS),

                      // Main value
                      Text(
                        HealthUtils.formatValue(summary.latest, metric),
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),

                      const Spacer(),

                      // Trend and average
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTrendColor(
                                summary.trend,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTrendIcon(summary.trend),
                                  size: 12,
                                  color: _getTrendColor(summary.trend),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _getTrendText(summary.trend),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: _getTrendColor(summary.trend),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Avg ${HealthUtils.formatValue(summary.average, metric)}',
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<HealthDataPoint> data, Color color) {
    if (data.length < 2) {
      return Container(
        height: 32,
        alignment: Alignment.center,
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ],
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: data.map((e) => e.value).reduce(min),
          maxY: data.map((e) => e.value).reduce(max),
        ),
      ),
    );
  }

  Color _getTrendColor(double trend) {
    if (trend > 0.1) return AppTheme.accentGreen;
    if (trend < -0.1) return AppTheme.accentRed;
    return AppTheme.textTertiary;
  }

  IconData _getTrendIcon(double trend) {
    if (trend > 0.1) return Icons.trending_up_rounded;
    if (trend < -0.1) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  String _getTrendText(double trend) {
    if (trend > 0.1) return 'Up';
    if (trend < -0.1) return 'Down';
    return 'Stable';
  }
}
