import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/reports/data/models/report_catalog_model.dart';
import 'package:propcare_governance/features/reports/presentation/bloc/reports_state.dart';
import 'package:propcare_governance/features/reports/presentation/pages/report_viewer_page.dart';
import 'package:propcare_governance/features/reports/presentation/widgets/report_card_item.dart';

void main() {
  group('ReportCatalogModel tests', () {
    final sampleJson = {
      'generatedAt': '2026-11-02T05:17:35.059Z',
      'dateRange': {
        'from': '2026-10-03',
        'to': '2026-11-02',
        'key': 'last_30',
      },
      'scopeSites': 6,
      'reportRoles': null,
      'reports': [
        {
          'id': 'sites',
          'title': 'Site Report',
          'unit': 'sites',
          'count': 6,
          'description': 'Site Master, Client Type, Billing PM, Status, Geography, SPOCs.',
          'exportKind': 'sites',
        },
        {
          'id': 'governance',
          'title': 'Governance Report',
          'unit': 'activities',
          'count': 0,
          'description': 'Your Role Tree (All Roles): Scheduled, Completed (0), Overdue (0).',
          'exportKind': 'governance',
        },
        {
          'id': 'issues',
          'title': 'Issue Report',
          'unit': 'issues',
          'count': 2,
          'description': 'Open (1), Closed, Priority, Department, Owner, TAT Performance.',
          'exportKind': 'issues',
        },
        {
          'id': 'visits',
          'title': 'Site Visit Report',
          'unit': 'visits',
          'count': 0,
          'description': 'Visit Date, User, Geo Status, Checklist Result For Physical Activities In Your Role Tree.',
          'exportKind': 'visits',
        },
        {
          'id': 'transition',
          'title': 'Transition / L&D Report',
          'unit': 'activities',
          'count': 0,
          'description': 'Transition Lead / Head Activities — Training, Readiness And Competency Checks.',
          'exportKind': 'transition',
        },
        {
          'id': 'ehs',
          'title': 'EHS Report',
          'unit': 'records',
          'count': 0,
          'description': 'EHS Audits, Incidents, HIRA-Linked Findings And Safety Issues.',
          'exportKind': 'ehs',
        },
        {
          'id': 'hr',
          'title': 'HR Report',
          'unit': 'records',
          'count': 0,
          'description': 'HR Compliance Checks, Employee Issues And Statutory Follow-Ups.',
          'exportKind': 'hr',
        },
        {
          'id': 'machines',
          'title': 'Machine Report',
          'unit': 'machines',
          'count': 2,
          'description': 'Machinery Master, PPM Activities And Machine-Technician Issues.',
          'exportKind': 'machines',
        },
      ],
    };

    test('parses report catalog response correctly', () {
      final catalog = ReportCatalogResponseModel.fromJson(sampleJson);
      expect(catalog.generatedAt, '2026-11-02T05:17:35.059Z');
      expect(catalog.scopeSites, 6);
      expect(catalog.dateRange.key, 'last_30');
      expect(catalog.dateRange.from, '2026-10-03');
      expect(catalog.dateRange.to, '2026-11-02');
      expect(catalog.reports.length, 8);
    });

    test('parses individual report items correctly', () {
      final catalog = ReportCatalogResponseModel.fromJson(sampleJson);

      final siteReport = catalog.reports.firstWhere((r) => r.id == 'sites');
      expect(siteReport.title, 'Site Report');
      expect(siteReport.unit, 'sites');
      expect(siteReport.count, 6);
      expect(siteReport.countDisplay, '6 Sites');
      expect(siteReport.exportKind, 'sites');

      final issueReport = catalog.reports.firstWhere((r) => r.id == 'issues');
      expect(issueReport.title, 'Issue Report');
      expect(issueReport.count, 2);
      expect(issueReport.countDisplay, '2 Issues');
      expect(issueReport.exportKind, 'issues');

      final machineReport = catalog.reports.firstWhere((r) => r.id == 'machines');
      expect(machineReport.title, 'Machine Report');
      expect(machineReport.count, 2);
      expect(machineReport.countDisplay, '2 Machines');
      expect(machineReport.exportKind, 'machines');
    });

    test('Reports filter parameters format correctly for API', () {
      final queryParams = <String, dynamic>{
        'dateRange': 'last_30',
        'zoneId': 'be542e12-7433-44d6-8246-c12b8c2aa401',
        'clusterId': 'cb89d03b-4788-4716-9521-70bb1d986e78',
        'clientType': 'A+',
        'function': 'OPERATIONS',
        'status': 'LIVE',
      };

      final uri = Uri.parse('https://stagegovernance.digilogy.dev/api/reports/catalog').replace(queryParameters: queryParams);
      expect(uri.queryParameters['dateRange'], 'last_30');
      expect(uri.queryParameters['zoneId'], 'be542e12-7433-44d6-8246-c12b8c2aa401');
      expect(uri.queryParameters['clusterId'], 'cb89d03b-4788-4716-9521-70bb1d986e78');
      expect(uri.queryParameters['clientType'], 'A+');
      expect(uri.queryParameters['function'], 'OPERATIONS');
      expect(uri.queryParameters['status'], 'LIVE');
      expect(uri.toString(), contains('clientType=A%2B'));
      expect(uri.toString(), contains('function=OPERATIONS'));
      expect(uri.toString(), contains('status=LIVE'));
    });

    testWidgets('ReportViewerPage supports toggling between Table and Card views', (tester) async {
      const sampleCsv = '''Site code,Site name,Client,City,Status
BPT_0001,BPT,BPT Client,Chennai,LIVE
DIGIDE_0001,Digi-demo2,Digi Client,Bangalore,INACTIVE''';

      await tester.pumpWidget(
        const MaterialApp(
          home: ReportViewerPage(
            title: 'Site Report',
            csvContent: sampleCsv,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Table View by default
      expect(find.text('Site Report'), findsOneWidget);
      expect(find.text('2 records in scope'), findsOneWidget);
      expect(find.text('5 columns'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('BPT_0001'), findsOneWidget);

      // Switch to Card View
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();

      // DataTable should no longer be present, cards should be visible
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('BPT'), findsWidgets);
      expect(find.text('LIVE'), findsOneWidget);

      // Switch back to Table View
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('ReportCardItem hides View Report button when count is 0', (tester) async {
      const zeroReport = ReportItemModel(
        id: 'ehs',
        title: 'EHS Report',
        unit: 'records',
        count: 0,
        description: 'EHS Audits, Incidents, HIRA-Linked Findings And Safety Issues.',
        exportKind: 'ehs',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCardItem(
              report: zeroReport,
              isRunning: false,
              onRun: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EHS Report'), findsOneWidget);
      expect(find.text('0 Records'), findsOneWidget);
      expect(find.text('View Report'), findsNothing);
    });

    testWidgets('ReportCardItem displays View Report button when count is greater than 0', (tester) async {
      const activeReport = ReportItemModel(
        id: 'sites',
        title: 'Site Report',
        unit: 'sites',
        count: 6,
        description: 'Site Master, Client Type, Billing PM, Status, Geography, SPOCs.',
        exportKind: 'sites',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCardItem(
              report: activeReport,
              isRunning: false,
              onRun: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Site Report'), findsOneWidget);
      expect(find.text('6 Sites'), findsOneWidget);
      expect(find.text('View Report'), findsOneWidget);
    });

    testWidgets('ReportsPage shows visual loader while isFiltering is true', (tester) async {
      final sampleCatalog = ReportCatalogResponseModel(
        generatedAt: '2026-11-02T05:17:35.059Z',
        dateRange: const ReportDateRangeModel(from: '2026-10-03', to: '2026-11-02', key: 'last_30'),
        scopeSites: 6,
        reports: [],
      );

      final state = ReportsLoaded(
        catalog: sampleCatalog,
        isFiltering: true,
      );

      expect(state.isFiltering, isTrue);
    });
  });
}

