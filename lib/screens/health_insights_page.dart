import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_theme.dart';
import '../models/health_models.dart';

class HealthInsightsPage extends StatefulWidget {
  final GoogleSignInAccount user;
  final Map<String, List<HealthDataPoint>> timeSeriesData;
  final Map<String, HealthSummary> summaryData;
  final int selectedDays;

  const HealthInsightsPage({
    super.key,
    required this.user,
    required this.timeSeriesData,
    required this.summaryData,
    required this.selectedDays,
  });

  @override
  State<HealthInsightsPage> createState() => _HealthInsightsPageState();
}

class _HealthInsightsPageState extends State<HealthInsightsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Activity', 'Vitals', 'Sleep'];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: AppTheme.primaryMedical,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareInsights,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalDataPoints = widget.timeSeriesData.values.fold(
      0,
      (sum, list) => sum + list.length,
    );

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryHealthGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.elevationHigh,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child:
                    widget.user.photoUrl != null
                        ? ClipOval(
                          child: Image.network(
                            widget.user.photoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person_rounded,
                                size: 30,
                                color: Colors.white.withOpacity(0.9),
                              );
                            },
                          ),
                        )
                        : Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: Colors.white.withOpacity(0.9),
                        ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.user.displayName}\'s Health Report',
                      style: AppTheme.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Last ${widget.selectedDays} days • $totalDataPoints data points',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            'Heart Rate',
            _getHeartRateAvg(),
            Icons.favorite_rounded,
            AppTheme.heartRate,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildQuickStatCard(
            'Steps',
            _getStepsTotal(),
            Icons.directions_walk_rounded,
            AppTheme.activity,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildQuickStatCard(
            'Sleep',
            _getSleepAvg(),
            Icons.bedtime_rounded,
            AppTheme.sleep,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Row(
        children:
            _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = _selectedTab == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = index),
                  child: AnimatedContainer(
                    duration: AppTheme.animationMedium,
                    margin: EdgeInsets.only(
                      right: index < _tabs.length - 1 ? AppTheme.spacingS : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppTheme.primaryMedical
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppTheme.primaryMedical
                                : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyMedium.copyWith(
                        color:
                            isSelected
                                ? Colors.white
                                : AppTheme.textSecondaryDark,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: AnimatedSwitcher(
        duration: AppTheme.animationMedium,
        child: _getTabContent(),
      ),
    );
  }

  Widget _getTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildActivityTab();
      case 2:
        return _buildVitalsTab();
      case 3:
        return _buildSleepTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Health Summary'),
          const SizedBox(height: AppTheme.spacingM),
          _buildOverviewCards(),
          const SizedBox(height: AppTheme.spacingXL),
          _buildSectionTitle('Trends & Insights'),
          const SizedBox(height: AppTheme.spacingM),
          _buildTrendsSection(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Activity Overview'),
          const SizedBox(height: AppTheme.spacingM),
          _buildActivityCards(),
          const SizedBox(height: AppTheme.spacingXL),
          _buildSectionTitle('Steps Chart'),
          const SizedBox(height: AppTheme.spacingM),
          _buildStepsChart(),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Vital Signs'),
          const SizedBox(height: AppTheme.spacingM),
          _buildVitalsCards(),
          const SizedBox(height: AppTheme.spacingXL),
          _buildSectionTitle('Heart Rate Trend'),
          const SizedBox(height: AppTheme.spacingM),
          _buildHeartRateChart(),
        ],
      ),
    );
  }

  Widget _buildSleepTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Sleep Analysis'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSleepCards(),
          const SizedBox(height: AppTheme.spacingXL),
          _buildSectionTitle('Sleep Pattern'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSleepChart(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.headingMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryDark,
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spacingM,
      mainAxisSpacing: AppTheme.spacingM,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Steps',
          _getStepsTotal(),
          Icons.directions_walk_rounded,
          AppTheme.activity,
        ),
        _buildMetricCard(
          'Heart Rate',
          _getHeartRateAvg(),
          Icons.favorite_rounded,
          AppTheme.heartRate,
        ),
        _buildMetricCard(
          'Sleep',
          _getSleepAvg(),
          Icons.bedtime_rounded,
          AppTheme.sleep,
        ),
        _buildMetricCard(
          'Calories',
          _getCaloriesTotal(),
          Icons.local_fire_department_rounded,
          AppTheme.vitals,
        ),
      ],
    );
  }

  Widget _buildActivityCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spacingM,
      mainAxisSpacing: AppTheme.spacingM,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          'Daily Steps',
          _getStepsTotal(),
          Icons.directions_walk_rounded,
          AppTheme.activity,
        ),
        _buildMetricCard(
          'Distance',
          _getDistanceTotal(),
          Icons.straighten_rounded,
          AppTheme.activity,
        ),
        _buildMetricCard(
          'Active Energy',
          _getActiveEnergyTotal(),
          Icons.local_fire_department_rounded,
          AppTheme.vitals,
        ),
        _buildMetricCard(
          'Exercise Time',
          _getExerciseTime(),
          Icons.fitness_center_rounded,
          AppTheme.activity,
        ),
      ],
    );
  }

  Widget _buildVitalsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spacingM,
      mainAxisSpacing: AppTheme.spacingM,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          'Heart Rate',
          _getHeartRateAvg(),
          Icons.favorite_rounded,
          AppTheme.heartRate,
        ),
        _buildMetricCard(
          'Blood Pressure',
          _getBloodPressure(),
          Icons.monitor_heart_rounded,
          AppTheme.vitals,
        ),
        _buildMetricCard(
          'Oxygen Sat.',
          _getOxygenSaturation(),
          Icons.air_rounded,
          AppTheme.vitals,
        ),
        _buildMetricCard(
          'Body Temp.',
          _getBodyTemperature(),
          Icons.thermostat_rounded,
          AppTheme.vitals,
        ),
      ],
    );
  }

  Widget _buildSleepCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spacingM,
      mainAxisSpacing: AppTheme.spacingM,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          'Avg Sleep',
          _getSleepAvg(),
          Icons.bedtime_rounded,
          AppTheme.sleep,
        ),
        _buildMetricCard(
          'Deep Sleep',
          _getDeepSleep(),
          Icons.nights_stay_rounded,
          AppTheme.sleep,
        ),
        _buildMetricCard(
          'Sleep Quality',
          _getSleepQuality(),
          Icons.hotel_rounded,
          AppTheme.sleep,
        ),
        _buildMetricCard(
          'Sleep Score',
          _getSleepScore(),
          Icons.score_rounded,
          AppTheme.sleep,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfacePure,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.elevationMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfacePure,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Trends',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildTrendItem('Steps', _getStepsTrend(), AppTheme.activity),
          _buildTrendItem(
            'Heart Rate',
            _getHeartRateTrend(),
            AppTheme.heartRate,
          ),
          _buildTrendItem('Sleep', _getSleepTrend(), AppTheme.sleep),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String title, String trend, Color color) {
    final isPositive = trend.contains('↑');
    final isNegative = trend.contains('↓');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: (isPositive
                      ? AppTheme.success
                      : isNegative
                      ? AppTheme.error
                      : AppTheme.textSecondaryDark)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              trend,
              style: AppTheme.bodySmall.copyWith(
                color:
                    isPositive
                        ? AppTheme.success
                        : isNegative
                        ? AppTheme.error
                        : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsChart() {
    if (!widget.timeSeriesData.containsKey('steps')) {
      return _buildNoDataCard('No steps data available');
    }

    final stepsData = widget.timeSeriesData['steps']!;
    return _buildChart(stepsData, 'Steps', AppTheme.activity);
  }

  Widget _buildHeartRateChart() {
    if (!widget.timeSeriesData.containsKey('heart_rate')) {
      return _buildNoDataCard('No heart rate data available');
    }

    final heartRateData = widget.timeSeriesData['heart_rate']!;
    return _buildChart(heartRateData, 'Heart Rate (BPM)', AppTheme.heartRate);
  }

  Widget _buildSleepChart() {
    if (!widget.timeSeriesData.containsKey('sleep_hours')) {
      return _buildNoDataCard('No sleep data available');
    }

    final sleepData = widget.timeSeriesData['sleep_hours']!;
    return _buildChart(sleepData, 'Sleep Hours', AppTheme.sleep);
  }

  Widget _buildChart(List<HealthDataPoint> data, String title, Color color) {
    if (data.isEmpty) {
      return _buildNoDataCard('No $title data available');
    }

    final spots =
        data.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value);
        }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfacePure,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfacePure,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppTheme.textSecondaryDark.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _shareInsights() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppTheme.primaryMedical,
      ),
    );
  }

  // Helper methods to get metric values
  String _getHeartRateAvg() {
    if (widget.summaryData.containsKey('heart_rate')) {
      return '${widget.summaryData['heart_rate']!.average.toInt()} bpm';
    }
    return '--';
  }

  String _getStepsTotal() {
    if (widget.summaryData.containsKey('steps')) {
      final steps = widget.summaryData['steps']!.latest;
      return steps >= 1000
          ? '${(steps / 1000).toStringAsFixed(1)}K'
          : steps.toInt().toString();
    }
    return '--';
  }

  String _getSleepAvg() {
    if (widget.summaryData.containsKey('sleep_hours')) {
      return '${widget.summaryData['sleep_hours']!.average.toStringAsFixed(1)}h';
    }
    return '--';
  }

  String _getCaloriesTotal() {
    if (widget.summaryData.containsKey('calories')) {
      return '${widget.summaryData['calories']!.latest.toInt()}';
    }
    return '--';
  }

  String _getDistanceTotal() {
    if (widget.summaryData.containsKey('distance')) {
      final distance = widget.summaryData['distance']!.latest;
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '--';
  }

  String _getActiveEnergyTotal() {
    return _getCaloriesTotal();
  }

  String _getExerciseTime() {
    if (widget.summaryData.containsKey('workout_time')) {
      return '${widget.summaryData['workout_time']!.latest.toInt()} min';
    }
    return '--';
  }

  String _getBloodPressure() {
    if (widget.summaryData.containsKey('blood_pressure_systolic') &&
        widget.summaryData.containsKey('blood_pressure_diastolic')) {
      final systolic =
          widget.summaryData['blood_pressure_systolic']!.average.toInt();
      final diastolic =
          widget.summaryData['blood_pressure_diastolic']!.average.toInt();
      return '$systolic/$diastolic';
    }
    return '--';
  }

  String _getOxygenSaturation() {
    if (widget.summaryData.containsKey('oxygen_saturation')) {
      return '${widget.summaryData['oxygen_saturation']!.average.toInt()}%';
    }
    return '--';
  }

  String _getBodyTemperature() {
    if (widget.summaryData.containsKey('body_temperature')) {
      return '${widget.summaryData['body_temperature']!.average.toStringAsFixed(1)}°C';
    }
    return '--';
  }

  String _getDeepSleep() {
    if (widget.summaryData.containsKey('deep_sleep')) {
      return '${widget.summaryData['deep_sleep']!.average.toStringAsFixed(1)}h';
    }
    return '--';
  }

  String _getSleepQuality() {
    if (widget.summaryData.containsKey('sleep_hours')) {
      final sleepHours = widget.summaryData['sleep_hours']!.average;
      if (sleepHours >= 7 && sleepHours <= 9) return 'Good';
      if (sleepHours >= 6) return 'Fair';
      return 'Poor';
    }
    return '--';
  }

  String _getSleepScore() {
    if (widget.summaryData.containsKey('sleep_hours')) {
      final sleepHours = widget.summaryData['sleep_hours']!.average;
      final score = ((sleepHours / 8) * 100).clamp(0, 100);
      return '${score.toInt()}/100';
    }
    return '--';
  }

  String _getStepsTrend() {
    if (widget.summaryData.containsKey('steps')) {
      final trend = widget.summaryData['steps']!.trend;
      if (trend > 0.1) return '↑ ${(trend * 100).toStringAsFixed(0)}%';
      if (trend < -0.1) return '↓ ${(trend.abs() * 100).toStringAsFixed(0)}%';
      return '→ Stable';
    }
    return '--';
  }

  String _getHeartRateTrend() {
    if (widget.summaryData.containsKey('heart_rate')) {
      final trend = widget.summaryData['heart_rate']!.trend;
      if (trend > 0.05) return '↑ ${(trend * 100).toStringAsFixed(0)}%';
      if (trend < -0.05) return '↓ ${(trend.abs() * 100).toStringAsFixed(0)}%';
      return '→ Stable';
    }
    return '--';
  }

  String _getSleepTrend() {
    if (widget.summaryData.containsKey('sleep_hours')) {
      final trend = widget.summaryData['sleep_hours']!.trend;
      if (trend > 0.1) return '↑ ${(trend * 100).toStringAsFixed(0)}%';
      if (trend < -0.1) return '↓ ${(trend.abs() * 100).toStringAsFixed(0)}%';
      return '→ Stable';
    }
    return '--';
  }
}
