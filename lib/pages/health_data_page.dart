import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/health_models.dart';
import '../constants/app_theme.dart';
import '../services/health_data_service.dart';
import '../services/prediction_scheduler_service.dart';
import '../widgets/detailed_chart.dart';
import '../widgets/detailed_stats.dart';
import '../screens/main_app_screen.dart';
import '../screens/login_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/empty_state_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/profile_page.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import 'data_sources_page.dart';

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({super.key});

  @override
  State<HealthDataPage> createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  final HealthDataService _healthDataService = HealthDataService();
  final PredictionSchedulerService _predictionScheduler =
      PredictionSchedulerService();

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
    _checkExistingSession();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _predictionScheduler.stopScheduler();
    // Don't automatically sign out on dispose - let user stay signed in
    // Only sign out when they explicitly choose to do so
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

  Future<void> _checkExistingSession() async {
    try {
      // Don't auto-login if user manually signed out
      final wasManuallySignedOut =
          await UserProfileService.wasManuallySignedOut();
      if (wasManuallySignedOut) {
        debugPrint('Skipping auto-login due to manual sign-out');
        return;
      }

      // Check if user has a saved session
      final hasSession = await UserProfileService.hasUserSession();
      if (!hasSession) return;

      // Try to sign in silently with Google
      final account = await _healthDataService.googleSignIn.signInSilently();
      if (account != null) {
        setState(() {
          _user = account;
          _debugMessage = 'Welcome back, ${account.displayName ?? 'User'}!';
        });

        // Check profile setup status
        await _checkProfileSetupStatus();

        // Fetch health data if profile is complete
        if (!_showProfileSetup) {
          await _fetchComprehensiveHealthData();

          // Start prediction scheduler for returning users
          await _startPredictionScheduler();
        }
      } else {
        // Silent sign-in failed, clear invalid session
        await UserProfileService.clearProfile();
      }
    } catch (error) {
      debugPrint('Auto-login failed: $error');
      // Clear invalid session
      await UserProfileService.clearProfile();
    }
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

      // Save user session for auto-login
      await UserProfileService.saveUserSession(
        email: account.email,
        displayName: account.displayName ?? 'User',
        photoUrl: account.photoUrl,
      );

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

    // Start the prediction scheduler (every 3 hours)
    await _startPredictionScheduler();
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
              onSignOut: () async {
                // Handle sign out from profile page
                try {
                  // Ensure Google sign-out is complete
                  await _healthDataService.googleSignIn.signOut();
                  await _healthDataService.googleSignIn.disconnect();
                } catch (e) {
                  debugPrint('Error during Google sign-out: $e');
                }

                setState(() {
                  _user = null;
                  _timeSeriesData = {};
                  _summaryData = {};
                  _showProfileSetup = false;
                  _userProfile = null;
                  _debugMessage = 'Signed out successfully';
                });
              },
            ),
      ),
    );

    // Check if user was signed out and refresh state if needed
    if (_user == null) {
      final hasSession = await UserProfileService.hasUserSession();
      if (!hasSession) {
        // User was signed out, refresh the page state
        setState(() {
          _debugMessage = 'Please sign in to continue';
        });
      }
    }
  }

  void _showDataSourcesPage(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const DataSourcesPage()));
  }

  Future<void> _startPredictionScheduler() async {
    try {
      debugPrint('🔮 Starting hypertension prediction scheduler...');

      // Start the scheduler with immediate first run
      await _predictionScheduler.startScheduler(
        healthDataService: _healthDataService,
        user: _user,
        runImmediately: true, // Run first prediction immediately
      );

      // Add listener to update UI when predictions complete
      _predictionScheduler.addListener((prediction) {
        if (mounted) {
          setState(() {
            debugPrint(
              '📊 New prediction received: ${prediction.riskLevel.label}',
            );
          });
        }
      });

      debugPrint('✅ Prediction scheduler started successfully');
    } catch (e) {
      debugPrint('❌ Error starting prediction scheduler: $e');
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
      // Try universal health data (now prioritizes full time series from Google Fit)
      final universalResult = await _healthDataService.fetchUniversalHealthData(
        _user,
        _selectedDays,
      );

      debugPrint('🔍 Universal result keys: ${universalResult.keys.toList()}');

      // Check if this is full time series data or summary data
      if (universalResult.containsKey('timeSeriesData') &&
          universalResult.containsKey('summaryData')) {
        // This is full Google Fit format with time series data
        final timeSeriesData =
            universalResult['timeSeriesData']
                as Map<String, List<HealthDataPoint>>;
        final totalPoints = timeSeriesData.values.fold(
          0,
          (sum, list) => sum + list.length,
        );
        debugPrint(
          '📊 Processing full time series data format with $totalPoints data points',
        );

        setState(() {
          _timeSeriesData = universalResult['timeSeriesData'];
          _summaryData = universalResult['summaryData'];

          // Enhanced message with data point counts
          String message =
              universalResult['message'] as String? ?? 'Data loaded';
          message += '\n📈 Total data points: $totalPoints';

          // Show breakdown by metric
          timeSeriesData.forEach((key, points) {
            if (points.isNotEmpty) {
              message += '\n  • $key: ${points.length} points';
            }
          });

          // Check if we have Health Connect blood pressure to supplement
          if (universalResult.containsKey('health_connect_bp')) {
            message += '\n🩺 Blood pressure data available via Health Connect!';
          }
          _debugMessage = message;
        });
      } else if (universalResult.isNotEmpty &&
          _hasValidHealthData(universalResult)) {
        // This is summary format from Health Connect
        debugPrint('📱 Processing Health Connect summary data format');
        setState(() {
          _timeSeriesData = _convertUniversalToTimeSeries(universalResult);
          _summaryData = _convertUniversalToSummary(universalResult);
          _debugMessage = _buildUniversalDataMessage(universalResult);
        });
      } else {
        // Fallback to traditional Google Fit method (shouldn't happen with new logic)
        debugPrint('⚠️ Fallback to traditional Google Fit method');
        final result = await _healthDataService.fetchComprehensiveHealthData(
          _user!,
          _selectedDays,
        );

        setState(() {
          _timeSeriesData = result['timeSeriesData'];
          _summaryData = result['summaryData'];
          _debugMessage = result['message'];
        });
      }
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
                  // Data sources button
                  IconButton(
                    onPressed: () => _showDataSourcesPage(context),
                    icon: const Icon(
                      Icons.storage_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Data Sources',
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

    return MainAppScreen(
      user: _user!,
      selectedDays: _selectedDays,
      timeSeriesData: _timeSeriesData,
      summaryData: _summaryData,
      onRefresh: _fetchComprehensiveHealthData,
      onShowDetail: _showDetailedView,
      onProfileTap: _showProfile,
      predictionScheduler: _predictionScheduler,
    );
  }

  /// Check if universal health data has valid content
  bool _hasValidHealthData(Map<String, dynamic> data) {
    final steps = data['steps'] as int? ?? 0;
    final heartRate = data['heart_rate_avg'] as int? ?? 0;
    final bloodPressure = data['blood_pressure_available'] as bool? ?? false;
    final dataSources = data['data_sources'] as List<String>? ?? [];

    return steps > 0 ||
        heartRate > 0 ||
        bloodPressure ||
        dataSources.isNotEmpty;
  }

  /// Convert universal health data to time series format
  Map<String, List<HealthDataPoint>> _convertUniversalToTimeSeries(
    Map<String, dynamic> data,
  ) {
    Map<String, List<HealthDataPoint>> timeSeries = {};
    final now = DateTime.now();

    // Steps
    if ((data['steps'] as int? ?? 0) > 0) {
      timeSeries['steps'] = [
        HealthDataPoint(
          value: (data['steps'] as int).toDouble(),
          timestamp: now,
        ),
      ];
    }

    // Heart Rate
    if ((data['heart_rate_avg'] as int? ?? 0) > 0) {
      timeSeries['heart_rate'] = [
        HealthDataPoint(
          value: (data['heart_rate_avg'] as int).toDouble(),
          timestamp: now,
        ),
      ];
    }

    // Blood Pressure (NEW - from Health Connect)
    if ((data['blood_pressure_systolic'] as int? ?? 0) > 0) {
      timeSeries['blood_pressure_systolic'] = [
        HealthDataPoint(
          value: (data['blood_pressure_systolic'] as int).toDouble(),
          timestamp: now,
        ),
      ];
    }

    if ((data['blood_pressure_diastolic'] as int? ?? 0) > 0) {
      timeSeries['blood_pressure_diastolic'] = [
        HealthDataPoint(
          value: (data['blood_pressure_diastolic'] as int).toDouble(),
          timestamp: now,
        ),
      ];
    }

    // Oxygen Saturation
    if ((data['oxygen_saturation_avg'] as int? ?? 0) > 0) {
      timeSeries['oxygen_saturation'] = [
        HealthDataPoint(
          value: (data['oxygen_saturation_avg'] as int).toDouble(),
          timestamp: now,
        ),
      ];
    }

    // Calories
    if ((data['calories'] as int? ?? 0) > 0) {
      timeSeries['calories'] = [
        HealthDataPoint(
          value: (data['calories'] as int).toDouble(),
          timestamp: now,
        ),
      ];
    }

    return timeSeries;
  }

  /// Convert universal health data to summary format
  Map<String, HealthSummary> _convertUniversalToSummary(
    Map<String, dynamic> data,
  ) {
    Map<String, HealthSummary> summary = {};
    debugPrint(
      '🔄 Converting universal data to summary: ${data.keys.toList()}',
    );

    // Steps
    final steps = (data['steps'] as int? ?? 0).toDouble();
    debugPrint('📊 Converting steps data: $steps');
    if (steps > 0) {
      summary['steps'] = HealthSummary(
        average: steps,
        min: steps,
        max: steps,
        latest: steps,
        trend: 0.0,
      );
      debugPrint('✅ Steps summary created with value: $steps');
    } else {
      debugPrint('❌ No steps data - steps = $steps');
    }

    // Heart Rate
    final heartRate = (data['heart_rate_avg'] as int? ?? 0).toDouble();
    if (heartRate > 0) {
      summary['heart_rate'] = HealthSummary(
        average: heartRate,
        min: heartRate,
        max: heartRate,
        latest: heartRate,
        trend: 0.0,
      );
    }

    // Blood Pressure Systolic (NEW)
    final systolic = (data['blood_pressure_systolic'] as int? ?? 0).toDouble();
    if (systolic > 0) {
      summary['blood_pressure_systolic'] = HealthSummary(
        average: systolic,
        min: systolic,
        max: systolic,
        latest: systolic,
        trend: 0.0,
      );
    }

    // Blood Pressure Diastolic (NEW)
    final diastolic =
        (data['blood_pressure_diastolic'] as int? ?? 0).toDouble();
    if (diastolic > 0) {
      summary['blood_pressure_diastolic'] = HealthSummary(
        average: diastolic,
        min: diastolic,
        max: diastolic,
        latest: diastolic,
        trend: 0.0,
      );
    }

    // Oxygen Saturation
    final oxygen = (data['oxygen_saturation_avg'] as int? ?? 0).toDouble();
    if (oxygen > 0) {
      summary['oxygen_saturation'] = HealthSummary(
        average: oxygen,
        min: oxygen,
        max: oxygen,
        latest: oxygen,
        trend: 0.0,
      );
    }

    // Calories
    final calories = (data['calories'] as int? ?? 0).toDouble();
    if (calories > 0) {
      summary['calories'] = HealthSummary(
        average: calories,
        min: calories,
        max: calories,
        latest: calories,
        trend: 0.0,
      );
    }

    return summary;
  }

  /// Build debug message for universal data
  String _buildUniversalDataMessage(Map<String, dynamic> data) {
    final dataSources = data['data_sources'] as List<String>? ?? [];
    final bloodPressureAvailable =
        data['blood_pressure_available'] as bool? ?? false;
    final steps = data['steps'] as int? ?? 0;
    final heartRate = data['heart_rate_avg'] as int? ?? 0;

    if (dataSources.isEmpty) {
      return 'No health data sources available';
    }

    String message = '📱 Connected: ${dataSources.join(', ')}\n';

    if (bloodPressureAvailable) {
      message += '🩺 Blood pressure data available!\n';
    }

    if (steps > 0) {
      message += '👟 Steps: ${steps.toString()}\n';
    }

    if (heartRate > 0) {
      message += '❤️ Heart rate: ${heartRate}bpm\n';
    }

    message +=
        '\n✅ Universal smartwatch support active (Oraimo, Samsung, Fitbit, etc.)';

    return message;
  }
}
