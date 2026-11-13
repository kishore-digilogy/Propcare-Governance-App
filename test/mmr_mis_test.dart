import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/models/meta_model.dart';
import 'package:propcare_governance/core/services/meta_service.dart';
import 'package:propcare_governance/core/storage/hive_storage.dart';
import 'package:propcare_governance/features/activities/data/datasources/activities_remote_datasource.dart';
import 'package:propcare_governance/features/activities/data/models/activity_detail_model.dart';
import 'package:propcare_governance/features/activities/data/models/activity_site_summary_model.dart';
import 'package:propcare_governance/features/activities/data/models/checklist_report_model.dart';
import 'package:propcare_governance/features/activities/data/models/site_activity_item_model.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/activities_bloc.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/activities_event.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/activities_state.dart';
import 'package:propcare_governance/features/activities/presentation/pages/mmr_mis_page.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';

class MockMmrMisRemoteDataSource implements ActivitiesRemoteDataSource {
  final SiteActivitiesResponseModel mmrMisResponse;
  String? lastViewPassed;
  String? lastKindPassed;
  String? lastStatusPassed;
  String? lastStatusBucketPassed;

  MockMmrMisRemoteDataSource({required this.mmrMisResponse});

  @override
  Future<SiteActivitiesResponseModel> getActivities({
    String? view,
    String? siteId,
    int offset = 0,
    int limit = 10,
    String? status,
    String? statusBucket,
    String? role,
    String? zoneId,
    String? clusterId,
    String? kind,
  }) async {
    lastViewPassed = view;
    lastKindPassed = kind;
    lastStatusPassed = status;
    lastStatusBucketPassed = statusBucket;
    return mmrMisResponse;
  }

  @override
  Future<ActivitiesBySiteResponseModel> getActivitiesBySite({
    required String view,
    String? zoneId,
    String? clusterId,
    String? status,
    String? role,
  }) async {
    return const ActivitiesBySiteResponseModel(
      items: [],
      pending: 0,
      completed: 0,
      total: 0,
      view: 'mine',
      myRoleLabel: 'Cluster Lead',
    );
  }

  @override
  Future<SiteActivitiesResponseModel> getSiteActivities({
    required String view,
    required String siteId,
    int offset = 0,
    int limit = 10,
    String? status,
    String? role,
  }) async {
    return mmrMisResponse;
  }

  @override
  Future<ActivityDetailModel> getActivityDetail(String activityId) async {
    return const ActivityDetailModel(
      activity: ActivityItemDetailModel(
        id: 'act_mmr_1',
        siteId: 'site_digilogy',
        role: 'CLUSTER_HEAD',
        kind: 'MMR',
        title: 'Monthly MIS Review · Digilogy',
        scheduledDate: '2026-11-30',
        dueDate: '2026-11-30',
        status: 'OPEN',
        statusLabel: 'Assigned',
        clientType: 'A+',
        code: 'ACT-E61C9',
        functionLabel: 'Operations',
        roleLabel: 'Cluster Head',
        frequencyLabel: 'Monthly',
        priority: 'High',
      ),
      site: ActivitySiteDetailModel(
        id: 'site_digilogy',
        name: 'Digilogy',
        code: 'DIGI_001',
        clientName: 'Digilogy Client',
        city: 'NA',
        state: 'Tamil Nadu',
        zoneId: 'z_1',
        status: 'LIVE',
      ),
    );
  }

