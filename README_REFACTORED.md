# SmartHealth Flutter App - Refactored Structure

## Overview
This Flutter application provides comprehensive health data visualization by connecting to Google Fit APIs. The codebase has been refactored into a clean, modular architecture following Flutter best practices.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── constants/
│   └── health_metrics.dart           # Health metrics configuration and constants
├── models/
│   └── health_models.dart            # Data models (HealthDataPoint, HealthSummary, HealthMetric)
├── services/
│   ├── google_fit_service.dart       # Google Fit API interactions
│   └── health_data_service.dart      # High-level health data coordination
├── utils/
│   └── health_utils.dart             # Utility functions for calculations and formatting
├── widgets/
│   ├── metric_card.dart              # Individual metric display card
│   ├── detailed_chart.dart           # Detailed chart widget for metrics
│   ├── detailed_stats.dart           # Statistics display widget
│   ├── user_header.dart              # User profile header widget
│   └── category_header.dart          # Category section header widget
└── pages/
    └── health_data_page.dart         # Main health dashboard page
```

## Architecture Overview

### 1. **Models** (`lib/models/`)
- **HealthDataPoint**: Represents a single health measurement with timestamp and value
- **HealthSummary**: Aggregated statistics (average, min, max, latest, trend)
- **HealthMetric**: Configuration for each health metric (name, unit, icon, color, etc.)
- **ValueType**: Enum for integer vs decimal value types

### 2. **Constants** (`lib/constants/`)
- **HealthMetrics**: Central configuration for all supported health metrics
- Includes Google Fit scopes, metric definitions, and category icons
- Supports Activity, Heart, Sleep, Body, Vitals, and Wellness categories

### 3. **Services** (`lib/services/`)
- **GoogleFitService**: Low-level Google Fit API interactions
  - Data fetching and parsing
  - Heart rate calculations
  - Sleep data processing
  - Blood pressure handling
- **HealthDataService**: High-level orchestration
  - Coordinates multiple API calls
  - Manages authentication
  - Data aggregation and organization

### 4. **Utils** (`lib/utils/`)
- **HealthUtils**: Utility functions
  - Value formatting for different units
  - Summary calculations
  - Data grouping by categories

### 5. **Widgets** (`lib/widgets/`)
- **MetricCard**: Displays individual metrics with mini-charts
- **DetailedChart**: Full-screen charts for detailed analysis
- **DetailedStats**: Statistical breakdowns
- **UserHeader**: User profile and summary information
- **CategoryHeader**: Section headers for metric categories

### 6. **Pages** (`lib/pages/`)
- **HealthDataPage**: Main dashboard orchestrating all components

## Key Features

### Health Metrics Supported
- **Activity**: Steps, calories, distance, active minutes, floors climbed
- **Heart**: Heart rate, resting HR, max HR, HRV
- **Sleep**: Duration, deep sleep %, REM sleep %, efficiency
- **Vitals**: Blood oxygen, temperature, breathing rate, blood pressure
- **Wellness**: Stress score, recovery score
- **Body**: Weight tracking

### Data Visualization
- Mini-charts on metric cards for quick trends
- Detailed line charts with interactive elements
- Statistical summaries (average, min, max, trend)
- Color-coded categories and trend indicators

### User Experience
- Google Sign-In integration
- Configurable time periods (7, 14, 30, 90 days)
- Responsive grid layout
- Modal detail views
- Loading states and error handling

## Technical Implementation

### State Management
- Uses Flutter's built-in StatefulWidget
- Centralized state in main page component
- Service layer handles data fetching logic

### Data Flow
1. User authentication via Google Sign-In
2. HealthDataService coordinates API calls
3. GoogleFitService handles specific data types
4. Data processed and stored in page state
5. Widgets display formatted data

### Error Handling
- Comprehensive try-catch blocks
- User-friendly error messages
- Graceful degradation for missing data
- Debug logging for development

## Dependencies
- `flutter`: UI framework
- `google_sign_in`: Authentication
- `http`: API communication
- `fl_chart`: Chart visualization

## Getting Started

1. Ensure Google Fit API credentials are configured
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application
4. Sign in with Google account to view health data

## Code Quality
- Follows Flutter/Dart style guidelines
- No lint warnings or errors
- Modular, testable architecture
- Clear separation of concerns
- Comprehensive documentation

## Future Enhancements
- Unit tests for services and utilities
- Integration tests for user flows
- Data caching and offline support
- Additional health metric types
- Export functionality
- Custom date range selection
