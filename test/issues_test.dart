import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/models/meta_model.dart';
import 'package:propcare_governance/features/issues/data/datasources/issues_remote_datasource.dart';
import 'package:propcare_governance/features/issues/data/models/issue_model.dart';
import 'package:propcare_governance/features/issues/presentation/bloc/issues_bloc.dart';
import 'package:propcare_governance/features/issues/presentation/bloc/issues_state.dart';
import 'package:propcare_governance/features/issues/presentation/pages/issues_page.dart';

class _FakeIssuesRemoteDataSource implements IssuesRemoteDataSource {
  @override
  Future<IssuesResponseModel> getIssues({int offset = 0, int limit = 20, String? zoneId, String? clusterId, String? siteId, String? status}) async {
    return const IssuesResponseModel(items: [
      IssueModel(
        id: 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
        siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
        department: 'OPERATIONS',
        title: 'Potted Plants Free From Dust And Healthy',
        description: 'test',
        priority: 'MEDIUM',
        ownerId: '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
        dueDate: '2026-10-30',
        status: 'OPEN',
      ),
    ], total: 1);
  }

  @override
  Future<IssueDetailModel> getIssueDetail(String issueId) async {
    return const IssueDetailModel(
      issue: IssueModel(
        id: 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
        siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
        department: 'OPERATIONS',
        title: 'Potted Plants Free From Dust And Healthy',
        description: 'test',
        priority: 'MEDIUM',
        ownerId: '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
        dueDate: '2026-10-30',
        status: 'OPEN',
      ),
      actions: [],
    );
  }

  @override
  Future<IssueModel> createIssue(Map<String, dynamic> payload) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateIssue(String issueId, Map<String, dynamic> payload) async {
    return true;
  }

  @override
  Future<IssueActionModel> addActionPoint(Map<String, dynamic> payload) async {
    throw UnimplementedError();
  }
}

