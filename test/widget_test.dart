// This is a basic Flutter widget test for SmartHealth app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smarthealth/main.dart';

void main() {
  testWidgets('SmartHealth app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(SmartHealthApp());

    // Verify that the app loads with sign-in screen
    expect(find.text('SmartHealth Dashboard'), findsWidgets);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byIcon(Icons.health_and_safety), findsOneWidget);

    // Verify the main text is present
    expect(
      find.text(
        'Connect your Google Fit account to view\ncomprehensive health metrics',
      ),
      findsOneWidget,
    );
  });
}
