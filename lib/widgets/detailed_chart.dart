import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_models.dart';
import '../utils/health_utils.dart';
import '../constants/app_theme.dart';

class DetailedChart extends StatefulWidget {
  final List<HealthDataPoint> data;
  final HealthMetric metric;

  const DetailedChart({super.key, required this.data, required this.metric});

  @override
  State<DetailedChart> createState() => _DetailedChartState();
}

class _DetailedChartState extends State<DetailedChart> {
  String selectedPeriod = '7d';

  List<HealthDataPoint> get filteredData {
    final now = DateTime.now();
    int days = 7;

    switch (selectedPeriod) {
      case '24h':
        days = 1;
        break;
      case '7d':
        days = 7;
        break;
      case '30d':
        days = 30;
        break;
      case '90d':
        days = 90;
        break;
    }

    final cutoff = now.subtract(Duration(days: days));
    return widget.data
        .where((point) => point.timestamp.isAfter(cutoff))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (filteredData.length < 2) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Insufficient data for chart',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        children: [
          // Header with period selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(widget.metric.icon, color: widget.metric.color, size: 20),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  widget.metric.name,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _buildPeriodSelector(),
              ],
            ),
          ),

          // Chart
          Container(
            height: 280,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = ['24h', '7d', '30d', '90d'];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            periods.map((period) {
              final isSelected = period == selectedPeriod;
              return GestureDetector(
                onTap: () => setState(() => selectedPeriod = period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    period,
                    style: AppTheme.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    final maxY = filteredData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final minY = filteredData
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    final paddedMax = maxY + (range * 0.1);
    final paddedMin = (minY - (range * 0.1)).clamp(0, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (filteredData.length - 1).toDouble(),
        minY: paddedMin.toDouble(),
        maxY: paddedMax.toDouble(),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (paddedMax - paddedMin) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppTheme.borderLight, strokeWidth: 1);
          },
        ),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (paddedMax - paddedMin) / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    HealthUtils.formatValue(value, widget.metric),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (filteredData.length / 5).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < filteredData.length) {
                  final point = filteredData[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${point.timestamp.month}/${point.timestamp.day}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        borderData: FlBorderData(show: false),

        lineBarsData: [
          LineChartBarData(
            spots:
                filteredData.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value.value);
                }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: widget.metric.color,
            barWidth: 3,

            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.surfacePrimary,
                  strokeWidth: 2,
                  strokeColor: widget.metric.color,
                );
              },
            ),

            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.metric.color.withValues(alpha: 0.15),
                  widget.metric.color.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],

        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.surfaceSecondary,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final point = filteredData[touchedSpot.x.toInt()];
                return LineTooltipItem(
                  '${HealthUtils.formatValue(touchedSpot.y, widget.metric)}\n${point.timestamp.month}/${point.timestamp.day}',
                  AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: widget.metric.color.withValues(alpha: 0.3),
                  strokeWidth: 2,
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: AppTheme.surfacePrimary,
                      strokeWidth: 3,
                      strokeColor: widget.metric.color,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
