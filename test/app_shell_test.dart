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
    testWidgets('LD_HEAD role shows standard 5-item bottom nav and navigates to All Sites', (tester) async {
      HiveStorage.mockUserRole = 'LD_HEAD';

      final testPages = List.generate(10, (i) => Scaffold(body: Text('Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Dashboard, Sites, Governance, Attendance, Reports
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Governance'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      // Tapping Sites opens sub-menu with All Sites
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Draft Sites'), findsOneWidget);

      // Tapping Back returns to main bottom bar
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

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

      // Should show all 5 standard items: Dashboard, Sites, Governance, Attendance, Reports
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Governance'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      // Tapping Sites opens sites submenu with Draft Sites and Transition included
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewals'), findsOneWidget);
      expect(find.text('Draft Sites'), findsOneWidget);
      expect(find.text('Transition'), findsOneWidget);

      // Tapping Draft Sites switches to page 3
      await tester.tap(find.text('Draft Sites'));
      await tester.pumpAndSettle();
      expect(find.text('Page 3'), findsOneWidget);

      // Tapping Back returns to main bottom bar
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Tapping Governance opens governance submenu with My Governance and Team Governance
      await tester.tap(find.text('Governance'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('My Governance'), findsOneWidget);
      expect(find.text('Team Governance'), findsOneWidget);
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

      // Should show all 5 standard items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Governance'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      // Tapping Sites opens sites submenu where Transition is HIDDEN
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewals'), findsOneWidget);
      expect(find.text('Draft Sites'), findsOneWidget);
      expect(find.text('Transition'), findsNothing);
    });

    testWidgets('iPad / Tablet screen renders Left Sidebar navigation layout and switches pages', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      // Set iPad Pro 11" resolution (834 x 1194)
      tester.view.physicalSize = const Size(834 * 2, 1194 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testPages = List.generate(16, (i) => Scaffold(body: Text('Tablet Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Tablet layout shows PropCare Governance header in sidebar
      expect(find.text('PropCare'), findsOneWidget);
      expect(find.text('Governance'), findsWidgets);
      expect(find.text('Dashboard'), findsOneWidget);

      // Sites submenu should be open by default on tablet
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewal Sites'), findsOneWidget);
      expect(find.text('Draft Sites'), findsOneWidget);

      // Tapping All Sites navigates to page 1
      await tester.tap(find.text('All Sites'));
      await tester.pumpAndSettle();
      expect(find.text('Tablet Page 1'), findsOneWidget);

      // Tapping Renewal Sites navigates to page 2
      await tester.tap(find.text('Renewal Sites'));
      await tester.pumpAndSettle();
      expect(find.text('Tablet Page 2'), findsOneWidget);

      // Tapping Checklist Report navigates to page 12
      await tester.tap(find.text('Checklist Report'));
      await tester.pumpAndSettle();
      expect(find.text('Tablet Page 12'), findsOneWidget);

      // Collapse sidebar button toggles sidebar width
      final collapseButton = find.byTooltip('Collapse sidebar');
      expect(collapseButton, findsOneWidget);
      await tester.tap(collapseButton);
      await tester.pumpAndSettle();

      // Expand sidebar button is now available
      expect(find.byTooltip('Expand sidebar'), findsOneWidget);
    });

    testWidgets('Orientation change in landscape renders cleanly without overflow', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      // Landscape orientation on phone (844 x 390)
      tester.view.physicalSize = const Size(844 * 2, 390 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testPages = List.generate(16, (i) => Scaffold(body: Text('Landscape Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Clean render without errors
      expect(find.text('Landscape Page 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
