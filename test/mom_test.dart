import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:propcare_governance/features/mom/data/datasources/mom_remote_datasource.dart';
import 'package:propcare_governance/features/mom/data/models/mom_activity_model.dart';
import 'package:propcare_governance/features/mom/data/models/mom_by_site_model.dart';
import 'package:propcare_governance/features/mom/presentation/bloc/mom_bloc.dart';
import 'package:propcare_governance/features/mom/presentation/bloc/mom_event.dart';
import 'package:propcare_governance/features/mom/presentation/bloc/mom_state.dart';
import 'package:propcare_governance/features/mom/presentation/pages/mom_page.dart';
import 'package:propcare_governance/features/mom/presentation/widgets/mom_activity_form_view.dart';

class MockMomRemoteDataSource implements MomRemoteDataSource {
  final List<MomActivityModel> dummyActivities;

  MockMomRemoteDataSource({List<MomActivityModel>? activities})
      : dummyActivities = activities ??
            [
              MomActivityModel(
                id: 'act-1',
                siteId: 'site-apple',
                siteName: 'Apple',
                siteCode: 'apple1126001',
                zoneName: 'Tamil Nadu',
                clusterName: 'OMR',
                role: 'EHS',
                roleLabel: 'EHS',
                kind: 'GOVERNANCE',
                title: 'EHS Audit Visit',
                code: 'ACT-4C28C',
                scheduledDate: '2027-02-24',
                dueDate: '2027-02-24',
                status: 'COMPLETED',
                statusLabel: 'Sent',
                frequencyLabel: 'Quarterly',
                priority: 'High',
                clientType: 'A+',
                mom: MomDetailInfoModel(
                  to: ['kishorekumar@digilogy.co'],
                  cc: [],
                  subject: 'Site walkaround MOM - Apple - 25 Nov 2026',
                  sentAt: '2026-11-25T10:49:00.000Z',
                  points: const [
                    MomPointModel(
                      id: 'pt-1',
                      point: 'Ceiling Lights Free From Dust & Cobwebs',
                      status: 'DONE',
                      department: 'EHS',
                      targetDate: '2026-11-28',
                    ),
                  ],
                ),
              ),
              MomActivityModel(
                id: 'act-2',
                siteId: 'site-apple',
                siteName: 'Apple',
                siteCode: 'apple1126001',
                zoneName: 'Tamil Nadu',
                clusterName: 'OMR',
                role: 'CRRM',
                roleLabel: 'CRRM',
                kind: 'GOVERNANCE',
                title: 'CRRM Review',
                code: 'ACT-BE8E3',
                scheduledDate: '2028-02-24',
                dueDate: '2028-02-24',
                status: 'OPEN',
                statusLabel: 'Assigned',
                frequencyLabel: 'Quarterly',
                priority: 'High',
                clientType: 'A+',
                mom: const MomDetailInfoModel(),
              ),
            ];

  @override
  Future<MomBySiteModel> getMomBySite() async {
    return MomBySiteModel(
      items: [
        MomSiteItemModel(
          siteId: 'site-apple',
          siteName: 'Apple',
          siteCode: 'apple1126001',
          siteCity: 'NA',
          siteClientType: 'A+',
          zoneName: 'Tamil Nadu',
          clusterName: 'OMR',
          siteStatus: 'LIVE',
          pending: 1,
          completed: 1,
          total: 2,
        ),
      ],
      pending: 1,
      completed: 1,
    );
  }

  @override
  Future<List<MomActivityModel>> getGovernanceActivities() async {
    return dummyActivities;
  }

  @override
  Future<List<MomActivityModel>> getSiteMomActivities({required String siteId}) async {
    return dummyActivities.where((a) => a.siteId == siteId).toList();
  }

  @override
  Future<bool> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  }) async {
    return true;
  }

  @override
  Future<MomActivityModel> updateMomPointStatus({
    required String activityId,
    required String pointId,
    required String status,
  }) async {
    final act = dummyActivities.firstWhere((a) => a.id == activityId);
    final updatedPoints = act.mom.points.map((p) {
      if (p.id == pointId) {
        return p.copyWith(status: status);
      }
      return p;
    }).toList();
    return act.copyWith(mom: act.mom.copyWith(points: updatedPoints));
  }
}

