import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/sites/data/datasources/sites_remote_datasource.dart';
import 'package:propcare_governance/features/sites/data/models/site_detail_model.dart';
import 'package:propcare_governance/features/sites/data/models/site_model.dart';
import 'package:propcare_governance/features/sites/data/models/transition_detail_model.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/sites_bloc.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/sites_state.dart';
import 'package:propcare_governance/features/sites/presentation/pages/all_sites_page.dart';

class MockSitesRemoteDataSource implements SitesRemoteDataSource {
  final SitesResponseModel response;
  MockSitesRemoteDataSource(this.response);

  @override
  Future<SitesResponseModel> getSites({
    int offset = 0,
    int limit = 20,
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? mode,
    String? status,
    String? search,
    String? tab,
  }) async {
    return response;
  }

  @override
  Future<RenewalSitesResponseModel> getRenewalSites({
    String window = '30',
    int offset = 0,
    int limit = 20,
    String? zoneId,
    String? clusterId,
    String? clientType,
    String? search,
  }) async {
    return const RenewalSitesResponseModel(
      items: [],
      total: 0,
      window: '30',
      windowCounts: RenewalWindowCountsModel(
        count30: 0,
        count60: 0,
        count90: 0,
        countPending: 0,
      ),
    );
  }

  @override
  Future<SiteDetailResponseModel> getSiteDetail(String siteId) async =>
      throw UnimplementedError();

  @override
  Future<TransitionSiteDetailResponseModel> getTransitionDetail(String siteId) async =>
      throw UnimplementedError();

  @override
  Future<void> updateSpecialAttention(
    String siteId, {
    required bool enabled,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {}

  @override
  Future<void> updateClassification(
    String siteId, {
    required String clientType,
    required String effectiveDate,
    required String reason,
  }) async {}

  @override
  Future<void> updateLifecycle(
    String siteId, {
    required String action,
    required String reason,
  }) async {}
}

void main() {
  testWidgets('AllSitesPage renders correctly without Export and Create Site buttons', (tester) async {
    const sampleSite = SiteItemModel(
      id: 'site_1',
      name: 'BPT',
      code: 'BPT_0001',
      clientName: 'BPT Client',
      clientType: 'A',
      mode: 'NEW',
      status: 'LIVE',
      primaryServiceId: 'srv_1',
      manpowerRequired: 32,
      manpowerDeployed: 0,
      shortage: 32,
      billingPm: '740000.00',
      specialAttention: false,
      specialAttentionActive: false,
      special: false,
      zone: 'Hospitality',
      zoneName: 'Hospitality Zone',
      cluster: 'Pan India',
      clusterName: 'Pan India',
      group: 'Pan India',
      groupName: 'Pan India',
      service: 'HK',
      serviceName: 'Housekeeping',
      lead: 'Baskaran',
      leadName: 'Baskaran',
      head: 'Pandiyan',
      headName: 'Pandiyan',
    );

    const sampleResponse = SitesResponseModel(
      items: [sampleSite],
      total: 1,
      tabCounts: SiteTabCountsModel(
        all: 6,
        live: 5,
        transition: 4,
        special: 1,
        draft: 0,
        delayed: 0,
      ),
    );

    final bloc = SitesBloc(dataSource: MockSitesRemoteDataSource(sampleResponse));
    bloc.emit(const SitesLoaded(response: sampleResponse));

    await tester.pumpWidget(
      MaterialApp(
        home: AllSitesPage(bloc: bloc),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('All Sites'), findsWidgets);
    expect(find.text('Site master · access is filtered to your geography scope'), findsOneWidget);

    // Verify Export and Create buttons are ABSENT as requested
    expect(find.text('Export'), findsNothing);
    expect(find.text('+ Create Site'), findsNothing);
    expect(find.text('Create Site'), findsNothing);

    // Verify Metric Tabs
    expect(find.text('Live Sites'), findsOneWidget);
    expect(find.text('Transition'), findsOneWidget);
    expect(find.text('Special attention'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);

    // Verify Site Item row info
    expect(find.text('BPT'), findsOneWidget);
    expect(find.text('₹7.40L'), findsOneWidget);
  });
}
