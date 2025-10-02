import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../utils/health_utils.dart';
import '../constants/app_theme.dart';

class DetailedStats extends StatelessWidget {
  final HealthSummary summary;
  final HealthMetric metric;

  const DetailedStats({super.key, required this.summary, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfacePure,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.elevationSoft,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.textSecondaryDark,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Statistics',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Stats content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Latest',
                        HealthUtils.formatValue(summary.latest, metric),
                        Icons.access_time_rounded,
                        metric.color,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: _buildStatItem(
                        'Average',
                        HealthUtils.formatValue(summary.average, metric),
                        Icons.show_chart_rounded,
                        AppTheme.activity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Minimum',
                        HealthUtils.formatValue(summary.min, metric),
                        Icons.keyboard_arrow_down_rounded,
                        AppTheme.nutrition,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: _buildStatItem(
                        'Maximum',
                        HealthUtils.formatValue(summary.max, metric),
                        Icons.keyboard_arrow_up_rounded,
                        AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Trend indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: _getTrendColor(
                      summary.trend,
                    ).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: _getTrendColor(
                        summary.trend,
                      ).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getTrendColor(
                            summary.trend,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Icon(
                          _getTrendIcon(summary.trend),
                          color: _getTrendColor(summary.trend),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTrendTitle(summary.trend),
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getTrendColor(summary.trend),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getTrendDescription(summary.trend),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryDark,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(double trend) {
    if (trend > 0.05) return AppTheme.success;
    if (trend < -0.05) return AppTheme.error;
    return AppTheme.textSecondaryDark;
  }

  IconData _getTrendIcon(double trend) {
    if (trend > 0.05) return Icons.trending_up_rounded;
    if (trend < -0.05) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  String _getTrendTitle(double trend) {
    if (trend > 0.05) return 'Trending Up';
    if (trend < -0.05) return 'Trending Down';
    return 'Stable';
  }

  String _getTrendDescription(double trend) {
    if (trend > 0.05) return 'Values are increasing over time';
    if (trend < -0.05) return 'Values are decreasing over time';
    return 'Values remain relatively stable';
  }
}
