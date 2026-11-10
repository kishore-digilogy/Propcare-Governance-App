import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/activities/data/datasources/activities_remote_datasource.dart';
import 'package:propcare_governance/features/activities/data/models/activity_detail_model.dart';
import 'package:propcare_governance/features/activities/data/models/activity_site_summary_model.dart';
import 'package:propcare_governance/features/activities/data/models/checklist_report_model.dart';
import 'package:propcare_governance/features/activities/data/models/site_activity_item_model.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/checklist_report_bloc.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/checklist_report_event.dart';
import 'package:propcare_governance/features/activities/presentation/pages/checklist_report_detail_page.dart';
import 'package:propcare_governance/features/activities/presentation/pages/checklist_report_page.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';

class MockChecklistReportRemoteDataSource
    implements ActivitiesRemoteDataSource {
  final ChecklistReportResponseModel summaryResponse;
  final SiteChecklistDetailResponseModel detailResponse;
  List<Map<String, dynamic>>? lastSavedAnswers;
  String? lastSavedActivityId;

  MockChecklistReportRemoteDataSource({
    required this.summaryResponse,
    required this.detailResponse,
  });

  @override
  Future<ChecklistReportResponseModel> getChecklistBySite() async {
    return summaryResponse;
  }

  @override
  Future<SiteChecklistDetailResponseModel> getChecklistDetailBySite(
      String siteId) async {
    return detailResponse;
  }

  @override
  Future<bool> saveChecklistAnswers({
    required String activityId,
    required List<Map<String, dynamic>> answers,
  }) async {
    lastSavedActivityId = activityId;
    lastSavedAnswers = answers;
    return true;
  }

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
    throw UnimplementedError();
  }

  @override
  Future<ActivitiesBySiteResponseModel> getActivitiesBySite({
    required String view,
    String? zoneId,
    String? clusterId,
    String? status,
    String? role,
  }) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<ActivityDetailModel> getActivityDetail(String activityId) async {
    throw UnimplementedError();
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
}

