import 'package:flutter/material.dart';
import '../widgets/hypertension_risk_card.dart';
import '../constants/app_theme.dart';
import '../services/prediction_scheduler_service.dart';

/// Screen dedicated to displaying hypertension risk assessment
class RiskAssessmentScreen extends StatelessWidget {
  final PredictionSchedulerService? predictionScheduler;

  const RiskAssessmentScreen({super.key, this.predictionScheduler});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hypertension Risk Assessment',
            style: AppTheme.headingLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Comprehensive analysis of your hypertension risk based on your health metrics',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          if (predictionScheduler == null ||
              predictionScheduler!.latestPrediction == null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outlined,
                    color: Colors.blue.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No Assessment Available',
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Please ensure you have completed your health profile setup and have sufficient health data collected. The system needs at least 7 days of blood pressure data for accurate predictions.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                HypertensionRiskCard(
                  prediction: predictionScheduler!.latestPrediction!,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Text(
                              'Important Medical Disclaimer',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'This assessment is for informational purposes only and should not replace professional medical advice. Please consult with your healthcare provider for diagnosis and treatment decisions.',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
