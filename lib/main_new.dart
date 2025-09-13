import 'package:flutter/material.dart';
import 'pages/health_data_page.dart';

void main() => runApp(SmartHealthApp());

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHealth - Complete Biometric Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HealthDataPage(),
    );
  }
}
