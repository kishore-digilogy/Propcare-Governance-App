import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/models/meta_model.dart';
import 'package:propcare_governance/core/services/meta_service.dart';
import 'package:propcare_governance/core/storage/hive_storage.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/app_shell.dart';

void main() {
  setUp(() {
    MetaService.instance.setMockMeta(const MetaDataModel(
      users: [],
      sites: [MetaSiteModel(id: 's1', name: 'Mock Site')],
      units: [],
    ));
  });

  tearDown(() {
    HiveStorage.mockUserRole = null;
  });

  group('AppShell Role-Based Navigation Tests', () {
    testWidgets('LD_HEAD role shows streamlined bottom nav without Activities and Attendance', (tester) async {
      HiveStorage.mockUserRole = 'LD_HEAD';

      final testPages = List.generate(9, (i) => Scaffold(body: Text('Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Dashboard, Sites, Transition, and MOM & Mail
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Transition'), findsOneWidget);
      expect(find.text('MOM & Mail'), findsOneWidget);

      // Should NOT show Activities or Attendance in bottom nav
      expect(find.text('Activities'), findsNothing);
      expect(find.text('Attendance'), findsNothing);

      // Tapping Transition directly switches to Transition page (index 4)
      await tester.tap(find.text('Transition'));
      await tester.pumpAndSettle();

      expect(find.text('Page 4'), findsOneWidget);

      // Tapping Sites opens sites submenu
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewals'), findsOneWidget);
      expect(find.text('Transition'), findsOneWidget);
    });

    testWidgets('Non-LD role (CRRM) shows full 5-item bottom nav including Activities and Attendance', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      final testPages = List.generate(9, (i) => Scaffold(body: Text('Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Should show all 5 standard items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('MOM & Mail'), findsOneWidget);
    });
  });
}
