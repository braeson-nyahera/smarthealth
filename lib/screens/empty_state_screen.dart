import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class EmptyStateScreen extends StatelessWidget {
  final String debugMessage;
  final VoidCallback onRefresh;
  const EmptyStateScreen({
    super.key,
    required this.debugMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_usage_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No health data found',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.textSecondaryDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Make sure you have Google Fit data\nfor the selected time period',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textTertiaryDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMedical,
              foregroundColor: Colors.white,
            ),
          ),
          if (debugMessage.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.warning),
              ),
              child: Text(
                debugMessage,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.warning),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