void main() {
  group('MomActivityModel & MomPointModel Tests', () {
    test('JSON parsing correctly populates status, dates, and points', () {
      final json = {
        'id': 'act-123',
        'siteId': 'site-apple',
        'siteName': 'Apple',
        'role': 'EHS',
        'title': 'EHS Audit Visit',
        'code': 'ACT-001',
        'scheduledDate': '2027-02-24',
        'dueDate': '2027-02-24',
        'status': 'COMPLETED',
        'statusLabel': 'Sent',
        'zoneName': 'Tamil Nadu',
        'clusterName': 'OMR',
        'frequencyLabel': 'Quarterly',
        'mom': {
          'to': ['kishore@digilogy.co'],
          'subject': 'Site walkaround MOM - Apple',
          'sentAt': '2026-11-25T10:49:00.000Z',
          'points': [
            {
              'id': 'pt-1',
              'point': 'Inspection observation',
              'status': 'DONE',
              'department': 'EHS',
              'targetDate': '2026-11-28',
            }
          ]
        }
      };

      final model = MomActivityModel.fromJson(json);
      expect(model.id, 'act-123');
      expect(model.isSent, isTrue);
      expect(model.isPending, isFalse);
      expect(model.totalPoints, 1);
      expect(model.completedPoints, 1);
      expect(model.pendingPoints, 0);
      expect(model.mom.points.first.isDone, isTrue);
      expect(model.formattedSentAt, contains('25 Nov 2026'));
    });
  });

  group('MomBloc Tests', () {
    test('loads activities and manages tab selection properly', () async {
      final mock = MockMomRemoteDataSource();
      final bloc = MomBloc(dataSource: mock);

      bloc.add(const LoadMomBySite());
      await pumpEventQueue();

      expect(bloc.state, isA<MomLoaded>());
      final loaded = bloc.state as MomLoaded;
      expect(loaded.allCount, 2);
      expect(loaded.completedCount, 1);
      expect(loaded.pendingCount, 1);

      // Change tab to Pending
      bloc.add(const ChangeMomTab(1));
      await pumpEventQueue();
      final pendingState = bloc.state as MomLoaded;
      expect(pendingState.selectedTabIndex, 1);
      expect(pendingState.filteredActivities.length, 1);
      expect(pendingState.filteredActivities.first.role, 'CRRM');

      // Change tab to Completed
      bloc.add(const ChangeMomTab(2));
      await pumpEventQueue();
      final completedState = bloc.state as MomLoaded;
      expect(completedState.selectedTabIndex, 2);
      expect(completedState.filteredActivities.length, 1);
      expect(completedState.filteredActivities.first.role, 'EHS');

      bloc.close();
    });

    test('selects activity directly and updates action point status', () async {
      final mock = MockMomRemoteDataSource();
      final bloc = MomBloc(dataSource: mock);

      bloc.add(const LoadMomBySite());
      await pumpEventQueue();

      final act = (bloc.state as MomLoaded).allActivities.first;
      bloc.add(SelectMomActivityDirectly(act));
      await pumpEventQueue();

      final detailState = bloc.state as MomLoaded;
      expect(detailState.selectedSite, isNotNull);
      expect(detailState.selectedActivity?.id, 'act-1');

      // Update action point status to OPEN
      bloc.add(const UpdateMomPointStatusAction(
        activityId: 'act-1',
        pointId: 'pt-1',
        status: 'OPEN',
      ));
      await pumpEventQueue();

      final updatedState = bloc.state as MomLoaded;
      expect(updatedState.selectedActivity?.mom.points.first.isDone, isFalse);

      bloc.close();
    });

    test('when getGovernanceActivities returns empty, site activities are fetched and populated', () async {
      final mock = MockMomRemoteDataSource(activities: []);
      final bloc = MomBloc(dataSource: mock);

      bloc.add(const LoadMomBySite());
      await pumpEventQueue();

      expect(bloc.state, isA<MomLoaded>());
      final loaded = bloc.state as MomLoaded;
      expect(loaded.allCount, 2);
      expect(loaded.allActivities.isNotEmpty, isTrue);

      bloc.close();
    });
  });

  group('MomPage Widget Tests', () {
    testWidgets('renders MOM & Email page with 3 metric cards and activities table',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mock = MockMomRemoteDataSource();
      final bloc = MomBloc(dataSource: mock)..add(const LoadMomBySite());

      await tester.pumpWidget(
        MaterialApp(
          home: MomPage(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('MOM & Email'), findsWidgets);
      expect(find.text('Send MOM Mail For Completed Governance Visits.'), findsOneWidget);

      // Verify 3 Metric Cards: All, Pending, Completed
      expect(find.text('All'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);

      // Verify Activities table items
      expect(find.text('EHS Audit Visit'), findsWidgets);
      expect(find.text('CRRM Review'), findsWidgets);
      expect(find.text('Apple'), findsWidgets);

      // Tap on an activity to open Detail View
      await tester.tap(find.text('EHS Audit Visit').first);
      await tester.pumpAndSettle();

      // Breadcrumb and Detail header
      expect(find.text('All sites'), findsOneWidget);
      expect(find.text('Pick A Visit To Send Or Review MOM.'), findsOneWidget);

      // Verify Visit selector and Summary strip
      expect(find.textContaining('Select Visit'), findsOneWidget);
      expect(find.text('Governance'), findsWidgets);
      expect(find.text('Visit date'), findsWidgets);

      // Verify Style Switcher: Dropdown, Badges, Cards
      expect(find.text('Dropdown'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);

      // Switch style to Badges
      await tester.tap(find.text('Badges'));
      await tester.pumpAndSettle();

      // Switch style to Cards
      await tester.tap(find.text('Cards'));
      await tester.pumpAndSettle();

      // Switch back to Dropdown
      await tester.tap(find.text('Dropdown'));
      await tester.pumpAndSettle();

      // Status pill & Role dropdown
      expect(find.textContaining('SENT ON'), findsOneWidget);

      // Sub-tabs: MOM and Action Points
      expect(find.text('MOM'), findsWidgets);
      expect(find.textContaining('Action Points'), findsWidgets);

      // Switch to Action Points sub-tab
      await tester.tap(find.textContaining('Action Points').first);
      await tester.pumpAndSettle();

      // Action point observation text and status toggles
      expect(find.text('Ceiling Lights Free From Dust & Cobwebs'), findsOneWidget);

      // Tap Back to return to sites list
      await tester.tap(find.text('All sites'));
      await tester.pumpAndSettle();

      expect(find.text('Send MOM Mail For Completed Governance Visits.'), findsOneWidget);

      bloc.close();
    });
  });
}
