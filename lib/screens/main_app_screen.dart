import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/risk_assessment_screen.dart';
import '../screens/graphs_screen.dart';
import '../models/health_models.dart';
import '../constants/app_theme.dart';
import '../services/prediction_scheduler_service.dart';

/// Main screen with bottom navigation for Dashboard, Graphs, and Risk Assessment
class MainAppScreen extends StatefulWidget {
  final dynamic user;
  final int selectedDays;
  final Map<String, List<HealthDataPoint>> timeSeriesData;
  final Map<String, HealthSummary> summaryData;
  final VoidCallback onRefresh;
  final void Function(String, HealthMetric, List<HealthDataPoint>) onShowDetail;
  final VoidCallback? onProfileTap;
  final PredictionSchedulerService? predictionScheduler;

  const MainAppScreen({
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
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        user: widget.user,
        selectedDays: widget.selectedDays,
        timeSeriesData: widget.timeSeriesData,
        summaryData: widget.summaryData,
        onRefresh: widget.onRefresh,
        onShowDetail: widget.onShowDetail,
        onProfileTap: widget.onProfileTap,
        predictionScheduler: widget.predictionScheduler,
      ),
      GraphsScreen(
        timeSeriesData: widget.timeSeriesData,
        summaryData: widget.summaryData,
        selectedDays: widget.selectedDays,
        onShowDetail: widget.onShowDetail,
      ),
      RiskAssessmentScreen(predictionScheduler: widget.predictionScheduler),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryMedical,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            activeIcon: Icon(Icons.show_chart),
            label: 'Graphs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            activeIcon: Icon(Icons.favorite),
            label: 'Risk Assessment',
          ),
        ],
      ),
    );
  }
}
