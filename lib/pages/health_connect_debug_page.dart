import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../constants/app_theme.dart';

/// Debug page to diagnose Health Connect issues
class HealthConnectDebugPage extends StatefulWidget {
  const HealthConnectDebugPage({super.key});

  @override
  State<HealthConnectDebugPage> createState() => _HealthConnectDebugPageState();
}

class _HealthConnectDebugPageState extends State<HealthConnectDebugPage> {
  final List<String> _logs = [];
  bool _isChecking = false;
  Health? _health;

  @override
  void initState() {
    super.initState();
    _health = Health();
    _runDiagnostics();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().split('.')[0]}] $message');
    });
    debugPrint(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isChecking = true;
      _logs.clear();
    });

    _addLog('🔍 Starting Health Connect diagnostics...');
    _addLog('');

    try {
      // Step 1: Check platform
      _addLog('📱 Platform Information:');
      _addLog('   Platform: Android');
      _addLog('');

      // Step 2: Configure Health
      _addLog('⚙️ Configuring Health package...');
      try {
        _health!.configure();
        _addLog('   ✅ Health package configured successfully');
      } catch (e) {
        _addLog('   ❌ Failed to configure: $e');
      }
      _addLog('');

      // Step 3: Check basic permission
      _addLog('🔐 Checking permissions...');
      try {
        final hasPermission = await _health!.hasPermissions(
          [HealthDataType.STEPS],
          permissions: [HealthDataAccess.READ],
        );
        _addLog('   Result: $hasPermission');
        if (hasPermission == null) {
          _addLog('   ❌ Health Connect not available (returned null)');
          _addLog(
            '   💡 This usually means Health Connect app is not installed',
          );
        } else if (hasPermission == false) {
          _addLog('   ⚠️ Health Connect available but permission not granted');
        } else {
          _addLog('   ✅ Permission granted!');
        }
      } catch (e) {
        _addLog('   ❌ Permission check failed: $e');
      }
      _addLog('');

      // Step 4: Request permissions
      _addLog('📝 Requesting permissions...');
      try {
        final granted = await _health!.requestAuthorization(
          [
            HealthDataType.STEPS,
            HealthDataType.HEART_RATE,
            HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
          ],
          permissions: [
            HealthDataAccess.READ,
            HealthDataAccess.READ,
            HealthDataAccess.READ,
          ],
        );
        _addLog('   Result: $granted');
        if (granted) {
          _addLog('   ✅ Permissions granted successfully!');
        } else {
          _addLog('   ❌ Permissions denied or Health Connect unavailable');
        }
      } catch (e) {
        _addLog('   ❌ Authorization request failed: $e');
      }
      _addLog('');

      // Step 5: Try to fetch data
      _addLog('📊 Attempting to fetch sample data...');
      try {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final healthData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: yesterday,
          endTime: now,
        );

        _addLog('   Data points retrieved: ${healthData.length}');
        if (healthData.isEmpty) {
          _addLog(
            '   ⚠️ No data found (this might be normal if no steps recorded)',
          );
        } else {
          _addLog('   ✅ Successfully retrieved health data!');
          _addLog('   Sample: ${healthData.first.value} steps');
        }
      } catch (e) {
        _addLog('   ❌ Data fetch failed: $e');
      }
      _addLog('');

      // Final diagnosis
      _addLog('📋 DIAGNOSIS:');
      _addLog('──────────────────────────────────');

      final hasPermission = await _health!.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );

      if (hasPermission == null) {
        _addLog('❌ Health Connect NOT INSTALLED');
        _addLog('');
        _addLog('💡 Solution:');
        _addLog('   1. Open Google Play Store');
        _addLog('   2. Search for "Health Connect"');
        _addLog('   3. Install "Health Connect by Google"');
        _addLog('   4. Restart this app');
      } else if (hasPermission == false) {
        _addLog('⚠️ Health Connect INSTALLED but NOT AUTHORIZED');
        _addLog('');
        _addLog('💡 Solution:');
        _addLog('   1. Click "Request Permissions" button above');
        _addLog('   2. Grant all requested permissions');
        _addLog('   3. Or open Settings > Apps > Health Connect');
        _addLog('   4. Grant permissions manually');
      } else {
        _addLog('✅ Health Connect WORKING CORRECTLY!');
        _addLog('');
        _addLog('   Everything is configured properly.');
        _addLog('   You can now use all health features.');
      }
    } catch (e) {
      _addLog('');
      _addLog('💥 CRITICAL ERROR: $e');
    }

    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Connect Diagnostics'),
        backgroundColor: AppTheme.primaryMedical,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isChecking ? null : _runDiagnostics,
            tooltip: 'Run diagnostics again',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isChecking ? Colors.blue[100] : Colors.green[100],
            child: Row(
              children: [
                if (_isChecking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isChecking
                        ? 'Running diagnostics...'
                        : 'Diagnostics complete',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isChecking ? Colors.blue[900] : Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color:
                          log.contains('❌')
                              ? Colors.red[700]
                              : log.contains('✅')
                              ? Colors.green[700]
                              : log.contains('⚠️')
                              ? Colors.orange[700]
                              : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isChecking ? null : _runDiagnostics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Run Diagnostics Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMedical,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final granted = await _health!.requestAuthorization([
                        HealthDataType.STEPS,
                        HealthDataType.HEART_RATE,
                        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
                        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
                        HealthDataType.BLOOD_OXYGEN,
                      ]);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              granted
                                  ? 'Permissions granted!'
                                  : 'Permissions denied',
                            ),
                            backgroundColor:
                                granted ? Colors.green : Colors.red,
                          ),
                        );

                        if (granted) {
                          await Future.delayed(const Duration(seconds: 1));
                          _runDiagnostics();
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Request Permissions'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