void main() {
  group('MetaModel tests', () {
    test('parses roles, units, users, sites correctly', () {
      final json = {
        'roles': {'CRRM': 'CRRM / Super Admin'},
        'units': [
          {
            'id': '65688f83-32ee-40a1-9108-3c3d96cc59d4',
            'name': 'Karnataka',
            'code': 'ZONE_KARNATAKA',
            'kind': 'ZONE',
            'parentId': null,
            'active': true
          },
          {
            'id': '7c6802b5-3d2a-4f78-aa69-54d6cc6a3d95',
            'name': 'City & ORR',
            'code': 'CLU_CITY_ORR',
            'kind': 'CLUSTER',
            'parentId': '65688f83-32ee-40a1-9108-3c3d96cc59d4',
            'zoneId': '65688f83-32ee-40a1-9108-3c3d96cc59d4',
            'active': true
          }
        ],
        'users': [
          {
            'id': '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
            'name': 'Arun Kumar',
            'role': 'CLUSTER_EXECUTIVE',
            'email': 'arunkumar.k@casagrandepropcare.com'
          }
        ],
        'sites': [
          {
            'id': '93130acb-01ba-4883-aef5-baf9e6d7f85e',
            'name': 'Space Intel',
            'zoneId': '65688f83-32ee-40a1-9108-3c3d96cc59d4',
            'clusterId': '7c6802b5-3d2a-4f78-aa69-54d6cc6a3d95',
            'status': 'LIVE'
          }
        ]
      };

      final meta = MetaDataModel.fromJson(json);
      expect(meta.roles['CRRM'], 'CRRM / Super Admin');
      expect(meta.zones.length, 1);
      expect(meta.clusters.length, 1);
      expect(meta.users.length, 1);
      expect(meta.users.first.displayWithRole, 'Arun Kumar · Cluster Executive');
      expect(meta.getSiteName('93130acb-01ba-4883-aef5-baf9e6d7f85e'), 'Space Intel');
      expect(meta.getUserName('13b8bc92-a3e3-426f-8e34-a663e9cc2e4a'), 'Arun Kumar');
    });
  });

  group('IssueModel tests', () {
    test('parses issue list item correctly', () {
      final json = {
        'id': 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
        'siteId': '93130acb-01ba-4883-aef5-baf9e6d7f85e',
        'activityId': '2a0b837a-8f7d-43d1-9b3a-d0f45f68d7a7',
        'department': 'OPERATIONS',
        'title': 'Potted Plants Free From Dust And Healthy',
        'description': 'test',
        'priority': 'MEDIUM',
        'ownerId': '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
        'dueDate': '2026-10-30',
        'status': 'OPEN',
        'resolution': null,
        'closedAt': null,
        'createdById': '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
        'createdAt': '2026-10-30T05:37:07.863Z',
        'updatedAt': '2026-10-30T05:37:07.863Z',
        'origin': null,
        'checklistTitle': null
      };

      final issue = IssueModel.fromJson(json);
      expect(issue.id, 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0');
      expect(issue.title, 'Potted Plants Free From Dust And Healthy');
      expect(issue.formattedStatus, 'Open');
      expect(issue.formattedPriority, 'Medium');
      expect(issue.formattedDueDate, '30 Oct 2026');
      expect(issue.formattedDepartment, 'Operations');
    });

    test('parses issue detail correctly', () {
      final json = {
        'issue': {
          'id': 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
          'siteId': '93130acb-01ba-4883-aef5-baf9e6d7f85e',
          'activityId': '2a0b837a-8f7d-43d1-9b3a-d0f45f68d7a7',
          'department': 'OPERATIONS',
          'title': 'Potted Plants Free From Dust And Healthy',
          'description': 'test',
          'priority': 'MEDIUM',
          'ownerId': '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
          'dueDate': '2026-10-30',
          'status': 'OPEN',
          'resolution': null,
          'closedAt': null,
        },
        'actions': []
      };

      final detail = IssueDetailModel.fromJson(json);
      expect(detail.issue.title, 'Potted Plants Free From Dust And Healthy');
      expect(detail.actions, isEmpty);
    });

    test('parses action points and resolution correctly', () {
      final json = {
        'issue': {
          'id': 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
          'siteId': '93130acb-01ba-4883-aef5-baf9e6d7f85e',
          'department': 'OPERATIONS',
          'title': 'Potted Plants Free From Dust And Healthy',
          'description': 'test',
          'priority': 'MEDIUM',
          'ownerId': '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
          'dueDate': '2026-10-30',
          'status': 'RESOLVED',
          'resolution': 'Done sdhys',
        },
        'actions': [
          {
            'id': '8dbeae4e-3d78-45f7-a5ba-fc06fd8facc8',
            'status': 'OPEN',
            'issueId': 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
            'title': '123451',
            'ownerId': '8e08d892-1fd2-4de9-b7ed-c39f73a8f869',
            'dueDate': '2026-11-02',
            'siteId': '93130acb-01ba-4883-aef5-baf9e6d7f85e'
          }
        ]
      };

      final detail = IssueDetailModel.fromJson(json);
      expect(detail.issue.isResolved, true);
      expect(detail.issue.resolution, 'Done sdhys');
      expect(detail.actions.length, 1);
      final action = detail.actions.first;
      expect(action.title, '123451');
      expect(action.status, 'OPEN');
      expect(action.formattedStatus, 'Open');
      expect(action.formattedDueDate, '2 Nov 2026');
      expect(action.ownerId, '8e08d892-1fd2-4de9-b7ed-c39f73a8f869');
    });
  });

  group('IssuesPage widget rendering test', () {
    testWidgets('renders issues page list correctly on mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final bloc = IssuesBloc(dataSource: _FakeIssuesRemoteDataSource());
      bloc.emit(const IssuesLoaded(
        data: IssuesResponseModel(items: [
          IssueModel(
            id: 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
            siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
            department: 'OPERATIONS',
            title: 'Potted Plants Free From Dust And Healthy',
            description: 'test',
            priority: 'MEDIUM',
            ownerId: '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
            dueDate: '2026-10-30',
            status: 'OPEN',
          ),
        ], total: 1),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssuesPage(bloc: bloc),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(IssuesPage), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Record issue'), findsOneWidget);

      // Tap Record issue to verify dialog opens without RenderBox layout assertion failure
      await tester.tap(find.text('Record issue'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Record A Site Issue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Record A Site Issue'), findsNothing);
    });

    testWidgets('renders action points in trendy card view with toggle', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final bloc = IssuesBloc(dataSource: _FakeIssuesRemoteDataSource());
      bloc.emit(IssuesLoaded(
        data: const IssuesResponseModel(items: [], total: 0),
        selectedIssueDetail: const IssueDetailModel(
          issue: IssueModel(
            id: 'cdb9eeb6-f4b4-4482-9efd-f22f64ce48c0',
            siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
            department: 'OPERATIONS',
            title: 'Potted Plants Free From Dust And Healthy',
            description: 'test',
            priority: 'MEDIUM',
            ownerId: '13b8bc92-a3e3-426f-8e34-a663e9cc2e4a',
            dueDate: '2026-10-30',
            status: 'OPEN',
          ),
          actions: [
            IssueActionModel(
              id: 'act-1',
              title: 'Clean potted plants and report',
              status: 'OPEN',
              owner: 'PropCare Administrator',
              dueDate: '2026-11-03',
            ),
          ],
        ),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssuesPage(bloc: bloc),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Action Points card title and action text
      expect(find.text('1 Action Points'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Clean potted plants and report'), findsOneWidget);
      expect(find.text('3 Nov 2026'), findsOneWidget);

      // Tap Table view toggle
      await tester.tap(find.text('Table'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);

      // Tap Cards view toggle to switch back
      await tester.tap(find.text('Cards'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Clean potted plants and report'), findsOneWidget);
    });
  });
}

