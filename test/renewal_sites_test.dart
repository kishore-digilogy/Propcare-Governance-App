import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/models/meta_model.dart';
import 'package:propcare_governance/core/services/meta_service.dart';
import 'package:propcare_governance/features/sites/data/datasources/sites_remote_datasource.dart';
import 'package:propcare_governance/features/sites/data/models/site_detail_model.dart';
import 'package:propcare_governance/features/sites/data/models/site_model.dart';
import 'package:propcare_governance/features/sites/data/models/transition_detail_model.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/renewals_bloc.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/renewals_event.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/renewals_state.dart';
import 'package:propcare_governance/features/sites/presentation/pages/renewal_sites_page.dart';

class MockRenewalsRemoteDataSource implements SitesRemoteDataSource {
  final RenewalSitesResponseModel renewalResponse;

  MockRenewalsRemoteDataSource(this.renewalResponse);

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
    throw UnimplementedError();
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
    return renewalResponse;
  }

  @override
  Future<SiteDetailResponseModel> getSiteDetail(String siteId) async =>
      throw UnimplementedError();

  @override
  Future<TransitionSiteDetailResponseModel> getTransitionDetail(String siteId) async =>
      throw UnimplementedError();

  @override
  Future<TransitionSiteDetailResponseModel> saveTransitionAction(
    String siteId, {
    required String action,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> kickoff,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> raiseTransitionIssue(
    String siteId, {
    required String phase,
    required String key,
    required String issue,
    required String ownerId,
    required String remarks,
  }) async {}

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
  const sampleSite = SiteItemModel(
    id: '3f6a5cf1-f450-4658-a813-82cf96f0c24a',
    name: 'newcompany',
    code: 'NEWCOM_0001',
    clientName: 'newcompany',
    clientType: 'A',
    billingPm: '740000.00',
    contractStartDate: '2026-11-03',
    contractEndDate: '2026-11-19',
    mode: 'NEW',
    status: 'LIVE',
    primaryServiceId: 'srv_1',
    manpowerRequired: 32,
    manpowerDeployed: 0,
    shortage: 32,
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
    lead: 'Priya',
    leadName: 'Priya',
    head: 'Head',
    headName: 'Head',
    contactPersonName: 'Priya',
    contactPhone: '9876897516',
    daysRemaining: 17,
  );

  const sampleRenewalResponse = RenewalSitesResponseModel(
    items: [sampleSite],
    total: 2,
    window: '30',
    windowCounts: RenewalWindowCountsModel(
      count30: 2,
      count60: 2,
      count90: 0,
      countPending: 0,
    ),
  );

  setUp(() {
    MetaService.instance.setMockMeta(const MetaDataModel(
      users: [],
      sites: [],
      units: [],
    ));
  });

  group('Renewal Models', () {
    test('parses renewal sites response and window counts correctly', () {
      final json = {
        'items': [
          {
            'id': 'site_1',
            'name': 'newcompany',
            'code': 'NEWCOM_0001',
            'clientName': 'newcompany',
            'clientType': 'A',
            'billingPm': '740000.00',
            'contractEndDate': '2026-11-19',
            'status': 'LIVE',
            'zoneName': 'Hospitality Zone',
            'clusterName': 'Pan India',
            'daysRemaining': 17,
          }
        ],
        'total': 2,
        'window': '30',
        'windowCounts': {
          '30': 2,
          '60': 2,
          '90': 0,
          'pending': 0,
        }
      };

      final parsed = RenewalSitesResponseModel.fromJson(json);
      expect(parsed.total, 2);
      expect(parsed.window, '30');
      expect(parsed.windowCounts.count30, 2);
      expect(parsed.windowCounts.count60, 2);
      expect(parsed.windowCounts.count90, 0);
      expect(parsed.windowCounts.countPending, 0);

      final site = parsed.items.first;
      expect(site.name, 'newcompany');
      expect(site.daysRemaining, 17);
      expect(site.daysRemainingDisplay, '17 days left');
      expect(site.formattedBillingPm, '₹7.40L');
    });
  });

  group('RenewalsBloc', () {
    test('loads renewal sites successfully', () async {
      final mock = MockRenewalsRemoteDataSource(sampleRenewalResponse);
      final bloc = RenewalsBloc(dataSource: mock);

      bloc.add(const LoadRenewalSites());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const RenewalsLoading(),
          isA<RenewalsLoaded>()
              .having((s) => s.response.items.length, 'items', 1)
              .having((s) => s.selectedWindow, 'window', '30'),
        ]),
      );
      bloc.close();
    });

    test('changes renewal window properly', () async {
      final mock = MockRenewalsRemoteDataSource(sampleRenewalResponse);
      final bloc = RenewalsBloc(dataSource: mock);
      bloc.emit(const RenewalsLoaded(response: sampleRenewalResponse));

      bloc.add(const ChangeRenewalWindow('60'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RenewalsLoaded>()
              .having((s) => s.isLoadingPage, 'isLoadingPage', true)
              .having((s) => s.selectedWindow, 'selectedWindow', '60'),
          isA<RenewalsLoaded>()
              .having((s) => s.isLoadingPage, 'isLoadingPage', false)
              .having((s) => s.selectedWindow, 'selectedWindow', '60'),
        ]),
      );
      bloc.close();
    });
  });

  group('RenewalSitesPage Widget Tests', () {
    testWidgets('renders Renewal Sites page with 4 window cards, table and pagination', (tester) async {
      final mock = MockRenewalsRemoteDataSource(sampleRenewalResponse);
      final bloc = RenewalsBloc(dataSource: mock);
      bloc.emit(const RenewalsLoaded(response: sampleRenewalResponse));

      await tester.pumpWidget(
        MaterialApp(
          home: RenewalSitesPage(bloc: bloc),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Renewal Sites'), findsOneWidget);

      // Verify 4 Window Cards
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('60 Days'), findsOneWidget);
      expect(find.text('90 Days'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Verify Subheader & Table items
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('newcompany'), findsWidgets);
      expect(find.text('17 days left'), findsOneWidget);

      // Verify Pagination is hidden when total <= 10
      expect(find.text('Showing 1-2 of 2'), findsNothing);

      // Card View is default, verify Card details
      expect(find.text('View site details'), findsWidgets);

      // Switch to Table View
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();

      expect(find.text('newcompany'), findsWidgets);

      bloc.close();
    });
  });
}
