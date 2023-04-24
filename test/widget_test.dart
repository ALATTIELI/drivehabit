import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test2/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app renders without errors.
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
