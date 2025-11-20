import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../constants/app_theme.dart';
import '../screens/health_insights_page.dart';

class SmartwatchStatsCard extends StatefulWidget {
  final dynamic user;
  final Map<String, List<HealthDataPoint>> timeSeriesData;
  final Map<String, HealthSummary> summaryData;
  final int selectedDays;

  const SmartwatchStatsCard({
    super.key,
    required this.user,
    required this.timeSeriesData,
    required this.summaryData,
    required this.selectedDays,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartWatch Analytics',
                style: AppTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Real-time health metrics',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Flexible(
          child: Container(
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
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Connected',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
            crossAxisCount:
                constraints.maxWidth > 600
                    ? 3
                    : constraints.maxWidth > 400
                    ? 2
                    : 1,
            crossAxisSpacing: AppTheme.spacingM,
            mainAxisSpacing: AppTheme.spacingM,
            childAspectRatio:
                constraints.maxWidth > 600
                    ? 1.2
                    : constraints.maxWidth > 400
                    ? 1.3
                    : 2.5,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Insights',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          '$totalDataPoints data points from smartwatch',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryDark),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryMedical,
                AppTheme.primaryMedical.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryMedical.withValues(alpha: 0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              onTap: _navigateToHealthInsights,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        'View detailed smartwatch insights',
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
        'value': '${heartRate.average.toInt()} bpm',
        'label': 'Avg Heart Rate',
        'trend': heartRate.trend,
      });
    } else {
      // Show placeholder when heart rate data is not available
      stats.add({
        'icon': Icons.favorite_border,
        'color': AppTheme.textSecondaryDark,
        'value': '--',
        'label': 'Heart Rate (No Data)',
        'trend': null,
      });
    }

    // Steps
    if (widget.summaryData.containsKey('steps')) {
      final steps = widget.summaryData['steps']!;
      stats.add({
        'icon': Icons.directions_walk_rounded,
        'color': AppTheme.activity,
        'value': '${(steps.latest / 1000).toStringAsFixed(1)}K',
        'label': 'Daily Steps',
        'trend': steps.trend,
      });
    } else {
      stats.add({
        'icon': Icons.directions_walk_outlined,
        'color': AppTheme.textSecondaryDark,
        'value': '--',
        'label': 'Steps (No Data)',
        'trend': null,
      });
    }

    // Calories
    if (widget.summaryData.containsKey('calories')) {
      final calories = widget.summaryData['calories']!;
      stats.add({
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orange,
        'value': '${calories.latest.toInt()} cal',
        'label': 'Calories Burned',
        'trend': calories.trend,
      });
    } else {
      stats.add({
        'icon': Icons.local_fire_department_outlined,
        'color': AppTheme.textSecondaryDark,
        'value': '--',
        'label': 'Calories (No Data)',
        'trend': null,
      });
    }

    // Blood Pressure
    if (widget.summaryData.containsKey('blood_pressure_systolic') &&
        widget.summaryData.containsKey('blood_pressure_diastolic')) {
      final systolic = widget.summaryData['blood_pressure_systolic']!;
      final diastolic = widget.summaryData['blood_pressure_diastolic']!;
      stats.add({
        'icon': Icons.bloodtype_rounded,
        'color': Colors.red.shade600,
        'value': '${systolic.latest.toInt()}/${diastolic.latest.toInt()}',
        'label': 'Blood Pressure',
        'trend': systolic.trend,
      });
    } else {
      stats.add({
        'icon': Icons.bloodtype_outlined,
        'color': AppTheme.textSecondaryDark,
        'value': '--',
        'label': 'Blood Pressure (No Data)',
        'trend': null,
      });
    }

    return stats.take(6).toList(); // Show max 6 stats in 2x3 grid
  }

  void _navigateToHealthInsights() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => HealthInsightsPage(
              user: widget.user,
              timeSeriesData: widget.timeSeriesData,
              summaryData: widget.summaryData,
              selectedDays: widget.selectedDays,
            ),
      ),
    );
  }
}
