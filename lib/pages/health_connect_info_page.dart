import 'package:flutter/material.dart';
import '../services/health_connect_service.dart';
import '../constants/app_theme.dart';

/// Page to display Health Connect information and capabilities
class HealthConnectInfoPage extends StatefulWidget {
  const HealthConnectInfoPage({super.key});

  @override
  State<HealthConnectInfoPage> createState() => _HealthConnectInfoPageState();
}

class _HealthConnectInfoPageState extends State<HealthConnectInfoPage> {
  final HealthConnectService _healthConnectService = HealthConnectService();
  bool _isLoading = true;
  bool _isAvailable = false;
  Map<String, dynamic> _dataSourceInfo = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkHealthConnect();
  }

  Future<void> _checkHealthConnect() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check availability
      _isAvailable = await _healthConnectService.isAvailable();

      // Get data source info
      _dataSourceInfo = await _healthConnectService.getDataSources();

      // Try to initialize
      if (_isAvailable) {
        await _healthConnectService.initialize();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testHealthData() async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health Connect not available')),
      );
      return;
    }

    try {
      final healthData = await _healthConnectService.getHealthData();

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('🩺 Health Connect Test Results'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Data Source: ${healthData['data_source']}'),
                      const SizedBox(height: 8),
                      Text('Steps: ${healthData['steps']}'),
                      Text('Heart Rate: ${healthData['heart_rate_avg']} bpm'),
                      Text(
                        'Blood Pressure: ${healthData['blood_pressure_systolic_avg']}/${healthData['blood_pressure_diastolic_avg']} mmHg',
                      ),
                      Text('Oxygen: ${healthData['oxygen_saturation_avg']}%'),
                      Text('Calories: ${healthData['calories']}'),
                      Text('Distance: ${healthData['distance']} km'),
                      Text('Sleep: ${healthData['sleep_hours']} hrs'),
                      const SizedBox(height: 16),
                      if (healthData['blood_pressure_systolic_avg'] > 0 ||
                          healthData['blood_pressure_diastolic_avg'] > 0)
                        const Text('✅ Blood pressure data found!')
                      else
                        const Text('ℹ️ No blood pressure data yet'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Test failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🩺 Health Connect Info'),
        backgroundColor: AppTheme.primaryMedical,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildCapabilitiesCard(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildSupportedDevicesCard(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildTestButton(),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingL),
                      _buildErrorCard(),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 Health Connect Status',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Icon(
                  _isAvailable ? Icons.check_circle : Icons.error,
                  color: _isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  _isAvailable ? 'Available' : 'Not Available',
                  style: TextStyle(
                    color: _isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (_isAvailable) ...[
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                '✅ Universal smartwatch support active!\n'
                'Your app can now access health data from Oraimo, Samsung, Fitbit, Garmin, Apple Watch, and 50+ other devices through Health Connect.',
                style: TextStyle(color: Colors.green),
              ),
            ] else ...[
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                '❌ Health Connect not available on this device.\n'
                'This feature requires Android 14+ or iOS with HealthKit.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 Health Connect Capabilities',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingM),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CapabilityItem(icon: '🩺', text: 'Blood pressure readings'),
                _CapabilityItem(icon: '❤️', text: 'Heart rate monitoring'),
                _CapabilityItem(icon: '🫁', text: 'Blood oxygen levels'),
                _CapabilityItem(icon: '👟', text: 'Step counting'),
                _CapabilityItem(icon: '🔥', text: 'Calorie tracking'),
                _CapabilityItem(icon: '😴', text: 'Sleep analysis'),
                _CapabilityItem(icon: '📏', text: 'Distance tracking'),
                _CapabilityItem(icon: '⚖️', text: 'Weight & body metrics'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedDevicesCard() {
    final supportedDevices =
        _dataSourceInfo['supported_devices'] as List<String>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⌚ Supported Smartwatches & Devices',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (supportedDevices.isNotEmpty)
              ...supportedDevices.map(
                (device) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 16),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(child: Text(device)),
                    ],
                  ),
                ),
              )
            else
              const Text('Loading supported devices...'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAvailable ? _testHealthData : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Test Health Connect Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryMedical,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(AppTheme.spacingL),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: AppTheme.spacingS),
                Text(
                  'Error Details',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(_errorMessage),
          ],
        ),
      ),
    );
  }
}

class _CapabilityItem extends StatelessWidget {
  final String icon;
  final String text;

  const _CapabilityItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
