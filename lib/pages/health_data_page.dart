import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/health_models.dart';
import '../constants/health_metrics.dart';
import '../constants/app_theme.dart';
import '../services/health_data_service.dart';
import '../utils/health_utils.dart';
import '../widgets/user_header.dart';
import '../widgets/category_header.dart';
import '../widgets/metric_card.dart';
import '../widgets/detailed_chart.dart';
import '../widgets/detailed_stats.dart';
import '../widgets/smartwatch_stats_card.dart';

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({super.key});

  @override
  State<HealthDataPage> createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  final HealthDataService _healthDataService = HealthDataService();

  GoogleSignInAccount? _user;
  Map<String, List<HealthDataPoint>> _timeSeriesData = {};
  Map<String, HealthSummary> _summaryData = {};
  String _debugMessage = '';
  bool _isLoading = false;
  int _selectedDays = 7;
  Timer? _refreshTimer;
  DateTime? _lastFetchTime;
  bool _isAutoRefreshing = false;
  int _autoRefreshFailures = 0;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _healthDataService.googleSignIn.signOut();
    super.dispose();
  }

  String _getAutoRefreshStatus() {
    if (_isAutoRefreshing) return 'updating...';
    if (_autoRefreshFailures > 0) return 'retry';

    if (_lastFetchTime != null) {
      final now = DateTime.now();
      final minutesAgo = now.difference(_lastFetchTime!).inMinutes;
      if (minutesAgo < 1) return 'just now';
      if (minutesAgo < 60) return '${minutesAgo}m ago';
      final hoursAgo = (minutesAgo / 60).floor();
      return '${hoursAgo}h ago';
    }

    return '2min';
  }

  void _startAutoRefresh() {
    // Auto-refresh every 2 minutes when user is signed in
    _refreshTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (_user != null && mounted && !_isLoading) {
        // Add a small delay check to prevent too frequent calls
        final now = DateTime.now();

        // Implement exponential backoff for failed attempts
        final backoffMinutes =
            _autoRefreshFailures > 0
                ? 2 *
                    (1 <<
                        (_autoRefreshFailures.clamp(
                          0,
                          4,
                        ))) // Max 32 minutes backoff
                : 2;

        final timeSinceLastFetch =
            _lastFetchTime != null
                ? now.difference(_lastFetchTime!).inMinutes
                : backoffMinutes;

        if (_lastFetchTime == null || timeSinceLastFetch >= backoffMinutes) {
          _fetchComprehensiveHealthData(isAutoRefresh: true);
        }
      }
    });
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _healthDataService.googleSignIn.signIn();
      if (account == null) {
        setState(() => _debugMessage = 'Sign-in cancelled by user');
        return;
      }
      setState(() => _user = account);
      await _fetchComprehensiveHealthData();
    } catch (error) {
      setState(() => _debugMessage = 'Sign-in error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchComprehensiveHealthData({
    bool isAutoRefresh = false,
  }) async {
    if (_user == null) return;

    // Record the fetch time
    _lastFetchTime = DateTime.now();

    setState(() {
      _isLoading = !isAutoRefresh; // Don't show full loading for auto-refresh
      _isAutoRefreshing = isAutoRefresh;
      _debugMessage =
          isAutoRefresh
              ? 'Auto-refreshing health data...'
              : 'Fetching comprehensive health data...';
    });

    try {
      final result = await _healthDataService.fetchComprehensiveHealthData(
        _user!,
        _selectedDays,
      );

      setState(() {
        _timeSeriesData = result['timeSeriesData'];
        _summaryData = result['summaryData'];
        _debugMessage = result['message'];
      });
    } catch (error) {
      if (isAutoRefresh) {
        _autoRefreshFailures++;
        // For auto-refresh failures, show a less intrusive message
        setState(
          () =>
              _debugMessage =
                  'Auto-refresh failed (${_autoRefreshFailures}x). Will retry...',
        );
      } else {
        _autoRefreshFailures = 0; // Reset on manual refresh
        setState(() => _debugMessage = 'Error fetching data: $error');
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isAutoRefreshing = false;
      });

      // Reset failure count on successful fetch
      if (!isAutoRefresh) {
        _autoRefreshFailures = 0;
      }
    }
  }

  void _showDetailedView(
    String key,
    HealthMetric metric,
    List<HealthDataPoint> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(metric.icon, color: metric.color, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metric.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${data.length} data points',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            DetailedChart(data: data, metric: metric),
                            SizedBox(height: 24),
                            DetailedStats(
                              summary: _summaryData[key]!,
                              metric: metric,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainer,
      appBar:
          _user != null
              ? AppBar(
                title: Text(
                  'SmartHealth',
                  style: AppTheme.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: AppTheme.primaryMedical,
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  // Auto-refresh indicator
                  if (_lastFetchTime != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _isAutoRefreshing
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(
                          color:
                              _isAutoRefreshing
                                  ? Colors.orange.withValues(alpha: 0.5)
                                  : Colors.green.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isAutoRefreshing
                              ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange.shade300,
                                  ),
                                ),
                              )
                              : Icon(
                                Icons.sync,
                                color: Colors.green.shade300,
                                size: 12,
                              ),
                          const SizedBox(width: 4),
                          Text(
                            _getAutoRefreshStatus(),
                            style: AppTheme.labelSmall.copyWith(
                              color:
                                  _isAutoRefreshing
                                      ? Colors.orange.shade300
                                      : _autoRefreshFailures > 0
                                      ? Colors.red.shade300
                                      : Colors.green.shade300,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Manual refresh button
                  IconButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () => _fetchComprehensiveHealthData(),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white.withValues(
                        alpha: _isLoading ? 0.5 : 1.0,
                      ),
                      size: 20,
                    ),
                    tooltip: 'Refresh Now',
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedDays,
                      dropdownColor: AppTheme.primaryMedical,
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
                        if (value != null && value != _selectedDays) {
                          setState(() => _selectedDays = value);
                          if (_user != null) {
                            _fetchComprehensiveHealthData();
                          }
                        }
                      },
                    ),
                  ),
                ],
              )
              : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_user == null) {
      return _buildSignInScreen();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_timeSeriesData.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDashboard();
  }

  Widget _buildSignInScreen() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryHealthGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Text(
                'SmartHealth',
                style: AppTheme.headingLarge.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Your comprehensive health dashboard',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Connect your Google Fit account to view\npersonalized health metrics and insights',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 280),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSignIn,
                  icon: Icon(
                    Icons.login_rounded,
                    color: AppTheme.primaryMedical,
                  ),
                  label: Text(
                    'Sign in with Google',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryMedical,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryMedical,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXL,
                      vertical: AppTheme.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
              if (_debugMessage.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _debugMessage,
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          SizedBox(height: 16),
          Text(
            _debugMessage.isNotEmpty ? _debugMessage : 'Loading health data...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_usage_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No health data found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Make sure you have Google Fit data\nfor the selected time period',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchComprehensiveHealthData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
          if (_debugMessage.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                _debugMessage,
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserHeader(
            user: _user!,
            selectedDays: _selectedDays,
            metricsCount: _timeSeriesData.length,
            onRefresh: _fetchComprehensiveHealthData,
          ),
          const SizedBox(height: AppTheme.spacingM),
          SmartwatchStatsCard(
            timeSeriesData: _timeSeriesData,
            summaryData: _summaryData,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          _buildMetricCategories(),
        ],
      ),
    );
  }

  Widget _buildMetricCategories() {
    final categories = HealthUtils.groupMetricsByCategory(
      _timeSeriesData,
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppTheme.spacingM,
        mainAxisSpacing: AppTheme.spacingM,
      ),
      itemCount: metricKeys.length,
      itemBuilder: (context, index) {
        final key = metricKeys[index];
        final metric = HealthMetrics.metricsToTrack[key]!;
        final summary = _summaryData[key];
        final timeSeries = _timeSeriesData[key];

        if (summary == null || timeSeries == null) {
          return Container();
        }

        return MetricCard(
          metricKey: key,
          metric: metric,
          summary: summary,
          timeSeries: timeSeries,
          onTap: () => _showDetailedView(key, metric, timeSeries),
        );
      },
    );
  }
}
