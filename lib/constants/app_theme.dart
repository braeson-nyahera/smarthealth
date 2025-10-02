import 'package:flutter/material.dart';

class AppTheme {
  // Modern Health App Color Palette - Based on medical/wellness principles
  static const Color primaryMedical = Color(
    0xFF0066CC,
  ); // Medical blue - trust & professionalism
  static const Color primaryMedicalLight = Color(0xFF4A90E2);
  static const Color primaryMedicalDark = Color(0xFF004499);

  // Secondary colors for health categories
  static const Color heartRate = Color(0xFFE74C3C); // Vibrant red for heart
  static const Color activity = Color(0xFF00D4AA); // Fresh teal for activity
  static const Color sleep = Color(0xFF6C5CE7); // Calming purple for sleep
  static const Color wellness = Color(0xFF00B894); // Natural green for wellness
  static const Color vitals = Color(0xFFFF6B6B); // Warm coral for vitals
  static const Color nutrition = Color(0xFFFF9500); // Orange for nutrition

  // Success states for health improvements
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD4F7DC);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF5E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDEDEA);

  // Modern neutral palette
  static const Color surfacePure = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFBFCFD);
  static const Color surfaceContainer = Color(0xFFF5F7FA);
  static const Color surfaceContainerHigh = Color(0xFFEFF2F6);
  static const Color surfaceBackground = Color(0xFFF8FAFC);

  // Accessible text colors with proper contrast ratios
  static const Color textPrimaryDark = Color(0xFF0F172A); // AAA contrast
  static const Color textSecondaryDark = Color(0xFF475569); // AA contrast
  static const Color textTertiaryDark = Color(0xFF64748B); // AA contrast
  static const Color textDisabled = Color(0xFF94A3B8);

  // Modern border and divider colors
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderDefault = Color(0xFFCBD5E1);
  static const Color borderStrong = Color(0xFF94A3B8);

  // Health-focused gradients
  static const LinearGradient primaryHealthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMedical, primaryMedicalDark],
    stops: [0.0, 1.0],
  );

  static const LinearGradient wellnessGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [wellness, Color(0xFF00A085)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfacePure, surfaceElevated],
    stops: [0.0, 1.0],
  );

  // Modern glass morphism effect
  static const LinearGradient glassMorphism = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(25, 255, 255, 255),
      Color.fromARGB(15, 255, 255, 255),
    ],
  );

  // Responsive spacing system
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingXXXL = 64.0;

  // Modern border radius system
  static const double radiusXXS = 4.0;
  static const double radiusXS = 6.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 9999.0;

  // Modern elevation system with softer shadows
  static List<BoxShadow> get elevationSoft => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevationMedium => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get elevationHigh => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      offset: const Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
  ];

  static List<BoxShadow> get elevationXHigh => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      offset: const Offset(0, 10),
      blurRadius: 25,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      offset: const Offset(0, 25),
      blurRadius: 50,
      spreadRadius: -12,
    ),
  ];

  // Glass morphism shadow for modern cards
  static List<BoxShadow> get glassEffect => [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.25),
      offset: const Offset(0, 1),
      blurRadius: 1,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      offset: const Offset(0, 8),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];

  // Modern typography system - Inter font family for health apps
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.1,
    color: textPrimaryDark,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: textPrimaryDark,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: textPrimaryDark,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
    color: textPrimaryDark,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: textPrimaryDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: textPrimaryDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textSecondaryDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: textTertiaryDark,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
    color: textPrimaryDark,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
    color: textSecondaryDark,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: textTertiaryDark,
  );

  // Modern Material 3 Theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryMedical,
      brightness: Brightness.light,
      surface: surfacePure,
      onSurface: textPrimaryDark,
      surfaceContainer: surfaceContainer,
      primary: primaryMedical,
      secondary: wellness,
      tertiary: activity,
    ),
    fontFamily: 'Inter', // Modern, accessible font
    scaffoldBackgroundColor: surfaceBackground,

    // Modern AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: surfacePure,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: false, // Modern left-aligned titles
      titleTextStyle: headingLarge.copyWith(fontWeight: FontWeight.w700),
      scrolledUnderElevation: 1,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.05),
    ),

    // Modern Card theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
        side: BorderSide(color: borderSubtle, width: 1),
      ),
      color: surfacePure,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
    ),

    // Modern Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryMedical,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: labelLarge.copyWith(color: Colors.white),
        minimumSize: const Size(0, 48), // Accessibility minimum touch target
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryMedical,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: labelLarge.copyWith(color: Colors.white),
        minimumSize: const Size(0, 48),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryMedical,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        side: const BorderSide(color: primaryMedical, width: 1.5),
        textStyle: labelLarge.copyWith(color: primaryMedical),
        minimumSize: const Size(0, 48),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryMedical,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: labelLarge.copyWith(color: primaryMedical),
        minimumSize: const Size(0, 48),
      ),
    ),

    // Modern Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryMedical, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
      labelStyle: bodyMedium,
      hintStyle: bodyMedium.copyWith(color: textDisabled),
    ),
  );

  // Modern animation durations and curves
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 600);

  static const Curve animationCurve = Curves.easeInOut;
  static const Curve animationBounceCurve = Curves.elasticOut;

  // Helper methods for health metric colors
  static Color getMetricColor(String category) {
    switch (category.toLowerCase()) {
      case 'activity':
        return activity;
      case 'heart':
        return heartRate;
      case 'sleep':
        return sleep;
      case 'vitals':
        return vitals;
      case 'wellness':
        return wellness;
      case 'body':
      case 'nutrition':
        return nutrition;
      case 'fitness':
        return activity;
      case 'recovery':
        return wellness;
      case 'health':
        return primaryMedical;
      default:
        return textSecondaryDark;
    }
  }

  static LinearGradient getMetricGradient(String category) {
    final color = getMetricColor(category);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, color.withValues(alpha: 0.8)],
    );
  }

  // Health status colors
  static Color getHealthStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
      case 'very active':
        return success;
      case 'good':
      case 'active':
        return wellness;
      case 'fair':
      case 'moderate':
        return warning;
      case 'poor':
      case 'low':
        return error;
      default:
        return textSecondaryDark;
    }
  }

  static Color getHealthStatusLightColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
      case 'very active':
        return successLight;
      case 'good':
      case 'active':
        return const Color(0xFFE8F5E8);
      case 'fair':
      case 'moderate':
        return warningLight;
      case 'poor':
      case 'low':
        return errorLight;
      default:
        return surfaceContainer;
    }
  }
}
