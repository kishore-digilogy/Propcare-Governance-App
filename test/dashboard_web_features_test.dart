import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/dashboard/data/models/dashboard_model.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';

void main() {
  final sampleDashboard = DashboardModel(
    date: '2026-11-17',
    drillZoneId: '533c4cbd-cce8-480f-a447-96a60f3a39f2',
    counts: const DashboardCountsModel(
      sites: 15,
      active: 9,
      inactive: 6,
      live: 9,
      transition: 0,
      pending: 9,
      completed: 2,
      overdue: 0,
      openIssues: 0,
      openActions: 0,
      tatAlerts: 0,
      approvals: 0,
      dueToday: 0,
      special: 0,
    ),
    renewals: const RenewalCountsModel(
      d30: 2,
      d60: 2,
      d90: 0,
      pending: 1,
      items30: [],
      items60: [],
      items90: [],
    ),
    geography: [],
    spocPerformance: [],
    chart: [],
    groups: [],
    overview: const OverviewModel(
      sites: 15,
      live: 9,
      inactive: 6,
      special: 0,
      transition: 0,
      users: 87,
      governancePending: 9,
      governanceCompleted: 2,
      governanceDue: 0,
      compliancePct: 18.0,
      surveys: SurveysSummaryModel(assigned: 0, completed: 0, pending: 0),
      governanceParams: [
        GovernanceParamModel(
          key: 'siteVisits',
          label: 'Site Visits',
          icon: 'visit',
          target: 11,
          completed: 2,
          pending: 9,
          due: 0,
          momCompleted: 2,
          momPending: 0,
        ),
        GovernanceParamModel(
          key: 'misMmr',
          label: 'MIS / MMR Submission',
          icon: 'mis',
          target: 14,
          completed: 0,
          pending: 14,
          due: 0,
          momCompleted: 0,
          momPending: 0,
        ),
        GovernanceParamModel(
          key: 'ehs',
          label: 'EHS Activities',
          icon: 'ehs',
          target: 9,
          completed: 0,
          pending: 9,
          due: 0,
          momCompleted: 0,
          momPending: 0,
        ),
        GovernanceParamModel(
          key: 'hr',
          label: 'HR Activities',
          icon: 'hr',
          target: 9,
          completed: 0,
          pending: 9,
          due: 0,
          momCompleted: 0,
          momPending: 0,
        ),
        GovernanceParamModel(
          key: 'rr',
          label: 'R&R Activities',
          icon: 'rr',
          target: 0,
          completed: 0,
          pending: 0,
          due: 0,
          momCompleted: 0,
          momPending: 0,
        ),
      ],
      selectedRole: 'CRRM',
      roleFilterRoles: [
        RoleOptionModel(role: 'CRRM', label: 'CRRM / Super Admin'),
        RoleOptionModel(role: 'ZONAL_HEAD', label: 'Zonal Head'),
        RoleOptionModel(role: 'CLUSTER_EXECUTIVE', label: 'Cluster Executive'),
      ],
      alerts: [
        KeyAlertModel(
          tone: 'red',
          title: 'Governance overdue',
          detail: '2 team activities past due in your allocation.',
          href: '/activities/team?statusBucket=due',
          count: 2,
        ),
      ],
      upcoming: [
        UpcomingActivityModel(
          id: 'act-sample-1',
          title: 'Cluster Executive Visit',
          siteName: 'Orange',
          dueDate: '2026-11-18',
          daysUntil: 1,
          state: 'Upcoming',
        ),
      ],
      governanceList: [],
    ),
    workspace: const WorkspaceModel(
      viewer: WorkspaceViewerModel(
        id: 'viewer-1',
        name: 'PropCare Admin',
        role: 'CRRM',
        roleLabel: 'CRRM / Super Admin',
      ),
      pan: true,
      zones: [
        ZoneModel(
          id: '533c4cbd-cce8-480f-a447-96a60f3a39f2',
          name: 'Andra Pradesh',
          sites: 5,
          live: 3,
          transition: 0,
          clusters: 1,
        ),
        ZoneModel(
          id: 'zone-tn',
          name: 'Tamil Nadu',
          sites: 10,
          live: 6,
          transition: 0,
          clusters: 6,
        ),
      ],
      clusters: [
        ClusterModel(
          id: 'cluster-1',
          name: 'Bhopur',
          zoneName: 'Andra Pradesh',
          sites: 5,
          live: 3,
          transition: 0,
        ),
      ],
      sites: [],
      roles: [
        RoleOptionModel(role: 'CRRM', label: 'CRRM / Super Admin'),
        RoleOptionModel(role: 'ZONAL_HEAD', label: 'Zonal Head'),
      ],
      siteCount: 15,
    ),
  );

  testWidgets('Dashboard renders top 4 stat cards with values matching web', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WebTopStatCards(data: sampleDashboard),
          ),
        ),
      ),
    );

    expect(find.text('Total Sites'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Live Sites'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('Lost Sites'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Special Attention'), findsOneWidget);
  });

  testWidgets(
    'Dashboard filter bar, governance parameters, surveys, and alerts render properly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DashboardFilterBar(
                    data: sampleDashboard,
                    selectedZoneId: null,
                    selectedClusterId: null,
                    selectedRole: null,
                    onFilterChanged: (_, __, ___) {},
                  ),
                  WebTopStatCards(data: sampleDashboard),
                  WebSurveysCard(surveys: sampleDashboard.overview.surveys),
                  WebGovernanceParamsGrid(
                    params: sampleDashboard.overview.governanceParams,
                  ),
                  WebAlertsAndUpcomingCard(
                    alerts: sampleDashboard.overview.alerts,
                    upcoming: sampleDashboard.overview.upcoming,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify 4 Stat Cards
      expect(find.text('Total Sites'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Live Sites'), findsOneWidget);
      expect(find.text('9'), findsWidgets);
      expect(find.text('Lost Sites'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Special Attention'), findsOneWidget);
      expect(find.text('0'), findsWidgets);

      // Verify Surveys card (without View All button)
      expect(find.text('Surveys'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);

      // Verify 5 Governance Parameter cards
      expect(find.text('Site Visits'), findsOneWidget);
      expect(find.text('MIS / MMR Submission'), findsOneWidget);
      expect(find.text('EHS Activities'), findsOneWidget);
      expect(find.text('HR Activities'), findsOneWidget);
      expect(find.text('R&R Activities'), findsOneWidget);

      // Verify Completed and Pending in governance cards (Target & MOM removed)
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Target'), findsNothing);
      expect(find.text('MOM'), findsNothing);

      // Verify Alerts & Upcoming
      expect(find.text('Key Alerts'), findsOneWidget);
      expect(find.text('Governance overdue'), findsOneWidget);
      expect(
        find.text('2 team activities past due in your allocation.'),
        findsOneWidget,
      );
      expect(find.text('DUE'), findsOneWidget);

      expect(find.text('Upcoming Activities'), findsOneWidget);
      expect(find.text('Cluster Executive Visit'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    },
  );

  testWidgets(
    'Upcoming activities card limits to 5 items and expands with bottom View All button',
    (tester) async {
      final sevenActivities = List.generate(
        7,
        (index) => UpcomingActivityModel(
          id: 'act-$index',
          title: 'Activity #$index',
          siteName: 'Site $index',
          dueDate: '2026-11-20',
          daysUntil: index + 1,
          state: 'Upcoming',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WebAlertsAndUpcomingCard(
                alerts: const [],
                upcoming: sevenActivities,
              ),
            ),
          ),
        ),
      );

      // Initial state: only first 5 items rendered
      expect(find.text('Activity #0'), findsOneWidget);
      expect(find.text('Activity #4'), findsOneWidget);
      expect(find.text('Activity #5'), findsNothing);
      expect(find.text('Activity #6'), findsNothing);

      // Bottom View All button should be present
      expect(find.text('View All'), findsOneWidget);

      // Scroll to and tap View All
      await tester.ensureVisible(find.text('View All'));
      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      // Now all 7 items are displayed
      expect(find.text('Activity #5'), findsOneWidget);
      expect(find.text('Activity #6'), findsOneWidget);
      expect(find.text('Show Less'), findsOneWidget);

      // Tap Show Less to collapse back
      await tester.ensureVisible(find.text('Show Less'));
      await tester.tap(find.text('Show Less'));
      await tester.pumpAndSettle();

      expect(find.text('Activity #5'), findsNothing);
      expect(find.text('View All'), findsOneWidget);
    },
  );

  testWidgets('DashboardBelowFilterShimmer renders properly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardBelowFilterShimmer(),
          ),
        ),
      ),
    );

    expect(find.byType(DashboardBelowFilterShimmer), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });
}
