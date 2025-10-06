import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/health_models.dart';
import '../constants/app_theme.dart';

class MetricCard extends StatefulWidget {
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
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppTheme.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: AppTheme.animationMedium,
                curve: AppTheme.animationCurve,
                decoration: BoxDecoration(
                  color: AppTheme.surfacePure,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(
                    color:
                        _isHovered
                            ? AppTheme.getMetricColor(
                              widget.metric.category,
                            ).withValues(alpha: 0.3)
                            : AppTheme.borderSubtle,
                    width: _isHovered ? 2 : 1,
                  ),
                  boxShadow:
                      _isHovered
                          ? [
                            BoxShadow(
                              color: AppTheme.getMetricColor(
                                widget.metric.category,
                              ).withValues(alpha: 0.1),
                              offset: const Offset(0, 8),
                              blurRadius: 24,
                              spreadRadius: 0,
                            ),
                            ...AppTheme.elevationMedium,
                          ]
                          : AppTheme.elevationSoft,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      Flexible(child: _buildContent()),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.getMetricColor(
              widget.metric.category,
            ).withValues(alpha: 0.05),
            AppTheme.getMetricColor(
              widget.metric.category,
            ).withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.getMetricColor(
                widget.metric.category,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              widget.metric.icon,
              size: 20,
              color: AppTheme.getMetricColor(widget.metric.category),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.metric.name,
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.metric.category,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.getMetricColor(widget.metric.category),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (widget.timeSeries.isNotEmpty)
            SizedBox(width: 40, height: 24, child: _buildSparkline()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingM,
        AppTheme.spacingS,
        AppTheme.spacingM,
        0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatValue(widget.summary.latest),
                    style: AppTheme.displayLarge.copyWith(
                      color: AppTheme.getMetricColor(widget.metric.category),
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.metric.unit,
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.textSecondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.summary.trend != 0) ...[
            const SizedBox(height: AppTheme.spacingXS),
            _buildTrendIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.timeSeries.isNotEmpty)
            SizedBox(height: 32, child: _buildSparkline()),
          const SizedBox(height: AppTheme.spacingS),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg',
                    _formatValue(widget.summary.average),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Min',
                    _formatValue(widget.summary.min),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Max',
                    _formatValue(widget.summary.max),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textTertiaryDark,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryDark,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTrendIndicator() {
    final trend = widget.summary.trend;
    final isPositive = trend > 0;
    final isImprovement = _isPositiveChange(widget.metric.name, isPositive);

    final color = isImprovement ? AppTheme.success : AppTheme.warning;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline() {
    if (widget.timeSeries.isEmpty) return Container();

    final values = widget.timeSeries.map((point) => point.value).toList();
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);

    if (minValue == maxValue) return Container();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                values.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value);
                }).toList(),
            isCurved: true,
            color: AppTheme.getMetricColor(widget.metric.category),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.getMetricColor(
                widget.metric.category,
              ).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (widget.metric.valueType == ValueType.integer) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  bool _isPositiveChange(String metricName, bool isPositive) {
    // For health metrics, define what constitutes improvement
    const improvesWithIncrease = {
      'steps',
      'active_minutes',
      'sleep_duration',
      'vo2_max',
      'hydration',
      'workout_sessions',
      'oxygen_saturation',
    };

    const improvesWithDecrease = {
      'resting_heart_rate',
      'stress_level',
      'body_fat_percentage',
    };

    final lowerMetric = metricName.toLowerCase();

    if (improvesWithIncrease.any((metric) => lowerMetric.contains(metric))) {
      return isPositive;
    }

    if (improvesWithDecrease.any((metric) => lowerMetric.contains(metric))) {
      return !isPositive;
    }

    return isPositive; // Default assumption
  }
}
