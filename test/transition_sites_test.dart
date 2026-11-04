import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/sites/data/datasources/sites_remote_datasource.dart';
import 'package:propcare_governance/features/sites/data/models/site_detail_model.dart';
import 'package:propcare_governance/features/sites/data/models/site_model.dart';
import 'package:propcare_governance/features/sites/data/models/transition_detail_model.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/transition_bloc.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/transition_event.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/transition_state.dart';
import 'package:propcare_governance/features/sites/presentation/pages/transition_sites_page.dart';

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
    throw UnimplementedError();
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
  const sampleDraftSite = SiteItemModel(
    id: 'd94a424e-2bb5-4366-962e-569676f5e97b',
    name: 'test',
    code: 'TEST_0001',
    clientName: 'test',
    clientType: 'A',
    billingPm: '740000.00',
    mode: 'NEW',
    status: 'DRAFT',
    primaryServiceId: '0b22fc91',
    manpowerRequired: 32,
    manpowerDeployed: 0,
    shortage: 32,
    specialAttention: false,
    specialAttentionActive: false,
    special: false,
    zone: 'Mumbai',
    zoneName: 'Mumbai Zone',
    cluster: 'Mumbai',
    clusterName: 'Mumbai',
    group: 'Mumbai',
    groupName: 'Mumbai',
    service: 'HK',
    serviceName: 'HK',
    lead: 'Yuva',
    leadName: 'Yuva',
    head: '—',
    headName: '—',
  );

  const sampleLiveTransitionSite = SiteItemModel(
    id: '3f6a5cf1-f450-4658-a813-82cf96f0c24a',
    name: 'newcompany',
    code: 'NEWCOM_0001',
    clientName: 'newcompany',
    clientType: 'A',
    billingPm: '740000.00',
    mode: 'NEW',
    status: 'LIVE',
    ldStatus: 'OPEN',
    primaryServiceId: '5fe134fd',
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
    service: 'IFM',
    serviceName: 'IFM',
    lead: 'Baskaran',
    leadName: 'Baskaran',
    head: '—',
    headName: '—',
  );

  const sampleClosedTransitionSite = SiteItemModel(
    id: 'bac7c24c-4c5c-4c2e-8b09-d035ef2ad8c4',
    name: 'DIGILOGY-DEV',
    code: 'DIGILO_0002',
    clientName: 'DIGILOGY-DEV',
    clientType: 'A',
    billingPm: '740000.00',
    mode: 'NEW',
    status: 'LIVE',
    ldStatus: 'VERIFIED',
    ldTransitionComplete: true,
    transitionClosed: true,
    primaryServiceId: '0b22fc91',
    manpowerRequired: 32,
    manpowerDeployed: 0,
    shortage: 32,
    specialAttention: false,
    specialAttentionActive: false,
    special: false,
    zone: 'Tamil Nadu',
    zoneName: 'Tamil Nadu Zone',
    cluster: 'MMN',
    clusterName: 'MMN',
    group: 'MMN',
    groupName: 'MMN',
    service: 'HK',
    serviceName: 'HK',
    lead: 'Siva',
    leadName: 'Siva',
    head: '—',
    headName: '—',
  );

  final mockResponse = SitesResponseModel(
    items: const [
      sampleDraftSite,
      sampleLiveTransitionSite,
      sampleClosedTransitionSite,
    ],
    total: 3,
    tabCounts: const SiteTabCountsModel(
      all: 3,
      draft: 1,
      live: 1,
      transition: 1,
      delayed: 0,
      special: 0,
    ),
  );

  group('Transition Model Helpers', () {
    test('identifies draft site as Site Creation stage', () {
      expect(sampleDraftSite.isSiteCreation, isTrue);
      expect(sampleDraftSite.isSiteLive, isFalse);
      expect(sampleDraftSite.isTransitionComplete, isFalse);
      expect(sampleDraftSite.transitionStageLabel, '1. Site Creation');
      expect(sampleDraftSite.transitionActionRequired, 'Save and go live from Create Site');
      expect(sampleDraftSite.transitionWorkflowButtonLabel, 'Site Creation →');
    });

    test('identifies live site with open LD as Site Live stage', () {
      expect(sampleLiveTransitionSite.isSiteCreation, isFalse);
      expect(sampleLiveTransitionSite.isSiteLive, isTrue);
      expect(sampleLiveTransitionSite.isTransitionComplete, isFalse);
      expect(sampleLiveTransitionSite.transitionStageLabel, '2. Site Live');
      expect(sampleLiveTransitionSite.transitionActionRequired, 'Awaiting L&D Head Stability Verify');
      expect(sampleLiveTransitionSite.transitionWorkflowButtonLabel, 'Site Live →');
    });

    test('identifies closed site as Transition Closed stage', () {
      expect(sampleClosedTransitionSite.isSiteCreation, isFalse);
      expect(sampleClosedTransitionSite.isSiteLive, isFalse);
      expect(sampleClosedTransitionSite.isTransitionComplete, isTrue);
      expect(sampleClosedTransitionSite.transitionStageLabel, 'Live · Transition Closed');
      expect(sampleClosedTransitionSite.transitionActionRequired, 'Transition complete — governance active');
      expect(sampleClosedTransitionSite.transitionWorkflowButtonLabel, 'View →');
    });
  });

  group('TransitionBloc Tests', () {
    test('loads transition sites and sets counts correctly', () async {
      final mockDs = MockSitesRemoteDataSource(mockResponse);
      final bloc = TransitionBloc(dataSource: mockDs);

      bloc.add(const LoadTransitionSites());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const TransitionLoading(),
          isA<TransitionLoaded>()
              .having((s) => s.countAll, 'countAll', 3)
              .having((s) => s.countSiteCreation, 'countSiteCreation', 1)
              .having((s) => s.countTransitionComplete, 'countTransitionComplete', 1)
              .having((s) => s.filteredSites.length, 'filteredSites.length', 3),
        ]),
      );
    });

    test('filters by stage tabs properly', () async {
      final mockDs = MockSitesRemoteDataSource(mockResponse);
      final bloc = TransitionBloc(dataSource: mockDs);

      bloc.add(const LoadTransitionSites());
      await bloc.stream.firstWhere((s) => s is TransitionLoaded);

      bloc.add(const ChangeTransitionTab('Site Creation'));
      await expectLater(
        bloc.stream,
        emits(
          isA<TransitionLoaded>()
              .having((s) => s.activeTab, 'activeTab', 'Site Creation')
              .having((s) => s.filteredSites.length, 'count', 1)
              .having((s) => s.filteredSites.first.name, 'name', 'test'),
        ),
      );

      bloc.add(const ChangeTransitionTab('Transition Complete'));
      await expectLater(
        bloc.stream,
        emits(
          isA<TransitionLoaded>()
              .having((s) => s.activeTab, 'activeTab', 'Transition Complete')
              .having((s) => s.filteredSites.length, 'count', 1)
              .having((s) => s.filteredSites.first.name, 'name', 'DIGILOGY-DEV'),
        ),
      );
    });

    test('filters by search query', () async {
      final mockDs = MockSitesRemoteDataSource(mockResponse);
      final bloc = TransitionBloc(dataSource: mockDs);

      bloc.add(const LoadTransitionSites());
      await bloc.stream.firstWhere((s) => s is TransitionLoaded);

      bloc.add(const ChangeTransitionSearch('NEWCOM'));
      await expectLater(
        bloc.stream,
        emits(
          isA<TransitionLoaded>()
              .having((s) => s.searchQuery, 'searchQuery', 'NEWCOM')
              .having((s) => s.filteredSites.length, 'count', 1)
              .having((s) => s.filteredSites.first.name, 'name', 'newcompany'),
        ),
      );
    });
  });

  group('TransitionSitesPage Widget Rendering', () {
    testWidgets('renders table, tabs, badges and buttons correctly on desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDs = MockSitesRemoteDataSource(mockResponse);
      final bloc = TransitionBloc(dataSource: mockDs);
      bloc.emit(TransitionLoaded(
        allSites: mockResponse.items,
        filteredSites: mockResponse.items,
        countAll: 3,
        countSiteCreation: 1,
        countSiteLive: 1,
        countTransitionComplete: 1,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: TransitionSitesPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Lifecycle note
      expect(find.text('Transition & Start-Up'), findsOneWidget);
      expect(
        find.textContaining('Lifecycle: Site Creation'),
        findsOneWidget,
      );

      // Tab pills
      expect(find.text('All Sites (3)'), findsOneWidget);
      expect(find.text('Site Creation (1)'), findsOneWidget);
      expect(find.text('Transition Complete (1)'), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Card view is default, verify sites rendered
      expect(find.text('test'), findsOneWidget);
      expect(find.text('newcompany'), findsOneWidget);
      expect(find.text('DIGILOGY-DEV'), findsOneWidget);

      // Switch to Table view
      await tester.tap(find.byTooltip('Table view'));
      await tester.pumpAndSettle();

      // Table columns
      expect(find.text('Site & Client'), findsOneWidget);
      expect(find.text('Current Transition Stage'), findsOneWidget);
      expect(find.text('Action Required'), findsOneWidget);
      expect(find.text('Workflow Action'), findsOneWidget);

      // Stage badges
      expect(find.text('1. Site Creation'), findsOneWidget);
      expect(find.text('2. Site Live'), findsOneWidget);
      expect(find.text('Live · Transition Closed'), findsOneWidget);

      // Action required texts
      expect(find.text('Save and go live from Create Site'), findsOneWidget);
      expect(find.text('Awaiting L&D Head Stability Verify'), findsOneWidget);
      expect(find.text('Transition complete — governance active'), findsOneWidget);

      // Buttons
      expect(find.text('Site Creation →'), findsOneWidget);
      expect(find.text('Site Live →'), findsOneWidget);
      expect(find.text('View →'), findsOneWidget);

      // Tap on 'Site Creation (1)' tab
      await tester.tap(find.text('Site Creation (1)'));
      await tester.pumpAndSettle();

      // Only 'test' should remain in table
      expect(find.text('test'), findsOneWidget);
      expect(find.text('newcompany'), findsNothing);
      expect(find.text('DIGILOGY-DEV'), findsNothing);
    });
  });
}
