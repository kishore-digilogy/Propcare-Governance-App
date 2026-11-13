import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/dashboard/data/models/dashboard_model.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';

void main() {
  group('Dashboard Staggered Stat Grid Tests', () {
    const dummyDashboard = DashboardModel(
      date: '2026-11-11',
      counts: DashboardCountsModel(
        sites: 19,
        active: 8,
        inactive: 0,
        live: 8,
        transition: 6,
        pending: 0,
        completed: 0,
        overdue: 0,
        openIssues: 0,
        openActions: 0,
        tatAlerts: 0,
        approvals: 0,
        dueToday: 0,
      ),
      renewals: RenewalCountsModel(
        d30: 3,
        d60: 2,
        d90: 0,
        items30: [],
        items60: [],
        items90: [],
      ),
      geography: [],
      spocPerformance: [],
      chart: [],
      groups: [],
      overview: OverviewModel(
        sites: 19,
        live: 8,
        transition: 6,
        users: 87,
        governancePending: 0,
        governanceCompleted: 0,
        governanceDue: 0,
        governanceList: [],
      ),
      workspace: WorkspaceModel(
        viewer: WorkspaceViewerModel(
          id: '1',
          name: 'Admin',
          role: 'admin',
          roleLabel: 'Admin',
        ),
        pan: false,
        zones: [],
        clusters: [],
        sites: [],
        siteCount: 0,
      ),
    );

    testWidgets('renders all 6 staggered stat cards with values and labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardPage.testableStatGrid(data: dummyDashboard),
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. Overall Sites
      expect(find.text('Overall Sites'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);

      // 2. Live Sites
      expect(find.text('Live Sites'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // 3. Transition Sites
      expect(find.text('Transition\nSites'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      // 4. Users
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('Active Now'), findsOneWidget);

      // 5. R&R Pending
      expect(find.text('R&R Pending'), findsOneWidget);

      // 6. Survey Count
      expect(find.text('Survey Count'), findsOneWidget);
    });
  });
}
