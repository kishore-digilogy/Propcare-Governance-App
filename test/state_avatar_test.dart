import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/widgets/state_avatar.dart';

void main() {
  group('StateAvatar Widget Tests', () {
    testWidgets('renders embedded image for Karnataka', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StateAvatar(name: 'Karnataka', size: 32),
          ),
        ),
      );
      await tester.pump();

      // Should render Image widget with in-memory emblem
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    });

    testWidgets('renders embedded image for Andra Pradesh', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StateAvatar(name: 'Andra Pradesh', size: 32),
          ),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    });

    testWidgets('renders embedded image for Mumbai', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StateAvatar(name: 'Mumbai', size: 32),
          ),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    });

    testWidgets('renders embedded image for NCR', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StateAvatar(name: 'NCR', size: 32),
          ),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    });

    testWidgets('renders specialized hotel icon for Hospitality zone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StateAvatar(name: 'Hospitality', size: 32),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.hotel_rounded), findsOneWidget);
    });

    testWidgets('renders fallback initials for unknown state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StateAvatar(name: 'Zootopia', size: 32, enableNetwork: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ZO'), findsOneWidget);
    });
  });
}
