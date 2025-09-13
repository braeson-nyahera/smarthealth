import '../models/health_models.dart';

class HealthUtils {
  static String formatValue(double value, HealthMetric metric) {
    if (metric.unit == 'steps') {
      return '${value.toInt()}';
    } else if (metric.unit == 'km') {
      return '${value.toStringAsFixed(2)} km';
    } else if (metric.unit == 'kcal') {
      return '${value.toInt()} kcal';
    } else if (metric.unit == 'bpm') {
      return '${value.toInt()} bpm';
    } else if (metric.unit == 'mmHg') {
      return '${value.toInt()} mmHg';
    } else if (metric.unit == 'kg') {
      return '${value.toStringAsFixed(1)} kg';
    } else if (metric.unit == 'hours') {
      return '${(value / 60).toStringAsFixed(1)}h';
    } else if (metric.unit == 'minutes') {
      return '${value.toInt()}m';
    } else if (metric.unit == '%') {
      return '${value.toInt()}%';
    } else if (metric.unit == 'score') {
      return '${value.toInt()}';
    } else {
      return value.toStringAsFixed(1);
    }
  }

  static HealthSummary calculateSummary(List<HealthDataPoint> points) {
    if (points.isEmpty) {
      return HealthSummary(average: 0, min: 0, max: 0, latest: 0, trend: 0);
    }

    final values = points.map((p) => p.value).toList();
    final latest = points.last.value;
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Calculate trend (simple linear regression slope)
    double trend = 0;
    if (points.length > 1) {
      final n = points.length;
      final xSum = List.generate(n, (i) => i).reduce((a, b) => a + b);
      final ySum = values.reduce((a, b) => a + b);
      final xySum = List.generate(
        n,
        (i) => i * values[i],
      ).reduce((a, b) => a + b);
      final x2Sum = List.generate(n, (i) => i * i).reduce((a, b) => a + b);

      trend = (n * xySum - xSum * ySum) / (n * x2Sum - xSum * xSum);
    }

    return HealthSummary(
      average: average,
      min: min,
      max: max,
      latest: latest,
      trend: trend,
    );
  }

  static Map<String, List<String>> groupMetricsByCategory(
    Map<String, List<HealthDataPoint>> timeSeriesData,
    Map<String, HealthMetric> metricsToTrack,
  ) {
    Map<String, List<String>> categories = {};

    for (String key in timeSeriesData.keys) {
      if (metricsToTrack.containsKey(key)) {
        String category = metricsToTrack[key]!.category;
        categories.putIfAbsent(category, () => []).add(key);
      }
    }

    return categories;
  }
}
