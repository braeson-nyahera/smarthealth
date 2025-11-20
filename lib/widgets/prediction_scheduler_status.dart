import 'package:flutter/material.dart';
import '../services/prediction_scheduler_service.dart';
import '../constants/app_theme.dart';

/// Widget to display prediction scheduler status
class PredictionSchedulerStatus extends StatefulWidget {
  final PredictionSchedulerService scheduler;

  const PredictionSchedulerStatus({super.key, required this.scheduler});

  @override
  State<PredictionSchedulerStatus> createState() =>
      _PredictionSchedulerStatusState();
}

class _PredictionSchedulerStatusState extends State<PredictionSchedulerStatus> {
  @override
  Widget build(BuildContext context) {
    final latestPrediction = widget.scheduler.latestPrediction;
    final lastPredictionTime = widget.scheduler.lastPredictionTime;
    final timeUntilNext = widget.scheduler.timeUntilNextPrediction;
    final isRunning = widget.scheduler.isRunning;

    // Don't show if scheduler is not running
    if (!isRunning) {
      debugPrint('🔍 Scheduler status widget: Not running');
      return const SizedBox.shrink();
    }

    debugPrint(
      '🔍 Scheduler status widget: Running - Has prediction: ${latestPrediction != null}',
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Predictions Active',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusText(lastPredictionTime, timeUntilNext),
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Only show risk badge if we have a prediction
          if (latestPrediction != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: latestPrediction.riskLevel.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: latestPrediction.riskLevel.color.withOpacity(0.5),
                ),
              ),
              child: Text(
                latestPrediction.riskLevel.label,
                style: AppTheme.bodySmall.copyWith(
                  color: latestPrediction.riskLevel.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            )
          else
            // Show "waiting" indicator if no prediction yet
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Running...',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(DateTime? lastTime, Duration? timeUntilNext) {
    if (lastTime == null) {
      return 'First prediction in progress...';
    }

    final now = DateTime.now();
    final timeSince = now.difference(lastTime);

    debugPrint('⏰ Prediction timestamp calculation:');
    debugPrint('   Last prediction time: $lastTime');
    debugPrint('   Current time: $now');
    debugPrint('   Time difference: ${timeSince.inHours}h ${timeSince.inMinutes % 60}m');

    String lastTimeText;
    if (timeSince.inMinutes < 1) {
      lastTimeText = 'just now';
    } else if (timeSince.inHours < 1) {
      lastTimeText = '${timeSince.inMinutes}m ago';
    } else {
      final hours = timeSince.inHours;
      final minutes = timeSince.inMinutes % 60;
      lastTimeText =
          minutes > 0 ? '${hours}h ${minutes}m ago' : '${hours}h ago';
    }

    if (timeUntilNext == null) {
      return 'Last: $lastTimeText';
    }

    String nextTimeText;
    if (timeUntilNext.inMinutes < 1) {
      nextTimeText = 'soon';
    } else if (timeUntilNext.inHours < 1) {
      nextTimeText = '${timeUntilNext.inMinutes}m';
    } else {
      final hours = timeUntilNext.inHours;
      final minutes = timeUntilNext.inMinutes % 60;
      nextTimeText = minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }

    return 'Last: $lastTimeText • Next: $nextTimeText';
  }
}