  @override
  Future<ActivityItemDetailModel> completeActivity({
    required String activityId,
    required String visitDate,
    required bool clientMet,
    String? note,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ActivityItemDetailModel> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ChecklistReportResponseModel> getChecklistBySite() async {
    return const ChecklistReportResponseModel(items: []);
  }

  @override
  Future<SiteChecklistDetailResponseModel> getChecklistDetailBySite(String siteId) async {
    return SiteChecklistDetailResponseModel(siteId: siteId, siteName: 'Test', items: const []);
  }

  @override
  Future<bool> saveChecklistAnswers({required String activityId, required List<Map<String, dynamic>> answers}) async {
    return true;
  }
}

void main() {
  const sampleMmrActivity = SiteActivityItemModel(
    id: 'act_mmr_1',
    siteId: 'site_digilogy',
    role: 'CLUSTER_HEAD',
    kind: 'MMR',
    title: 'Monthly MIS Review · Digilogy',
    status: 'OPEN',
    clientType: 'A+',
    code: 'ACT-E61C9',
    siteName: 'Digilogy',
    siteCity: 'NA',
    zoneName: 'Tamil Nadu',
    clusterName: 'OMR',
    functionLabel: 'Operations',
    roleLabel: 'Cluster Head',
    frequencyLabel: 'Monthly',
    priority: 'High',
    statusLabel: 'Assigned',
    assignedToName: 'CJ Reddy',
    scheduledDate: '2026-11-30',
  );

  const sampleMisActivity = SiteActivityItemModel(
    id: 'act_mis_1',
    siteId: 'site_digidemo',
    role: 'CLUSTER_LEAD',
    kind: 'MIS',
    title: 'MIS preparation · Digi-demo2',
    status: 'OPEN',
    clientType: 'A',
    code: 'ACT-C0646',
    siteName: 'Digi-demo2',
    siteCity: 'NA',
    zoneName: 'Hospitality',
    clusterName: 'Pan India',
    functionLabel: 'Operations',
    roleLabel: 'Cluster Lead',
    frequencyLabel: 'Monthly',
    priority: 'Medium',
    statusLabel: 'Assigned',
    assignedToName: 'Baskaran',
    scheduledDate: '2026-11-30',
  );

  const sampleMmrMisResponse = SiteActivitiesResponseModel(
    items: [sampleMmrActivity, sampleMisActivity],
    total: 18,
    limit: 10,
    offset: 0,
    counts: SiteActivityCountsModel(
      today: 0,
      upcoming: 114,
      pending: 114,
      overdue: 0,
      all: 118,
      scheduled: 4,
      assigned: 14,
      completed: 0,
      summaryPending: 18,
      summaryOverdue: 0,
    ),
    view: 'mine',
    myRole: 'CLUSTER_LEAD',
    myRoleLabel: 'Cluster Lead',
  );

  setUp(() {
    MetaService.instance.setMockMeta(const MetaDataModel(
      users: [],
      sites: [
        MetaSiteModel(id: 'site_digilogy', name: 'Digilogy'),
        MetaSiteModel(id: 'site_digidemo', name: 'Digi-demo2'),
      ],
      units: [],
    ));
  });

  group('Cluster Lead Role & MMR / MIS Quick Actions', () {
    test('HiveStorage.isClusterLead correctly detects CLUSTER_LEAD role', () {
      HiveStorage.mockUserRole = 'CLUSTER_LEAD';
      expect(HiveStorage.isClusterLead, isTrue);

      HiveStorage.mockUserRole = 'Cluster Lead';
      expect(HiveStorage.isClusterLead, isTrue);

      HiveStorage.mockUserRole = 'CRRM';
      expect(HiveStorage.isClusterLead, isFalse);

      HiveStorage.mockUserRole = 'LD_HEAD';
      expect(HiveStorage.isClusterLead, isFalse);

      HiveStorage.mockUserRole = null;
    });

    testWidgets('Dashboard Quick Actions renders MMR / MIS specifically for Cluster Lead', (tester) async {
      HiveStorage.mockUserRole = 'CLUSTER_LEAD';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsGridView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick Actions grid must contain Reports, MMR / MIS, Issues, and R&R
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('MMR / MIS'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      // Governance Matrix and Training must NOT be in Cluster Lead quick actions
      expect(find.text('Governance Matrix'), findsNothing);
      expect(find.text('Training'), findsNothing);

      HiveStorage.mockUserRole = null;
    });

    testWidgets('Dashboard Quick Actions renders MMR / MIS also for Super Admin (CRRM)', (tester) async {
      HiveStorage.mockUserRole = 'CRRM';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsGridView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick Actions grid must contain Reports, MMR / MIS, Issues, Governance Matrix
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('MMR / MIS'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Governance Matrix'), findsOneWidget);

      HiveStorage.mockUserRole = null;
    });
  });

  group('MmrMisPage Widget Tests', () {
    testWidgets('Renders MMR / MIS page with top stat cards, search/filter bar, and cards list', (tester) async {
      final mockSource = MockMmrMisRemoteDataSource(mmrMisResponse: sampleMmrMisResponse);
      final bloc = ActivitiesBloc(remoteDataSource: mockSource);

      bloc.emit(ActivitiesLoaded(
        activitiesResponse: sampleMmrMisResponse,
        view: 'mine',
        kind: 'MIS,MMR',
        knownSites: const [
          ActivitySiteOptionModel(siteId: 'site_digilogy', siteName: 'Digilogy'),
          ActivitySiteOptionModel(siteId: 'site_digidemo', siteName: 'Digi-demo2'),
        ],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MmrMisPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('MMR / MIS'), findsOneWidget);
      expect(find.textContaining('Cluster Lead · MIS & MMR governance'), findsOneWidget);

      // Top Metric Cards
      expect(find.text('Total'), findsWidgets);
      expect(find.text('18'), findsWidgets); // Total count
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Due'), findsWidgets);

      // Section Header & count
      expect(find.text('MMR / MIS Activities'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 filtered activities

      // Activity cards
      expect(find.text('Monthly MIS Review · Digilogy'), findsOneWidget);
      expect(find.text('MIS preparation · Digi-demo2'), findsOneWidget);
      expect(find.text('ACT-E61C9'), findsOneWidget);
      expect(find.text('ACT-C0646'), findsOneWidget);
      expect(find.text('MMR'), findsOneWidget);
      expect(find.text('MIS'), findsOneWidget);
      expect(find.text('CJ Reddy'), findsOneWidget);
      expect(find.text('Baskaran'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Toggles to Table view and renders 7 columns matching web design', (tester) async {
      final mockSource = MockMmrMisRemoteDataSource(mmrMisResponse: sampleMmrMisResponse);
      final bloc = ActivitiesBloc(remoteDataSource: mockSource);

      bloc.emit(ActivitiesLoaded(
        activitiesResponse: sampleMmrMisResponse,
        view: 'mine',
        kind: 'MIS,MMR',
        knownSites: const [
          ActivitySiteOptionModel(siteId: 'site_digilogy', siteName: 'Digilogy'),
        ],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MmrMisPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Table view
      expect(find.text('Table'), findsOneWidget);
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();

      // Table is rendered with 7 columns
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Site'), findsOneWidget);
      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Cluster'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
      expect(find.text('Status'), findsWidgets);

      // Rows contain proper data
      expect(find.text('Digilogy'), findsOneWidget);
      expect(find.text('Tamil Nadu'), findsOneWidget);
      expect(find.text('OMR'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Tapping on MMR/MIS item opens ActivityExecutionView with template checklist', (tester) async {
      final mockSource = MockMmrMisRemoteDataSource(mmrMisResponse: sampleMmrMisResponse);
      final bloc = ActivitiesBloc(remoteDataSource: mockSource);

      bloc.emit(ActivitiesLoaded(
        activitiesResponse: sampleMmrMisResponse,
        view: 'mine',
        kind: 'MIS,MMR',
        knownSites: const [
          ActivitySiteOptionModel(siteId: 'site_digilogy', siteName: 'Digilogy'),
        ],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MmrMisPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the activity card
      expect(find.text('Monthly MIS Review · Digilogy'), findsOneWidget);
      await tester.tap(find.text('Monthly MIS Review · Digilogy'));
      await tester.pumpAndSettle();

      // Activity execution view opens
      expect(find.text('Activities > ACT-E61C9'), findsOneWidget);
      expect(find.text('Visit details'), findsWidgets);
      expect(find.text('Save draft'), findsOneWidget);
      expect(find.text('Submit visit'), findsWidgets);

      // Back returns to MMR / MIS list
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('MMR / MIS'), findsOneWidget);

      bloc.close();
    });

    test('LoadActivities for MMR/MIS queries without view=mine', () async {
      final mockSource = MockMmrMisRemoteDataSource(mmrMisResponse: sampleMmrMisResponse);
      final bloc = ActivitiesBloc(remoteDataSource: mockSource);

      bloc.add(const LoadActivities(kind: 'MIS,MMR'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ActivitiesLoading>(),
          isA<ActivitiesLoaded>()
              .having((s) => s.kind, 'kind', 'MIS,MMR')
              .having((s) => s.view, 'view', isNull),
        ]),
      );

      expect(mockSource.lastViewPassed, isNull);
      expect(mockSource.lastKindPassed, 'MIS,MMR');

      bloc.close();
    });

    testWidgets('MmrMisPage status filter contains Completed, Pending, Due', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockSource = MockMmrMisRemoteDataSource(mmrMisResponse: sampleMmrMisResponse);
      final bloc = ActivitiesBloc(remoteDataSource: mockSource);

      bloc.emit(ActivitiesLoaded(
        activitiesResponse: sampleMmrMisResponse,
        kind: 'MIS,MMR',
        knownSites: const [
          ActivitySiteOptionModel(siteId: 'site_digilogy', siteName: 'Digilogy'),
        ],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MmrMisPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Status dropdown placeholder is visible
      expect(find.text('Status'), findsOneWidget);

      bloc.close();
    });

    test('ActivitiesRemoteDataSourceImpl sends statusBucket for MMR/MIS', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          // Verify query parameters
          expect(options.queryParameters['kind'], 'MIS,MMR');
          expect(options.queryParameters['statusBucket'], 'pending');
          expect(options.queryParameters.containsKey('status'), isFalse);
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'items': [],
              'total': 0,
              'limit': 10,
              'offset': 0,
              'counts': {'today': 0, 'upcoming': 0, 'pending': 0, 'overdue': 0, 'all': 0},
            },
          ));
        },
      ));

      final ds = ActivitiesRemoteDataSourceImpl(dio: dio);
      await ds.getActivities(
        kind: 'MIS,MMR',
        status: 'pending',
      );
    });
  });
}
