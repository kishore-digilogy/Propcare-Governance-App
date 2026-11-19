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
    testWidgets('LD_HEAD role shows L&D bottom nav (Dashboard, Sites, Transition, Training, MOM & Email)', (tester) async {
      HiveStorage.mockUserRole = 'LD_HEAD';

      final testPages = List.generate(24, (i) => Scaffold(body: Text('Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Dashboard, Sites, Transition, Training, MOM & Email
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Transition'), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('MOM & Email'), findsOneWidget);

      // Tapping Sites opens sub-menu with All Sites only
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Draft Sites'), findsNothing);
      expect(find.text('Renewals'), findsNothing);

      // Tapping Back returns to main bottom bar
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Tapping Dashboard switches to Dashboard (index 0)
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Page 0'), findsOneWidget);
    });

    testWidgets('CRRM / Super Admin role shows full 5-item bottom nav and Sites submenu includes Transition', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      final testPages = List.generate(24, (i) => Scaffold(body: Text('Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Should show all 5 standard items: Dashboard, Sites, Governance, Attendance, MOM & Email
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Governance'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('MOM & Email'), findsOneWidget);

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

    testWidgets('Other roles (Machine Technician / HR) show Image 1 menus and hides Draft Sites & Transition', (tester) async {
      HiveStorage.mockUserRole = 'MACHINE_TECHNICIAN';

      final testPages = List.generate(24, (i) => Scaffold(body: Text('Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Should show all 5 standard items: Dashboard, Sites, Governance, Attendance, MOM & Email
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('Governance'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('MOM & Email'), findsOneWidget);

      // Tapping Sites opens sites submenu where Transition and Draft Sites are HIDDEN
      await tester.tap(find.text('Sites'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewals'), findsOneWidget);
      expect(find.text('Draft Sites'), findsNothing);
      expect(find.text('Transition'), findsNothing);
    });

    testWidgets('iPad / Tablet screen renders Image 2 sidebar for L&D role', (tester) async {
      HiveStorage.mockUserRole = 'LD_HEAD';

      // Set iPad Pro 11" resolution (834 x 1194)
      tester.view.physicalSize = const Size(834 * 2, 1194 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testPages = List.generate(27, (i) => Scaffold(body: Text('Tablet Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // L&D sidebar items matching Image 2
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewal Sites'), findsNothing);
      expect(find.text('Transition'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // Transition badge
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Training Activities'), findsOneWidget);
      expect(find.text('Site Observation Report'), findsOneWidget);
      expect(find.text('Training Report Generator'), findsOneWidget);
      expect(find.text('MOM'), findsOneWidget);
      // Role & Access and Approvals removed on tablet per user request
      expect(find.text('Role & Access'), findsNothing);
      expect(find.text('Approvals'), findsNothing);
      expect(find.text('Reports & Export'), findsOneWidget);
      expect(find.text('Transition / L&D'), findsOneWidget);

      // Non-L&D items must NOT be present
      expect(find.text('Attendance'), findsNothing);
      expect(find.text('Checklist Report'), findsNothing);
      expect(find.text('MMR / MIS'), findsNothing);
      expect(find.text('Issues'), findsNothing);
    });

    testWidgets('iPad / Tablet screen renders Image 1 sidebar for Machine Technician (Others)', (tester) async {
      HiveStorage.mockUserRole = 'MACHINE_TECHNICIAN';

      tester.view.physicalSize = const Size(834 * 2, 1194 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testPages = List.generate(27, (i) => Scaffold(body: Text('Tablet Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Image 1 sidebar items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sites'), findsOneWidget);
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewal Sites'), findsOneWidget);
      expect(find.text('Draft Sites'), findsNothing);
      expect(find.text('Governance'), findsWidgets);
      expect(find.text('My Governance'), findsOneWidget);
      expect(find.text('Team Governance'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('MOM & Email'), findsOneWidget);
      expect(find.text('Checklist Report'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Reports & Export'), findsOneWidget);
      expect(find.text('Issue Report'), findsOneWidget);
      expect(find.text('Machine Report'), findsOneWidget);

      // L&D specific and admin-only items must NOT be present
      expect(find.text('Training'), findsNothing);
      expect(find.text('Role & Access'), findsNothing);
      expect(find.text('Approvals'), findsNothing);
      expect(find.text('Transition / L&D'), findsNothing);
      expect(find.text('MMR / MIS'), findsNothing);
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
      // Training must be visible ONLY for L&D roles, not CRRM / COO / Super Admin
      expect(find.text('Training'), findsNothing);

      // Sites submenu should be open by default on tablet
      expect(find.text('All Sites'), findsOneWidget);
      expect(find.text('Renewal Sites'), findsOneWidget);
      expect(find.text('Draft Sites'), findsOneWidget);
      expect(find.text('Create Site'), findsNothing);
      expect(find.text('Role & Access'), findsNothing);
      expect(find.text('Approvals'), findsNothing);

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

    testWidgets('Super Admin sidebar renders Reports & Export with all reports from Site Report to Machine Report', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      tester.view.physicalSize = const Size(834 * 2, 1194 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testPages = List.generate(27, (i) => Scaffold(body: Text('Tablet Page $i')));

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(pages: testPages),
        ),
      );
      await tester.pumpAndSettle();

      // Reports & Export expandable group items (All Reports category removed per user request)
      expect(find.text('Reports & Export'), findsOneWidget);
      expect(find.text('All Reports'), findsNothing);
      expect(find.text('Site Report'), findsOneWidget);
      expect(find.text('Governance & Visits'), findsOneWidget);
      expect(find.text('Issue Report'), findsOneWidget);
      expect(find.text('Transition / L&D'), findsOneWidget);
      expect(find.text('EHS Report'), findsOneWidget);
      expect(find.text('HR Report'), findsOneWidget);
      expect(find.text('Machine Report'), findsOneWidget);

      // Tapping Site Report navigates to page 20
      await tester.tap(find.text('Site Report'));
      await tester.pumpAndSettle();
      expect(find.text('Tablet Page 20'), findsOneWidget);

      // Tapping Issue Report navigates to page 22
      await tester.tap(find.text('Issue Report'));
      await tester.pumpAndSettle();
      expect(find.text('Tablet Page 22'), findsOneWidget);
    });

    testWidgets('Tablet hides Quick Actions toggle on Dashboard (shows full Governance Overview directly)', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      tester.view.physicalSize = const Size(834 * 2, 1194 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(),
        ),
      );
      await tester.pumpAndSettle();

      // On tablet, Quick Actions toggle is not rendered
      expect(find.text('Quick Actions'), findsNothing);
      expect(find.text('Governance Overview'), findsNothing); // Toggle bar pill not shown
      expect(tester.takeException(), isNull);
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
