import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  final String debugMessage;
  const LoadingScreen({super.key, required this.debugMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMedical),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            debugMessage.isNotEmpty ? debugMessage : 'Loading health data...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