void main() {
  const sampleSummary = ChecklistReportResponseModel(
    pending: 3,
    completed: 107,
    activities: 4,
    sites: 2,
    items: [
      ChecklistReportItemModel(
        id: 'act_1',
        siteId: 'site_digilogy',
        siteName: 'DIGILOGY-2',
        siteCity: 'NA',
        siteClientType: 'A',
        zoneName: 'Karnataka',
        clusterName: 'E-City',
        siteStatus: 'LIVE',
        activityLabel: 'Cluster Lead Visit',
        role: 'CLUSTER_LEAD',
        roleLabel: 'Cluster Lead',
        frequencyLabel: 'Monthly',
        visitDate: '2026-11-03',
        pending: 2,
        completed: 10,
      ),
      ChecklistReportItemModel(
        id: 'act_2',
        siteId: 'site_space_intel',
        siteName: 'Space Intel',
        siteCity: 'NA',
        siteClientType: 'A',
        zoneName: 'Karnataka',
        clusterName: 'ORR',
        siteStatus: 'LIVE',
        activityLabel: 'Cluster Executive Visit',
        role: 'CLUSTER_EXECUTIVE',
        roleLabel: 'Cluster Executive',
        frequencyLabel: 'Every 15 Days',
        visitDate: '2026-10-22',
        pending: 1,
        completed: 31,
      ),
    ],
  );

  const sampleDetail = SiteChecklistDetailResponseModel(
    siteId: 'site_digilogy',
    siteName: 'DIGILOGY-2',
    siteClientType: 'A',
    pending: 2,
    items: [
      SiteChecklistActivityItemModel(
        id: 'act_1',
        title: 'Cluster Lead Visit',
        role: 'CLUSTER_LEAD',
        roleLabel: 'Cluster Lead',
        visitDate: '2026-11-03',
        scheduledDate: '2026-11-03',
        dueDate: '2026-12-04',
        code: 'ACT-2882C',
        clientType: 'A',
        status: 'COMPLETED',
        frequencyLabel: 'Monthly',
        pending: 2,
        completed: 10,
        spoc: 'Balasubramani',
        mom: 'Sent',
        template: [
          ChecklistTemplateItemModel(
            key: 'CLUSTER_LEAD:entrance_sofas_crevices',
            title: 'Sofas & Crevices Areas',
            section: 'Entrance Door, Reception, Floor Mat Condition, Fragrance',
            sortOrder: 1,
          ),
          ChecklistTemplateItemModel(
            key: 'CLUSTER_LEAD:entrance_glass_door',
            title: 'Glass Door Clean & Clear',
            section: 'Entrance Door, Reception, Floor Mat Condition, Fragrance',
            sortOrder: 2,
          ),
          ChecklistTemplateItemModel(
            key: 'CLUSTER_LEAD:washroom_odour',
            title: 'Odour',
            section: 'Washroom (Sample Restrooms) - 1 Male & Female',
            sortOrder: 3,
          ),
        ],
        answers: [
          ChecklistAnswerItemModel(
            key: 'CLUSTER_LEAD:entrance_sofas_crevices',
            status: 'OK',
            remarks: '',
          ),
          ChecklistAnswerItemModel(
            key: 'CLUSTER_LEAD:entrance_glass_door',
            status: 'ISSUE',
            remarks: 'rgweyewyew',
          ),
          ChecklistAnswerItemModel(
            key: 'CLUSTER_LEAD:washroom_odour',
            status: 'ISSUE',
            remarks: 'segtewtre',
          ),
        ],
      ),
    ],
  );

  group('ChecklistReport Models', () {
    test('ChecklistReportResponseModel.fromJson parses correctly', () {
      final json = {
        'items': [
          {
            'id': '2882ca5b',
            'siteId': 'd8bd1c62',
            'siteName': 'DIGILOGY-2',
            'siteCity': 'NA',
            'siteClientType': 'A',
            'zoneName': 'Karnataka',
            'clusterName': 'E-City',
            'siteStatus': 'LIVE',
            'activityLabel': 'Cluster Lead Visit',
            'role': 'CLUSTER_LEAD',
            'roleLabel': 'Cluster Lead',
            'frequencyLabel': 'Monthly',
            'visitDate': '2026-11-03',
            'pending': 2,
            'completed': 10,
          }
        ],
        'pending': 3,
        'completed': 107,
        'activities': 4,
        'sites': 2,
      };

      final model = ChecklistReportResponseModel.fromJson(json);
      expect(model.pending, 3);
      expect(model.completed, 107);
      expect(model.allCount, 110);
      expect(model.items.length, 1);
      expect(model.items.first.siteName, 'DIGILOGY-2');
      expect(model.items.first.pending, 2);
      expect(model.items.first.completed, 10);
    });

    test('SiteChecklistDetailResponseModel.fromJson parses correctly', () {
      final json = {
        'siteId': '93130acb',
        'siteName': 'Space Intel',
        'siteClientType': 'A',
        'pending': 1,
        'items': [
          {
            'id': '2a0b837a',
            'title': 'Cluster Executive Visit',
            'role': 'CLUSTER_EXECUTIVE',
            'roleLabel': 'Cluster Executive',
            'visitDate': '2026-10-22',
            'scheduledDate': '2026-11-14',
            'dueDate': '2026-11-14',
            'code': 'ACT-2A0B8',
            'template': [
              {
                'key': 'CLUSTER_LEAD:entrance_sofas_crevices',
                'title': 'Sofas & Crevices Areas',
                'section':
                    'Entrance Door, Reception, Floor Mat Condition, Fragrance',
                'sortOrder': 1,
              }
            ],
            'answers': [
              {
                'key': 'CLUSTER_LEAD:entrance_sofas_crevices',
                'status': 'OK',
                'remarks': '',
              }
            ],
          }
        ],
      };

      final model = SiteChecklistDetailResponseModel.fromJson(json);
      expect(model.siteName, 'Space Intel');
      expect(model.items.length, 1);
      expect(model.items.first.template.length, 1);
      expect(model.items.first.template.first.title, 'Sofas & Crevices Areas');
      expect(model.items.first.answers.first.status, 'OK');
    });
  });

  group('ChecklistReportBloc', () {
    test('LoadChecklistReport loads summary and populates state', () async {
      final mockDataSource = MockChecklistReportRemoteDataSource(
        summaryResponse: sampleSummary,
        detailResponse: sampleDetail,
      );
      final bloc = ChecklistReportBloc(remoteDataSource: mockDataSource);

      bloc.add(const LoadChecklistReport());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isLoadingSummary, false);
      expect(bloc.state.summary, sampleSummary);
      expect(bloc.state.filteredItems.length, 2);
    });

    test('LoadSiteChecklistDetail loads detail and answers map', () async {
      final mockDataSource = MockChecklistReportRemoteDataSource(
        summaryResponse: sampleSummary,
        detailResponse: sampleDetail,
      );
      final bloc = ChecklistReportBloc(remoteDataSource: mockDataSource);

      bloc.add(const LoadSiteChecklistDetail(siteId: 'site_digilogy'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isLoadingDetail, false);
      expect(bloc.state.detailSite, sampleDetail);
      expect(bloc.state.selectedActivityId, 'act_1');
      expect(bloc.state.currentYesCount, 1);
      expect(bloc.state.currentNoCount, 2);
    });

    test('UpdateChecklistAnswer updates status and remarks', () async {
      final mockDataSource = MockChecklistReportRemoteDataSource(
        summaryResponse: sampleSummary,
        detailResponse: sampleDetail,
      );
      final bloc = ChecklistReportBloc(remoteDataSource: mockDataSource);

      bloc.add(const LoadSiteChecklistDetail(siteId: 'site_digilogy'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Change from ISSUE (No) to OK (Yes)
      bloc.add(const UpdateChecklistAnswer(
        key: 'CLUSTER_LEAD:entrance_glass_door',
        status: 'OK',
        remarks: 'Cleaned and fixed',
      ));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.currentAnswers['CLUSTER_LEAD:entrance_glass_door']?.status,
          'OK');
      expect(
          bloc.state.currentAnswers['CLUSTER_LEAD:entrance_glass_door']?.remarks,
          'Cleaned and fixed');
      expect(bloc.state.currentYesCount, 2);
      expect(bloc.state.currentNoCount, 1);
    });

    test('SaveCurrentChecklist sends PATCH answers to API', () async {
      final mockDataSource = MockChecklistReportRemoteDataSource(
        summaryResponse: sampleSummary,
        detailResponse: sampleDetail,
      );
      final bloc = ChecklistReportBloc(remoteDataSource: mockDataSource);

      bloc.add(const LoadSiteChecklistDetail(siteId: 'site_digilogy'));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const SaveCurrentChecklist());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isSaving, false);
      expect(bloc.state.saveSuccess, true);
      expect(mockDataSource.lastSavedActivityId, 'act_1');
      expect(mockDataSource.lastSavedAnswers != null, true);
      expect(mockDataSource.lastSavedAnswers!.length, 3);
    });
  });

  group('ChecklistReportPage UI tests', () {
    testWidgets('renders header, 3 top stat cards, and site list',
        (tester) async {
      final mockDataSource = MockChecklistReportRemoteDataSource(
        summaryResponse: sampleSummary,
        detailResponse: sampleDetail,
      );
      final bloc = ChecklistReportBloc(remoteDataSource: mockDataSource);

      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistReportPage(bloc: bloc),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Checklist Report'), findsWidgets);
      expect(
        find.text(
            'Update Walkaround Pending (No) Lines To Completed After The Visit.'),
        findsOneWidget,
      );

      // Verify Top Stat Cards
      expect(find.text('All'), findsOneWidget);
      expect(find.text('110'), findsOneWidget); // 107 + 3
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('107'), findsOneWidget);

      // Verify Sites
      expect(find.text('DIGILOGY-2'), findsOneWidget);
      expect(find.text('Space Intel'), findsOneWidget);
    });
  });

  group('ChecklistReportDetailPage UI tests', () {
    testWidgets(
        'renders detail page with sections, Yes/No/NA pills, and save button',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDataSource = MockChecklistReportRemoteDataSource(
        summaryResponse: sampleSummary,
        detailResponse: sampleDetail,
      );
      final bloc = ChecklistReportBloc(remoteDataSource: mockDataSource);

      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistReportDetailPage(
            siteId: 'site_digilogy',
            siteName: 'DIGILOGY-2',
            initialActivityId: 'act_1',
            bloc: bloc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Breadcrumbs & Site Title
      expect(find.text('Checklist Report'), findsOneWidget);
      expect(find.text('DIGILOGY-2'), findsWidgets);

      // Verify Template Section headers
      expect(
        find.text('Entrance Door, Reception, Floor Mat Condition, Fragrance'),
        findsOneWidget,
      );
      expect(
        find.text('Washroom (Sample Restrooms) - 1 Male & Female'),
        findsOneWidget,
      );

      // Verify items
      expect(find.text('Sofas & Crevices Areas'), findsOneWidget);
      expect(find.text('Glass Door Clean & Clear'), findsOneWidget);
      expect(find.text('Odour'), findsOneWidget);

      // Verify Activity Master
      expect(find.text('Activity Master'), findsOneWidget);
      expect(find.text('ACT-2882C'), findsOneWidget);

      // Verify Save checklist button
      expect(find.text('Save checklist'), findsOneWidget);

      // Tap Save checklist
      await tester.ensureVisible(find.text('Save checklist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save checklist'));
      await tester.pumpAndSettle();

      expect(mockDataSource.lastSavedActivityId, 'act_1');
    });
  });

  group('Quick Actions on Dashboard', () {
    testWidgets('renders Checklist Report quick action for all roles',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickActionsGridView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Checklist Report'), findsOneWidget);
      expect(
        find.text('Update walkaround pending lines to completed'),
        findsOneWidget,
      );
    });
  });
}
