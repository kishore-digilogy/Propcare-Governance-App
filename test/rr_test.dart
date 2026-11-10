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
import 'package:propcare_governance/features/activities/presentation/pages/rr_page.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';

class MockRrRemoteDataSource implements ActivitiesRemoteDataSource {
  final SiteActivitiesResponseModel rrResponse;
  String? lastViewPassed;
  String? lastKindPassed;
  String? lastStatusPassed;
  String? lastStatusBucketPassed;

  MockRrRemoteDataSource({required this.rrResponse});

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
    return rrResponse;
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
      myRoleLabel: 'CRRM / Super Admin',
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
    return rrResponse;
  }

  @override
  Future<ActivityDetailModel> getActivityDetail(String activityId) async {
    return const ActivityDetailModel(
      activity: ActivityItemDetailModel(
        id: 'act_rr_1',
        siteId: 'site_1',
        role: 'CRRM',
        kind: 'RR',
        title: 'Recognition & Reward Visit',
        scheduledDate: '2026-11-30',
        dueDate: '2026-11-30',
        status: 'OPEN',
        statusLabel: 'Pending',
        clientType: 'A',
        code: 'ACT-RR-01',
        functionLabel: 'Governance',
        roleLabel: 'CRRM',
        frequencyLabel: 'Quarterly',
        priority: 'Medium',
      ),
      site: ActivitySiteDetailModel(
        id: 'site_1',
        name: 'Space Intel',
        code: 'SPACE_01',
        clientName: 'Space Client',
        city: 'NA',
        state: 'Karnataka',
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
  setUp(() {
    MetaService.instance.setMockMeta(const MetaDataModel(
      users: [],
      sites: [
        MetaSiteModel(id: 's1', name: 'Digilogy'),
        MetaSiteModel(id: 's2', name: 'Space Intel'),
      ],
      units: [],
    ));
  });

  tearDown(() {
    HiveStorage.mockUserRole = null;
  });

  const emptySampleJson = {
    "items": [],
    "total": 0,
    "limit": 10,
    "offset": 0,
    "counts": {
      "today": 1,
      "upcoming": 80,
      "pending": 81,
      "overdue": 4,
      "all": 92,
      "scheduled": 0,
      "assigned": 0,
      "completed": 0,
      "summaryPending": 0,
      "summaryOverdue": 0
    },
    "view": null,
    "myRole": "CRRM",
    "myRoleLabel": "CRRM / Super Admin",
    "belowRoles": [
      {"role": "CEO", "label": "CEO"},
      {"role": "COO", "label": "COO"}
    ],
    "mineTotal": 0,
    "belowTotal": 0
  };

  const populatedSampleJson = {
    "items": [
      {
        "id": "e61c9749-981c-48da-9c51-c49e969a1390",
        "siteId": "s1",
        "siteName": "Digilogy",
        "role": "CRRM",
        "kind": "RR",
        "title": "Recognition & Reward · Digilogy",
        "scheduledDate": "2026-11-30",
        "dueDate": "2026-11-30",
        "status": "OPEN",
        "statusLabel": "Pending",
        "clientType": "B",
        "code": "ACT-RR-101",
        "zoneName": "Tamil Nadu",
        "clusterName": "OMR",
        "functionLabel": "Governance",
        "roleLabel": "CRRM",
        "frequencyLabel": "Quarterly",
        "priority": "Medium"
      }
    ],
    "total": 1,
    "limit": 10,
    "offset": 0,
    "counts": {
      "today": 0,
      "upcoming": 1,
      "pending": 1,
      "overdue": 0,
      "all": 1,
      "scheduled": 0,
      "assigned": 1,
      "completed": 0,
      "summaryPending": 1,
      "summaryOverdue": 0
    },
    "view": null,
    "myRole": "CRRM",
    "myRoleLabel": "CRRM / Super Admin",
    "belowRoles": [],
    "mineTotal": 0,
    "belowTotal": 0
  };

  group('Quick Actions R&R Tests', () {
    testWidgets('Quick Actions renders R&R card for Super Admin (CRRM)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      HiveStorage.mockUserRole = 'CRRM';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: QuickActionsGridView()),
        ),
      );
      await tester.pumpAndSettle();

      // Look for R&R in Quick Actions
      expect(find.text('R&R'), findsOneWidget);
      expect(find.text('Recognition and reward governance visits'), findsOneWidget);
    });

    testWidgets('Quick Actions renders R&R card for Cluster Lead', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      HiveStorage.mockUserRole = 'CLUSTER_LEAD';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: QuickActionsGridView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('R&R'), findsOneWidget);
      expect(find.text('MMR / MIS'), findsOneWidget);
    });
  });

  group('RrPage UI Tests', () {
    testWidgets('renders RrPage with empty state matching user screenshot', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final res = SiteActivitiesResponseModel.fromJson(emptySampleJson);
      final ds = MockRrRemoteDataSource(rrResponse: res);
      final bloc = ActivitiesBloc(remoteDataSource: ds);

      await tester.pumpWidget(
        MaterialApp(
          home: RrPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('R&R'), findsWidgets);
      expect(find.textContaining('Recognition And Reward Visits From The Governance Matrix'), findsOneWidget);

      // Stat cards: Total Activity, Completed, Pending, Due
      expect(find.text('Total Activity'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Due'), findsWidgets);

      // Section header
      expect(find.text('R&R Activities'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);

      // Empty state text matching user screenshot
      expect(
        find.text('No R&R Visits For These Sites. A And A+ Are N/A In The Governance Matrix, So A Visit Is Not Required.'),
        findsOneWidget,
      );
      expect(find.text('Try adjusting your search or filters.'), findsOneWidget);
    });

    testWidgets('renders RrPage with activities, card view and table view', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final res = SiteActivitiesResponseModel.fromJson(populatedSampleJson);
      final ds = MockRrRemoteDataSource(rrResponse: res);
      final bloc = ActivitiesBloc(remoteDataSource: ds);

      await tester.pumpWidget(
        MaterialApp(
          home: RrPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Card view items
      expect(find.text('Digilogy'), findsOneWidget);
      expect(find.text('Recognition & Reward · Digilogy'), findsOneWidget);
      expect(find.text('Due: 30 Nov 2026'), findsOneWidget);
      expect(find.text('Quarterly'), findsOneWidget);

      // Switch to Table view
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();

      expect(find.text('Site'), findsOneWidget);
      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Cluster'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
      expect(find.text('Status'), findsWidgets);
    });
  });

  group('ActivitiesRemoteDataSourceImpl kind=RR Tests', () {
    test('sends kind=RR and statusBucket=pending for RR activities', () async {
      final dio = Dio();
      final adapter = HttpClientAdapter();
      dio.httpClientAdapter = adapter;

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/activities');
          expect(options.queryParameters['kind'], 'RR');
          expect(options.queryParameters['statusBucket'], 'pending');
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: emptySampleJson,
          ));
        },
      ));

      final ds = ActivitiesRemoteDataSourceImpl(dio: dio);
      final res = await ds.getActivities(
        kind: 'RR',
        status: 'pending',
      );

      expect(res.total, 0);
    });
  });
}
