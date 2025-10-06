import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/health_models.dart';
import '../constants/app_theme.dart';
import '../services/health_data_service.dart';
import '../widgets/detailed_chart.dart';
import '../widgets/detailed_stats.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/empty_state_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/profile_page.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

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
  bool _showProfileSetup = false;
  UserProfile? _userProfile;

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

      // Check if user needs to complete profile setup
      await _checkProfileSetupStatus();

      if (!_showProfileSetup) {
        await _fetchComprehensiveHealthData();
      }
    } catch (error) {
      setState(() => _debugMessage = 'Sign-in error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkProfileSetupStatus() async {
    try {
      final profileCompleted = await UserProfileService.isProfileCompleted();
      final existingProfile = await UserProfileService.loadProfile();

      debugPrint(
        'Profile check - completed: $profileCompleted, existing: $existingProfile',
      );

      setState(() {
        _showProfileSetup = !profileCompleted;
        _userProfile = existingProfile;
      });
    } catch (e) {
      debugPrint('Error checking profile setup status: $e');
      // Default to not showing profile setup on error
      setState(() {
        _showProfileSetup = false;
      });
    }
  }

  Future<void> _onProfileSetupComplete() async {
    debugPrint('Profile setup completed callback triggered');

    setState(() {
      _showProfileSetup = false;
    });

    // Load the saved profile
    final profile = await UserProfileService.loadProfile();
    debugPrint('Loaded profile after completion: $profile');

    setState(() {
      _userProfile = profile;
    });

    // Now fetch health data
    await _fetchComprehensiveHealthData();
  }

  void _showProfile() async {
    if (_user == null || _userProfile == null) {
      // Show profile setup if no profile exists
      setState(() {
        _showProfileSetup = true;
      });
      return;
    }

    // Navigate to profile page
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ProfilePage(
              user: _user!,
              existingProfile: _userProfile,
              onProfileUpdated: () async {
                // Reload profile after update
                final updatedProfile = await UserProfileService.loadProfile();
                setState(() {
                  _userProfile = updatedProfile;
                });
              },
            ),
      ),
    );
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
      return LoginScreen(
        isLoading: _isLoading,
        onSignIn: _handleSignIn,
        debugMessage: _debugMessage,
      );
    }

    if (_showProfileSetup) {
      return ProfileSetupScreen(
        onComplete: _onProfileSetupComplete,
        existingProfile: _userProfile,
      );
    }

    if (_isLoading) {
      return LoadingScreen(debugMessage: _debugMessage);
    }

    if (_timeSeriesData.isEmpty) {
      return EmptyStateScreen(
        debugMessage: _debugMessage,
        onRefresh: _fetchComprehensiveHealthData,
      );
    }

    return DashboardScreen(
      user: _user!,
      selectedDays: _selectedDays,
      timeSeriesData: _timeSeriesData,
      summaryData: _summaryData,
      onRefresh: _fetchComprehensiveHealthData,
      onShowDetail: _showDetailedView,
      onProfileTap: _showProfile,
    );
  }
}
