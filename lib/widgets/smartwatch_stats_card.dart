import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../constants/app_theme.dart';

class SmartwatchStatsCard extends StatefulWidget {
  final Map<String, List<HealthDataPoint>> timeSeriesData;
  final Map<String, HealthSummary> summaryData;

  const SmartwatchStatsCard({
    super.key,
    required this.timeSeriesData,
    required this.summaryData,
  });

  @override
  State<SmartwatchStatsCard> createState() => _SmartwatchStatsCardState();
}

class _SmartwatchStatsCardState extends State<SmartwatchStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: AppTheme.borderSubtle, width: 1),
            boxShadow: AppTheme.elevationMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: AppTheme.spacingL),
              Flexible(child: _buildStatsGrid()),
              const SizedBox(height: AppTheme.spacingM),
              _buildHealthInsight(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.primaryMedical.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            Icons.watch_rounded,
            color: AppTheme.primaryMedical,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmartWatch Analytics',
              style: AppTheme.headingSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Real-time health metrics',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                'Connected',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _getKeyStats();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 500 ? 2 : 1,
            crossAxisSpacing: AppTheme.spacingM,
            mainAxisSpacing: AppTheme.spacingM,
            childAspectRatio: constraints.maxWidth > 500 ? 1.3 : 2.5,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(stat);
          },
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: 20,
              ),
              const Spacer(),
              if (stat['trend'] != null)
                Icon(
                  stat['trend'] > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: stat['trend'] > 0 ? AppTheme.success : AppTheme.error,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                stat['value'] as String,
                style: AppTheme.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Flexible(
            child: Text(
              stat['label'] as String,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryDark,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInsight() {
    final totalDataPoints = widget.timeSeriesData.values.fold(
      0,
      (sum, list) => sum + list.length,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryHealthGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: Colors.white, size: 24),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Insights',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tracking $totalDataPoints data points from your smartwatch',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to detailed insights
            },
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getKeyStats() {
    final stats = <Map<String, dynamic>>[];

    // Heart Rate
    if (widget.summaryData.containsKey('heart_rate')) {
      final heartRate = widget.summaryData['heart_rate']!;
      stats.add({
        'icon': Icons.favorite_rounded,
        'color': AppTheme.heartRate,
        'value': '\${heartRate.average.toInt()} bpm',
        'label': 'Avg Heart Rate',
        'trend': heartRate.trend,
      });
    }

    // Steps
    if (widget.summaryData.containsKey('steps')) {
      final steps = widget.summaryData['steps']!;
      stats.add({
        'icon': Icons.directions_walk_rounded,
        'color': AppTheme.activity,
        'value': '\${(steps.total / 1000).toStringAsFixed(1)}K',
        'label': 'Daily Steps',
        'trend': steps.trend,
      });
    }

    // Sleep
    if (widget.summaryData.containsKey('sleep_hours')) {
      final sleep = widget.summaryData['sleep_hours']!;
      stats.add({
        'icon': Icons.bedtime_rounded,
        'color': AppTheme.sleep,
        'value': '\${sleep.average.toStringAsFixed(1)}h',
        'label': 'Avg Sleep',
        'trend': sleep.trend,
      });
    }

    // Active Energy
    if (widget.summaryData.containsKey('active_energy')) {
      final energy = widget.summaryData['active_energy']!;
      stats.add({
        'icon': Icons.local_fire_department_rounded,
        'color': AppTheme.vitals,
        'value': '\${energy.total.toInt()} cal',
        'label': 'Active Energy',
        'trend': energy.trend,
      });
    }

    return stats.take(4).toList(); // Show max 4 stats in 2x2 grid
  }
}
