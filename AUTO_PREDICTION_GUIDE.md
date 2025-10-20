# Automatic Hypertension Prediction - Every 3 Hours

## Overview

SmartHealth now includes **automatic hypertension risk predictions** that run every 3 hours when you're signed in. This provides continuous health monitoring without manual intervention.

## How It Works

### Automatic Schedule
- **Frequency**: Predictions run automatically every 3 hours
- **First Run**: Immediately after profile setup or sign-in
- **Continuous**: Runs in the background as long as you're signed in
- **Minimum Interval**: 2h 45m safety buffer to prevent too-frequent predictions

### What Gets Analyzed

Each prediction analyzes your health data from the last **30 days**:

1. **Blood Pressure Readings**
   - Systolic and diastolic measurements
   - Trends and patterns over time

2. **Heart Rate Data**
   - Resting heart rate
   - Heart rate variability
   - Activity-adjusted rates

3. **Physical Activity**
   - Daily step counts
   - Activity duration and intensity
   - Exercise patterns

4. **Sleep Quality**
   - Sleep duration
   - Sleep consistency
   - Rest and recovery patterns

5. **Risk Factors** (from your profile)
   - Age
   - BMI (Body Mass Index)
   - Diabetes
   - High cholesterol
   - Physical activity level

## Viewing Predictions

### Dashboard Status Banner

When the scheduler is active, you'll see a status banner on your dashboard showing:
- **Last prediction time**: "2h 15m ago"
- **Next prediction time**: "in 45m"
- **Current risk level**: Color-coded risk badge (Low/Moderate/High/Very High)

### Latest Prediction Details

To view detailed prediction results:
1. The latest prediction is automatically saved
2. View it from the Hypertension section (coming soon)
3. See contributing factors and recommendations
4. Track risk score trends over time

## Prediction Output

Each prediction includes:

### Risk Assessment
- **Risk Level**: Low, Moderate, High, or Very High
- **Risk Score**: 0-100 numerical score
- **Confidence**: How confident the model is (0-100%)

### Contributing Factors
List of factors increasing your risk:
- Elevated blood pressure readings
- High heart rate patterns
- Insufficient physical activity
- Poor sleep quality
- Risk factors from profile

### Personalized Recommendations
Actionable advice based on your data:
- Lifestyle modifications
- Activity suggestions
- When to consult a doctor
- Monitoring priorities

### Future Projections
Risk predictions for:
- **7 days**: Short-term trend
- **30 days**: Monthly outlook
- **90 days**: Quarterly projection

## Data Storage

- **Latest prediction** is saved to persistent storage
- **Survives app restarts** - you'll see your last prediction when you return
- **Privacy**: All data stored locally on your device
- **No cloud upload** required

## Technical Details

### Scheduler Service

The `PredictionSchedulerService` manages automatic predictions:

```dart
// Service is started automatically after sign-in
await _predictionScheduler.startScheduler(
  healthDataService: _healthDataService,
  user: _user,
  runImmediately: true, // First prediction runs immediately
);
```

### Prediction Flow

1. **Data Collection** (30-day window)
   - Fetch all health metrics from HealthDataService
   - Load user profile and risk factors
   - Validate sufficient data available

2. **Model Execution**
   - Multi-layer prediction algorithm
   - Weighted scoring of all factors
   - Confidence calculation

3. **Result Storage**
   - Save to SharedPreferences
   - Update UI via listeners
   - Log to console for debugging

4. **Notification** (Future Enhancement)
   - Alert user if risk level changes
   - Remind about important trends

### Minimum Data Requirements

For accurate predictions, the system needs:
- ✅ At least **7 days** of blood pressure data
- ✅ At least **14 days** of heart rate data
- ✅ Some activity data (steps/exercise)
- ✅ Basic sleep data
- ✅ Complete user profile

If insufficient data is available, the prediction is skipped and will retry at the next scheduled time.

## Scheduler Management

### Auto-Start
The scheduler starts automatically when:
- ✅ User completes profile setup
- ✅ User signs in and has existing profile
- ✅ App is restarted with saved session

### Auto-Stop
The scheduler stops when:
- ❌ User signs out
- ❌ App is closed/terminated
- ❌ User clears app data

### Manual Control (Future)
Planned features:
- Pause scheduler temporarily
- Adjust prediction frequency (1h/3h/6h/12h)
- Request prediction on-demand
- View prediction history

## Performance Impact

- **Minimal battery use**: Runs in-app, not background service
- **Efficient data access**: Only fetches what's needed
- **Smart scheduling**: Respects minimum intervals
- **Graceful failures**: Skips predictions if data unavailable

## Privacy & Security

- ✅ **Local processing**: All predictions run on your device
- ✅ **No data upload**: Health data stays on your device
- ✅ **HIPAA-aware**: Follows health data best practices
- ✅ **User control**: Sign out to stop predictions

## Troubleshooting

### Predictions Not Running

1. **Check sign-in status**: Must be signed in
2. **Verify profile completion**: Profile must be complete
3. **Review data availability**: Need sufficient health data
4. **Check logs**: Look for error messages in console

### Seeing "Insufficient Data"

This means:
- Not enough days of blood pressure data
- Missing heart rate measurements
- Incomplete user profile
- Try collecting more health data over several days

### Scheduler Shows "Stopped"

Reasons:
- User manually signed out
- App was force-closed
- Error during initialization
- Sign in again to restart

## Debug Information

To view scheduler status in console:

```dart
print(_predictionScheduler.getPredictionSummary());
```

Output example:
```
Last Prediction: 2 hours, 15 minutes ago
Risk Level: Moderate Risk
Risk Score: 58.5/100
Next Prediction: in 0 hours, 45 minutes
Scheduler Status: Running
```

## Future Enhancements

Planned improvements:
- 📱 Push notifications for risk changes
- 📊 Prediction history dashboard
- 📈 Trend visualization over weeks/months
- 🔔 Custom alert thresholds
- ⚙️ Configurable prediction frequency
- 🤖 ML model improvements with more data
- 📤 Optional sharing with healthcare providers

## Code Reference

Key files:
- `/lib/services/prediction_scheduler_service.dart` - Main scheduler
- `/lib/services/hypertension_prediction_service.dart` - ML model
- `/lib/widgets/prediction_scheduler_status.dart` - UI status widget
- `/lib/models/hypertension_risk_models.dart` - Data models

## Support

If you experience issues with automatic predictions:
1. Check this guide's troubleshooting section
2. Review console logs for errors
3. Ensure Health Connect permissions granted
4. Verify sufficient health data collected
5. Try signing out and back in

---

**Note**: This is a health monitoring tool and should not replace professional medical advice. Always consult with healthcare providers for medical decisions.
