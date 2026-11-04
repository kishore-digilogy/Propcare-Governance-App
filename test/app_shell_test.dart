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
    testWidgets('LD_HEAD role shows streamlined 4-item bottom nav and directly navigates to All Sites', (tester) async {
      HiveStorage.mockUserRole = 'LD_HEAD';

      final testPages = List.generate(10, (i) => Scaffold(body: Text('Page $i')));

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

      // Should NOT show Activities, Attendance, or Training in bottom nav
      expect(find.text('Activities'), findsNothing);
      expect(find.text('Attendance'), findsNothing);

      // Tapping Sites directly switches to All Sites page (index 1) without opening sub-menu
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      // Sub-menu items should not exist
      expect(find.text('Back'), findsNothing);
      expect(find.text('Renewals'), findsNothing);

      // Tapping Transition directly switches to Transition page (index 4)
      await tester.tap(find.text('Transition'));
      await tester.pumpAndSettle();

      expect(find.text('Page 4'), findsOneWidget);

      // Tapping Dashboard switches to Dashboard (index 0)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Page 0'), findsOneWidget);
    });

    testWidgets('CRRM role shows full 5-item bottom nav and Sites submenu includes Transition', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      final testPages = List.generate(10, (i) => Scaffold(body: Text('Page $i')));

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

      // Tapping Sites opens sites submenu with Transition included
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewals'), findsOneWidget);
      expect(find.text('Transition'), findsOneWidget);
    });

    testWidgets('Other roles (HR) show 5-item bottom nav and Sites submenu hides Transition', (tester) async {
      HiveStorage.mockUserRole = 'HR';

      final testPages = List.generate(10, (i) => Scaffold(body: Text('Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Should show all 5 standard items matching image
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('MOM & Mail'), findsOneWidget);

      // Tapping Sites opens sites submenu where Transition is HIDDEN
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewals'), findsOneWidget);
      expect(find.text('Transition'), findsNothing);
    });
  });
}
