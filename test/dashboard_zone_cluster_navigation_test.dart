import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/models/meta_model.dart';
import 'package:propcare_governance/core/services/meta_service.dart';
import 'package:propcare_governance/features/dashboard/data/models/dashboard_model.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:propcare_governance/features/sites/presentation/pages/all_sites_page.dart';

void main() {
  setUp(() {
    MetaService.instance.setMockMeta(
      const MetaDataModel(
        roles: {},
        units: [
          MetaUnitModel(
            id: 'zone-andra',
            name: 'Andra Pradesh',
            code: 'AP',
            kind: 'ZONE',
          ),
          MetaUnitModel(
            id: 'zone-karnataka',
            name: 'Karnataka',
            code: 'KA',
            kind: 'ZONE',
          ),
          MetaUnitModel(
            id: 'cluster-bhojpur',
            name: 'Bhojpur',
            code: 'BH',
            kind: 'CLUSTER',
            zoneId: 'zone-andra',
          ),
        ],
        users: [],
        sites: [],
      ),
    );
  });

  testWidgets('Tapping a Zone in Zones card navigates to AllSitesPage with zone filter', (tester) async {
    const zone = ZoneModel(
      id: 'zone-andra',
      name: 'Andra Pradesh',
      sites: 5,
      live: 3,
      transition: 2,
      clusters: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZonesCard(zones: [zone]),
          ),
        ),
      ),
    );

    expect(find.text('Andra Pradesh'), findsOneWidget);

    await tester.tap(find.text('Andra Pradesh'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AllSitesPage), findsOneWidget);
  });

  testWidgets('Tapping a Cluster in Clusters card navigates to AllSitesPage with cluster filter', (tester) async {
    const cluster = ClusterModel(
      id: 'cluster-bhojpur',
      name: 'Bhojpur',
      zoneName: 'Andra Pradesh',
      sites: 2,
      live: 1,
      transition: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClustersCard(clusters: [cluster]),
          ),
        ),
      ),
    );

    expect(find.text('Bhojpur'), findsOneWidget);

    await tester.tap(find.text('Bhojpur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AllSitesPage), findsOneWidget);
  });

  testWidgets('DueSitesBar renders new design with 3D map illustration and 30/60/90 cards', (tester) async {
    const renewals = RenewalCountsModel(
      d30: 3,
      d60: 2,
      d90: 0,
      items30: [
        RenewalItemModel(
          id: 'site-1',
          code: 'SITE_01',
          name: 'Site Alpha',
          clientName: 'Client Alpha',
          contractEndDate: '2026-12-01',
          clusterName: 'ORR',
          zoneName: 'Karnataka',
          daysRemaining: 15,
        ),
      ],
      items60: [],
      items90: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DueSitesBar(renewals: renewals),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Due Sites'), findsOneWidget);
    expect(find.text('Across Zones'), findsOneWidget);

    // Verify 3 Interval Cards with days & counts
    expect(find.text('30 Days'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('60 Days'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('90 Days'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Tapping 30 Days expands details list with site name
    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();
    expect(find.text('Due in 30 Days (1)'), findsOneWidget);
    expect(find.text('Site Alpha'), findsOneWidget);

    // Tapping again collapses
    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();
    expect(find.text('Site Alpha'), findsNothing);
  });
}
