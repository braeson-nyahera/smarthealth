import 'package:flutter/material.dart';
import 'pages/health_data_page.dart';
import 'constants/app_theme.dart';

void main() {
  runApp(SmartHealthApp());
}

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHealth - Complete Biometric Data',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: HealthDataPage(),
    );
  }
}
