import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/health_data_page.dart';
import 'constants/app_theme.dart';
import 'utils/error_handler.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handling
  setupErrorHandling();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SmartHealthApp());
}

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHealth',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HealthDataPage(),
      // Add error handling for the entire app
      builder: (context, widget) {
        // Handle text scaling
        final mediaQueryData = MediaQuery.of(context);
        final constrainedTextScaleFactor = mediaQueryData.textScaleFactor.clamp(
          0.8,
          1.2,
        );

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(constrainedTextScaleFactor),
          ),
          child: widget!,
        );
      },
    );
  }
}
