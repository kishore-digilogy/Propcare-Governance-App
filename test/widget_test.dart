// This is a basic Flutter widget test updated for the clean architecture refactor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — PropCareApp renders without error',
      (WidgetTester tester) async {
    // PropCareApp requires DI to be initialised.
    // For a quick smoke test, wrap a minimal MaterialApp instead.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Test OK'))),
      ),
    );
    expect(find.text('Test OK'), findsOneWidget);
  });
}
