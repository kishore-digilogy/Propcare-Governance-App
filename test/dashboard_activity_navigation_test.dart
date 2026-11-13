import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/storage/hive_storage.dart';
import 'package:propcare_governance/features/activities/presentation/pages/activity_execution_page.dart';
import 'package:propcare_governance/features/dashboard/data/models/dashboard_model.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:propcare_governance/features/sites/presentation/pages/transition_site_detail_page.dart';
import 'package:propcare_governance/features/sites/presentation/pages/transition_sites_page.dart';

void main() {
  testWidgets('GovActivityRow renders activity and navigates to ActivityExecutionPage on tap', (tester) async {
    const item = GovernanceListItemModel(
      id: 'ACT-09006',
      title: 'CRRM Visit',
      siteName: 'Digilogy',
      roleLabel: 'CRRM / Super Admin',
      dueDate: '2027-01-30',
      assigneeName: 'PropCare Administrator',
      state: 'Upcoming',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GovActivityRow(item: item),
          ),
        ),
      ),
    );

    expect(find.text('CRRM Visit'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ActivityExecutionPage), findsOneWidget);
  });

  testWidgets('Upcoming L&D Work renders calendar badge and navigates to TransitionSiteDetailPage on tap', (tester) async {
    const item = GovernanceListItemModel(
      id: 'ld-rev-bac7c24c-4c5c-4c2e-8b09-d035ef2ad8c4-VERIFIED',
      title: 'Stability verified',
      activityLabel: 'Stability verified',
      siteName: 'DIGILOGY-DEV',
      roleLabel: 'L&D Head',
      dueDate: 'Fri Oct 30',
      assigneeName: 'kumar',
      state: 'Verified',
      href: '/ld-transition/bac7c24c-4c5c-4c2e-8b09-d035ef2ad8c4',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GovActivityRow(item: item, isLd: true),
          ),
        ),
      ),
    );

    // Verify calendar date container
    expect(find.text('OCT'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);

    // Verify content & status
    expect(find.text('Stability verified'), findsOneWidget);
    expect(find.text('DIGILOGY-DEV'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);

    // Tap should navigate to TransitionSiteDetailPage
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TransitionSiteDetailPage), findsOneWidget);
  });

  testWidgets('RecentGovernanceCard renders Upcoming L&D Work and View All when isLdRole is true', (tester) async {
    // Set userRole in HiveStorage
    HiveStorage.mockUserRole = 'LD_HEAD';

    const item = GovernanceListItemModel(
      id: 'ld-rev-bac7c24c-4c5c-4c2e-8b09-d035ef2ad8c4-VERIFIED',
      title: 'Stability verified',
      activityLabel: 'Stability verified',
      siteName: 'DIGILOGY-DEV',
      roleLabel: 'L&D Head',
      dueDate: 'Fri Oct 30',
      assigneeName: 'kumar',
      state: 'Verified',
      href: '/ld-transition/bac7c24c-4c5c-4c2e-8b09-d035ef2ad8c4',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecentGovernanceCard(items: [item]),
          ),
        ),
      ),
    );

    expect(find.text('Upcoming L&D Work'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);

    // Tap View All
    await tester.tap(find.text('View All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TransitionSitesPage), findsOneWidget);

    // Reset role
    HiveStorage.mockUserRole = null;
  });

  testWidgets('QuickActionsGridView renders Training, Role & Access, and Approvals for L&D role', (tester) async {
    HiveStorage.mockUserRole = 'LD_HEAD';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuickActionsGridView(),
          ),
        ),
      ),
    );

    // Should show Reports, Training, Role & Access, Approvals
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Role & Access'), findsOneWidget);
    expect(find.text('Approvals'), findsOneWidget);

    // Should NOT show Issues or Governance Matrix
    expect(find.text('Issues'), findsNothing);
    expect(find.text('Governance Matrix'), findsNothing);

    // Reset role
    HiveStorage.mockUserRole = null;
  });

  testWidgets('QuickActionsGridView renders Issues and Governance Matrix for CRRM role', (tester) async {
    HiveStorage.mockUserRole = 'CRRM';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuickActionsGridView(),
          ),
        ),
      ),
    );

    // Should show Reports, Issues, Governance Matrix
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Issues'), findsOneWidget);
    expect(find.text('Governance Matrix'), findsOneWidget);

    // Should NOT show Role & Access or Training
    expect(find.text('Role & Access'), findsNothing);
    expect(find.text('Training'), findsNothing);

    // Reset role
    HiveStorage.mockUserRole = null;
  });

  testWidgets('QuickActionsGridView renders Issues only for Other roles (HR)', (tester) async {
    HiveStorage.mockUserRole = 'HR';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuickActionsGridView(),
          ),
        ),
      ),
    );

    // Should show Reports, Issues
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Issues'), findsOneWidget);

    // Should NOT show Governance Matrix, Training, Role & Access, or Approvals
    expect(find.text('Governance Matrix'), findsNothing);
    expect(find.text('Training'), findsNothing);
    expect(find.text('Role & Access'), findsNothing);
    expect(find.text('Approvals'), findsNothing);

    // Reset role
    HiveStorage.mockUserRole = null;
  });

  testWidgets('SitesByZoneCard displays fallback UI when no sites are allocated', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SitesByZoneCard(
              geography: [],
              zones: [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sites By Zone'), findsOneWidget);
    expect(find.text('No sites allocated yet'), findsOneWidget);
    expect(find.text('Sites allocated to your zones will appear here'), findsOneWidget);
    expect(find.byIcon(Icons.domain_disabled_rounded), findsOneWidget);
  });

  testWidgets('SitesByZoneCard displays bars when sites exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SitesByZoneCard(
              geography: [
                GeographyItemModel(
                  id: 'z1',
                  name: 'Tamil Nadu',
                  sites: 3,
                  overdue: 0,
                  openIssues: 0,
                ),
              ],
              zones: [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sites By Zone'), findsOneWidget);
    expect(find.text('Tamil Nadu'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('No sites allocated yet'), findsNothing);
  });

  testWidgets('GovernanceCard displays fallback UI "No governance" when total items is 0', (tester) async {
    const overview = OverviewModel(
      sites: 0,
      live: 0,
      transition: 0,
      users: 0,
      governancePending: 0,
      governanceCompleted: 0,
      governanceDue: 0,
      governanceList: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GovernanceCard(overview: overview),
          ),
        ),
      ),
    );

    expect(find.text('Governance Overview'), findsOneWidget);
    expect(find.text('Current status of governance'), findsOneWidget);
    expect(find.text('No governance'), findsOneWidget);
    expect(find.text('No governance activities or visits scheduled yet'), findsOneWidget);
    expect(find.text('Total Items'), findsNothing);
  });

  testWidgets('GovernanceCard displays donut chart and stat cards when total items > 0', (tester) async {
    const overview = OverviewModel(
      sites: 10,
      live: 8,
      transition: 2,
      users: 5,
      governancePending: 5,
      governanceCompleted: 3,
      governanceDue: 2,
      governanceList: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GovernanceCard(overview: overview),
          ),
        ),
      ),
    );

    expect(find.text('Governance Overview'), findsOneWidget);
    expect(find.text('No governance'), findsNothing);
    expect(find.text('Total Items'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
  });
}
