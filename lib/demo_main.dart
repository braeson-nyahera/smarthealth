import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'widgets/category_header.dart';

void main() {
  runApp(const SmartHealthDemoApp());
}

class SmartHealthDemoApp extends StatelessWidget {
  const SmartHealthDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHealth Demo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  int _selectedDays = 7;

  // Generate demo data based on selected time period
  Map<String, String> _getDemoData(String metric) {
    final multiplier = _selectedDays / 7.0;

    switch (metric) {
      case 'Steps':
        final current = (12847 * multiplier).round();
        final avg = (10240 * multiplier * 0.8).round();
        return {
          'current': current.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          ),
          'avg': avg.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          ),
        };
      case 'Distance':
        final current = (8.2 * multiplier);
        final avg = (6.5 * multiplier * 0.85);
        return {
          'current': '${current.toStringAsFixed(1)} km',
          'avg': '${avg.toStringAsFixed(1)} km',
        };
      case 'Calories':
        final current = (420 * multiplier).round();
        final avg = (385 * multiplier * 0.9).round();
        return {'current': '$current cal', 'avg': '$avg cal'};
      case 'Active Minutes':
        final current = (45 * multiplier).round();
        final avg = (38 * multiplier * 0.85).round();
        return {'current': '$current min', 'avg': '$avg min'};
      case 'Heart Rate':
        // Heart rate doesn't scale with time period
        return {'current': '72 bpm', 'avg': '75 bpm'};
      case 'Sleep':
        final current =
            7.5 +
            (_selectedDays > 7
                ? 0.2
                : 0); // Slightly more sleep over longer periods
        final avg = 7.25;
        return {
          'current': '${(current).floor()}h ${((current % 1) * 60).round()}m',
          'avg': '${(avg).floor()}h ${((avg % 1) * 60).round()}m',
        };
      default:
        return {'current': '0', 'avg': '0'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceTertiary,
      appBar: AppBar(
        title: Text(
          'SmartHealth',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: DropdownButton<int>(
              value: _selectedDays,
              dropdownColor: AppTheme.primaryBlue,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              underline: Container(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 16,
              ),
              items:
                  [7, 14, 30, 90].map((days) {
                    return DropdownMenuItem(
                      value: days,
                      child: Text(
                        '$days days',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDays = value);
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo User Header
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.shadowSoft,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo User',
                            style: AppTheme.headingMedium.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Premium Health Dashboard',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Show bottom sheet with time period options
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppTheme.surfacePrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radiusL),
                            ),
                          ),
                          builder:
                              (context) => Container(
                                padding: const EdgeInsets.all(
                                  AppTheme.spacingL,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Select Time Period',
                                      style: AppTheme.headingMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingL),
                                    ...[7, 14, 30, 90].map(
                                      (days) => ListTile(
                                        title: Text('$days days'),
                                        trailing:
                                            _selectedDays == days
                                                ? Icon(
                                                  Icons.check,
                                                  color: AppTheme.primaryBlue,
                                                )
                                                : null,
                                        onTap: () {
                                          setState(() => _selectedDays = days);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_selectedDays days',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // Fitness Category
            CategoryHeader(category: 'Fitness'),
            const SizedBox(height: AppTheme.spacingM),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              children: [
                () {
                  final data = _getDemoData('Steps');
                  return _buildDemoCard(
                    'Steps',
                    Icons.directions_walk_rounded,
                    AppTheme.primaryBlue,
                    data['current']!,
                    data['avg']!,
                  );
                }(),
                () {
                  final data = _getDemoData('Distance');
                  return _buildDemoCard(
                    'Distance',
                    Icons.route_rounded,
                    AppTheme.secondaryTeal,
                    data['current']!,
                    data['avg']!,
                  );
                }(),
                () {
                  final data = _getDemoData('Calories');
                  return _buildDemoCard(
                    'Calories',
                    Icons.local_fire_department_rounded,
                    AppTheme.accentOrange,
                    data['current']!,
                    data['avg']!,
                  );
                }(),
                () {
                  final data = _getDemoData('Active Minutes');
                  return _buildDemoCard(
                    'Active Minutes',
                    Icons.timer_rounded,
                    AppTheme.accentPurple,
                    data['current']!,
                    data['avg']!,
                  );
                }(),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // Health Category
            CategoryHeader(category: 'Health'),
            const SizedBox(height: AppTheme.spacingM),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              children: [
                () {
                  final data = _getDemoData('Heart Rate');
                  return _buildDemoCard(
                    'Heart Rate',
                    Icons.favorite_rounded,
                    AppTheme.accentRed,
                    data['current']!,
                    data['avg']!,
                  );
                }(),
                () {
                  final data = _getDemoData('Sleep');
                  return _buildDemoCard(
                    'Sleep',
                    Icons.bedtime_rounded,
                    AppTheme.primaryBlue,
                    data['current']!,
                    data['avg']!,
                  );
                }(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoCard(
    String title,
    IconData icon,
    Color color,
    String value,
    String avgValue,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: AppTheme.shadowSoft,
      ),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color.withValues(alpha: 0.1),
                          color.withValues(alpha: 0.05),
                          color.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
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
                    title,
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
                    value,
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
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 12,
                              color: AppTheme.accentGreen,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Up',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.accentGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Avg $avgValue',
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
    );
  }
}
