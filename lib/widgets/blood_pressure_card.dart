import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../constants/app_theme.dart';

/// Widget to display blood pressure data with prediction indicator
class BloodPressureCard extends StatelessWidget {
  final HealthSummary? systolicSummary;
  final HealthSummary? diastolicSummary;
  final HealthSummary? predictionMetadata;
  final List<HealthDataPoint>? systolicData;
  final List<HealthDataPoint>? diastolicData;
  final VoidCallback? onTap;

  const BloodPressureCard({
    super.key,
    this.systolicSummary,
    this.diastolicSummary,
    this.predictionMetadata,
    this.systolicData,
    this.diastolicData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (systolicSummary == null || diastolicSummary == null) {
      return const SizedBox.shrink();
    }

    final systolic = systolicSummary!.latest.round();
    final diastolic = diastolicSummary!.latest.round();
    final isPredicted = predictionMetadata != null;
    final confidence = isPredicted ? predictionMetadata!.latest : 1.0;

    // Classify BP
    final category = _classifyBP(systolic, diastolic);
    final categoryColor = _getCategoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor.withOpacity(0.1),
                categoryColor.withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Icon(Icons.favorite, color: categoryColor, size: 24),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Blood Pressure',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isPredicted) ...[
                              const SizedBox(width: AppTheme.spacingS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blue.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'AI Predicted',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          category,
                          style: AppTheme.bodySmall.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondaryDark,
                    ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingL),

              // BP Reading
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Systolic
                  Column(
                    children: [
                      Text(
                        systolic.toString(),
                        style: AppTheme.headingLarge.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        'Systolic',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                    ),
                    child: Text(
                      '/',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.textSecondaryDark,
                        fontSize: 40,
                      ),
                    ),
                  ),

                  // Diastolic
                  Column(
                    children: [
                      Text(
                        diastolic.toString(),
                        style: AppTheme.headingLarge.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        'Diastolic',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingM),

              // Unit
              Center(
                child: Text(
                  'mmHg',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (isPredicted) ...[
                const SizedBox(height: AppTheme.spacingL),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Predicted from your health data',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Confidence: ${(confidence * 100).toStringAsFixed(0)}% • Based on heart rate, activity & sleep',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.blue.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.spacingM),

              // Recommendation
              _buildRecommendation(category, categoryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendation(String category, Color color) {
    String recommendation;
    IconData icon;

    switch (category) {
      case 'Normal':
        recommendation =
            'Your blood pressure is healthy. Keep up the good work!';
        icon = Icons.check_circle;
        break;
      case 'Elevated':
        recommendation = 'Consider lifestyle changes to prevent hypertension';
        icon = Icons.warning_amber;
        break;
      case 'Stage 1 Hypertension':
        recommendation = 'Consult with a healthcare provider';
        icon = Icons.medical_services;
        break;
      case 'Stage 2 Hypertension':
        recommendation = 'Seek medical attention promptly';
        icon = Icons.emergency;
        break;
      default:
        recommendation = 'Monitor your blood pressure regularly';
        icon = Icons.monitor_heart;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              recommendation,
              style: AppTheme.bodySmall.copyWith(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _classifyBP(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return 'Elevated';
    } else if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) {
      return 'Stage 1 Hypertension';
    } else if (systolic >= 140 || diastolic >= 90) {
      return 'Stage 2 Hypertension';
    } else {
      return 'Low Blood Pressure';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Normal':
        return Colors.green;
      case 'Elevated':
        return Colors.orange;
      case 'Stage 1 Hypertension':
        return Colors.deepOrange;
      case 'Stage 2 Hypertension':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
