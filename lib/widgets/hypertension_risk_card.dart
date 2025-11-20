import 'package:flutter/material.dart';
import '../models/hypertension_risk_models.dart';
import '../constants/app_theme.dart';

/// Widget to display hypertension risk prediction results
class HypertensionRiskCard extends StatelessWidget {
  final HypertensionPrediction prediction;
  final VoidCallback? onLearnMore;

  const HypertensionRiskCard({
    super.key,
    required this.prediction,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              prediction.riskLevel.color.withOpacity(0.1),
              prediction.riskLevel.color.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    color: prediction.riskLevel.color,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hypertension Risk Assessment',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Based on ${prediction.contributingFactors.length} factors',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Risk Level Display
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: prediction.riskLevel.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: prediction.riskLevel.color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      prediction.riskLevel.icon,
                      color: prediction.riskLevel.color,
                      size: 32,
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prediction.riskLevel.label,
                            style: AppTheme.headingSmall.copyWith(
                              color: prediction.riskLevel.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Risk Score: ${prediction.riskScore.toStringAsFixed(0)}/100',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Confidence indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.analytics,
                            size: 14,
                            color: AppTheme.textSecondaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    // Model health indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: prediction.modelHealthColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(
                          color: prediction.modelHealthColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            prediction.method == 'clinical_override'
                                ? Icons.verified
                                : prediction.method == 'ml_model'
                                ? Icons.cloud_done
                                : Icons.computer,
                            size: 14,
                            color: prediction.modelHealthColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            prediction.modelHealth,
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: prediction.modelHealthColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Clinical Reason Display
              if (prediction.clinicalReason != null &&
                  prediction.clinicalReason!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.purple,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinical Classification',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              prediction.clinicalReason!,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppTheme.spacingL),

              // Model source indicator
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: (prediction.method == 'ml_model'
                          ? Colors.blue
                          : prediction.method == 'clinical_override'
                          ? Colors.purple
                          : Colors.amber)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: (prediction.method == 'ml_model'
                            ? Colors.blue
                            : prediction.method == 'clinical_override'
                            ? Colors.purple
                            : Colors.amber)
                        .withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      prediction.method == 'ml_model'
                          ? Icons.cloud_queue
                          : prediction.method == 'clinical_override'
                          ? Icons.verified_user
                          : Icons.warning_amber_rounded,
                      color:
                          prediction.method == 'ml_model'
                              ? Colors.blue
                              : prediction.method == 'clinical_override'
                              ? Colors.purple
                              : Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prediction.method == 'ml_model'
                                ? 'ML Model Analysis'
                                : prediction.method == 'clinical_override'
                                ? 'Clinically Validated'
                                : 'Rule-Based Analysis',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  prediction.method == 'ml_model'
                                      ? Colors.blue
                                      : prediction.method == 'clinical_override'
                                      ? Colors.purple
                                      : Colors.amber,
                            ),
                          ),
                          Text(
                            prediction.method == 'ml_model'
                                ? 'Scientifically-backed assessment'
                                : prediction.method == 'clinical_override'
                                ? 'Clinically-backed assessment'
                                : 'Guidelines-based assessment',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Contributing Factors
              if (prediction.contributingFactors.isNotEmpty) ...[
                Text(
                  'Key Contributing Factors',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                ...prediction.contributingFactors.take(3).map((factor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: prediction.riskLevel.color,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Text(factor, style: AppTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                }),
                if (prediction.contributingFactors.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingXS),
                    child: Text(
                      '+${prediction.contributingFactors.length - 3} more factors',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryDark,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: AppTheme.spacingL),

              // Recommendations Preview
              if (prediction.recommendations.isNotEmpty) ...[
                Text(
                  'Top Recommendations',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                ...prediction.recommendations.take(3).map((recommendation) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: AppTheme.spacingM),

              // Learn More Button
              if (onLearnMore != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLearnMore,
                    icon: Icon(Icons.info_outline),
                    label: Text('View Detailed Analysis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: prediction.riskLevel.color,
                      side: BorderSide(color: prediction.riskLevel.color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),
                ),

              // Prediction metadata
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingS),
                child: Text(
                  'Updated: ${_formatDate(prediction.predictionDate)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Detailed risk analysis page
class HypertensionRiskDetailPage extends StatelessWidget {
  final HypertensionPrediction prediction;

  const HypertensionRiskDetailPage({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Risk Assessment Details'),
        backgroundColor: AppTheme.primaryMedical,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk Overview
            _buildRiskOverview(),

            const SizedBox(height: AppTheme.spacingXL),

            // All Contributing Factors
            _buildSection(
              'Contributing Factors',
              Icons.warning_amber,
              prediction.contributingFactors,
              prediction.riskLevel.color,
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // All Recommendations
            _buildSection(
              'Recommendations',
              Icons.check_circle,
              prediction.recommendations,
              AppTheme.success,
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // Future Projections
            if (prediction.futureProjections.isNotEmpty)
              _buildFutureProjections(),

            const SizedBox(height: AppTheme.spacingXL),

            // Disclaimer
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskOverview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: prediction.riskLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: prediction.riskLevel.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            prediction.riskLevel.icon,
            size: 64,
            color: prediction.riskLevel.color,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            prediction.riskLevel.label,
            style: AppTheme.headingLarge.copyWith(
              color: prediction.riskLevel.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Risk Score: ${prediction.riskScore.toStringAsFixed(1)}/100',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Confidence: ${(prediction.confidence * 100).toStringAsFixed(0)}%',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<String> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              title,
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(child: Text(item, style: AppTheme.bodyMedium)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFutureProjections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: AppTheme.primaryMedical),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              'Future Projections',
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...prediction.futureProjections.entries.map((entry) {
          final days = entry.key
              .replaceAll('_', ' ')
              .replaceAll('days', 'Days');
          final value = entry.value.toStringAsFixed(0);
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('$value mmHg', style: AppTheme.bodyMedium),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber[900], size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              'This prediction is for informational purposes only and should not replace professional medical advice. Always consult with a healthcare provider for accurate diagnosis and treatment.',
              style: AppTheme.bodySmall.copyWith(color: Colors.amber[900]),
            ),
          ),
        ],
      ),
    );
  }
}
