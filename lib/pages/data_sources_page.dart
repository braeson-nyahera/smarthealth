import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'health_connect_info_page.dart';
import 'health_connect_debug_page.dart';

class DataSourcesPage extends StatelessWidget {
  const DataSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sources'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Health Data Sources',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Google Fit Card
            _buildDataSourceCard(
              icon: Icons.fitness_center,
              title: 'Google Fit',
              description:
                  'Primary health data source with comprehensive activity and fitness tracking',
              status: 'Connected',
              statusColor: Colors.green,
              details: [
                'Steps, Heart Rate, Calories',
                'Activity Recognition',
                'Sleep Data (when available)',
              ],
            ),

            const SizedBox(height: 16),

            // FitCloudPro Card
            _buildDataSourceCard(
              icon: Icons.watch,
              title: 'FitCloudPro Smartwatch',
              description:
                  'Advanced smartwatch integration for detailed health metrics',
              status: 'Connected',
              statusColor: Colors.green,
              details: [
                'Real-time Heart Rate',
                'Oxygen Saturation (SpO2)',
                'Detailed Activity Tracking',
                'Sleep Analysis',
              ],
            ),

            const SizedBox(height: 16),

            // RDfit Card
            _buildDataSourceCard(
              icon: Icons.cloud_sync,
              title: 'RDfit API',
              description:
                  'Additional health data source for enhanced coverage and backup data',
              status: ApiConfig.isRDfitConfigured ? 'Configured' : 'Demo Mode',
              statusColor:
                  ApiConfig.isRDfitConfigured ? Colors.green : Colors.orange,
              details: [
                'Heart Rate & Steps Backup',
                'Additional Calories Data',
                'Sleep Data Supplementation',
                ApiConfig.isRDfitConfigured
                    ? 'Real API Key Configured'
                    : 'Using Demo Key (Limited Data)',
              ],
            ),

            const SizedBox(height: 16),

            // Health Connect Card (NEW - Universal Smartwatch Support)
            _buildHealthConnectCard(context),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Multi-Source Integration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This app uses multiple data sources to provide comprehensive health insights. '
                    'Data from different sources is intelligently combined, with primary sources '
                    'taking precedence and additional sources filling in gaps.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Debug button for Health Connect
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HealthConnectDebugPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug Health Connect Issues'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(color: Colors.purple[600]!),
                  foregroundColor: Colors.purple[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceCard({
    required IconData icon,
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required List<String> details,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(detail, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Health Connect card with universal smartwatch support info
  Widget _buildHealthConnectCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple[50]!, Colors.purple[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🩺 Health Connect',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple[600],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Universal smartwatch support including blood pressure',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '✅ Supported Devices:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Column(
                children: [
                  _DeviceItem(icon: '⌚', text: 'Oraimo smartwatches'),
                  _DeviceItem(icon: '📱', text: 'Samsung Galaxy Watch'),
                  _DeviceItem(icon: '🔵', text: 'Fitbit devices'),
                  _DeviceItem(icon: '🟢', text: 'Garmin watches'),
                  _DeviceItem(icon: '🍎', text: 'Apple Watch (via HealthKit)'),
                  _DeviceItem(icon: '➕', text: 'And 50+ other brands'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthConnectInfoPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Health Connect Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceItem extends StatelessWidget {
  final String icon;
  final String text;

  const _DeviceItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
