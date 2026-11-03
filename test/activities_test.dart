import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/models/meta_model.dart';
import 'package:propcare_governance/core/services/meta_service.dart';
import 'package:propcare_governance/features/activities/data/datasources/activities_remote_datasource.dart';
import 'package:propcare_governance/features/activities/data/models/activity_detail_model.dart';
import 'package:propcare_governance/features/activities/data/models/activity_site_summary_model.dart';
import 'package:propcare_governance/features/activities/data/models/site_activity_item_model.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/activities_bloc.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/activities_event.dart';
import 'package:propcare_governance/features/activities/presentation/bloc/activities_state.dart';
import 'package:propcare_governance/features/activities/presentation/pages/activities_page.dart';

const sampleActivityDetail = ActivityDetailModel(
  activity: ActivityItemDetailModel(
    id: 'act_1',
    siteId: 'site_123',
    role: 'CRRM',
    kind: 'GOVERNANCE',
    title: 'CRRM Visit',
    status: 'OPEN',
    statusLabel: 'Scheduled',
    clientType: 'A+',
    code: 'ACT-09006',
    functionLabel: 'CRRM',
    roleLabel: 'CRRM / Super Admin',
    frequencyLabel: 'Quarterly',
    priority: 'High',
    scheduledDate: '2027-01-30',
    dueDate: '2027-01-30',
  ),
  site: ActivitySiteDetailModel(
    id: 'site_123',
    name: 'Digilogy',
    code: 'DIGILO_0001',
    clientName: 'Digilogy',
    clientEmail: 'prem@gmail.com',
    contactPersonName: 'Prem',
    city: 'NA',
    state: 'NA',
    zoneId: 'z_1',
    status: 'LIVE',
    contactEmails: [
      EmailRecipientModel(
        value: 'prem@gmail.com',
        label: 'Prem · prem@gmail.com',
        name: 'Prem',
        role: 'CLIENT',
      ),
    ],
    ccEmails: [
      EmailRecipientModel(
        value: 'manibharathi@casagrandepropcare.com',
        label: 'Mani Bharathi · Cluster Executive · manibharathi@casagrandepropcare.com',
        name: 'Mani Bharathi',
        role: 'CLUSTER_EXECUTIVE',
      ),
    ],
  ),
);

class MockActivitiesRemoteDataSource implements ActivitiesRemoteDataSource {
  final ActivitiesBySiteResponseModel bySiteResponse;
  final SiteActivitiesResponseModel siteActivitiesResponse;

  MockActivitiesRemoteDataSource({
    required this.bySiteResponse,
    required this.siteActivitiesResponse,
  });

  @override
  Future<ActivitiesBySiteResponseModel> getActivitiesBySite({
    required String view,
    String? zoneId,
    String? clusterId,
    String? status,
    String? role,
  }) async {
    return bySiteResponse;
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
    return siteActivitiesResponse;
  }

  @override
  Future<ActivityDetailModel> getActivityDetail(String activityId) async {
    return sampleActivityDetail;
  }

  @override
  Future<ActivityItemDetailModel> completeActivity({
    required String activityId,
    required String visitDate,
    required bool clientMet,
    String? note,
  }) async {
    return sampleActivityDetail.activity.copyWith(
      status: 'COMPLETED',
      statusLabel: 'MOM Pending',
      visitDate: visitDate,
      clientMet: clientMet,
      completionNote: note,
    );
  }

  @override
  Future<ActivityItemDetailModel> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  }) async {
    final curMom = Map<String, dynamic>.from(payload);
    curMom['sentAt'] = DateTime.now().toIso8601String();
    return sampleActivityDetail.activity.copyWith(
      status: 'COMPLETED',
      statusLabel: 'Completed',
      mom: curMom,
    );
  }
}

class DelayActivitiesRemoteDataSource implements ActivitiesRemoteDataSource {
  final ActivitiesBySiteResponseModel bySiteResponse;
  final SiteActivitiesResponseModel siteActivitiesResponse;
  final Future<ActivitiesBySiteResponseModel> Function() onGetActivities;

  DelayActivitiesRemoteDataSource({
    required this.bySiteResponse,
    required this.siteActivitiesResponse,
    required this.onGetActivities,
  });

  @override
  Future<ActivitiesBySiteResponseModel> getActivitiesBySite({
    required String view,
    String? zoneId,
    String? clusterId,
    String? status,
    String? role,
  }) async {
    return onGetActivities();
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
    return siteActivitiesResponse;
  }

  @override
  Future<ActivityDetailModel> getActivityDetail(String activityId) async {
    return sampleActivityDetail;
  }

  @override
  Future<ActivityItemDetailModel> completeActivity({
    required String activityId,
    required String visitDate,
    required bool clientMet,
    String? note,
  }) async {
    return sampleActivityDetail.activity.copyWith(
      status: 'COMPLETED',
      statusLabel: 'MOM Pending',
      visitDate: visitDate,
      clientMet: clientMet,
      completionNote: note,
    );
  }

  @override
  Future<ActivityItemDetailModel> sendMomEmail({
    required String activityId,
    required Map<String, dynamic> payload,
  }) async {
    final curMom = Map<String, dynamic>.from(payload);
    curMom['sentAt'] = DateTime.now().toIso8601String();
    return sampleActivityDetail.activity.copyWith(
      status: 'COMPLETED',
      statusLabel: 'Completed',
      mom: curMom,
    );
  }
}

void main() {
  const sampleSite = ActivitySiteItemModel(
    siteId: 'site_123',
    siteName: 'BPT',
    siteCode: 'BPT_0001',
    siteCity: 'NA',
    siteClientType: 'A',
    zoneId: 'z_1',
    zoneName: 'Hospitality Zone',
    clusterId: 'c_1',
    clusterName: 'Pan India',
    siteStatus: 'LIVE',
    pending: 1,
    completed: 0,
    total: 1,
  );

  const sampleBySiteResponse = ActivitiesBySiteResponseModel(
    items: [sampleSite],
    pending: 6,
    completed: 0,
    total: 6,
    view: 'mine',
    myRoleLabel: 'CRRM / Super Admin',
    belowRoles: [
      RoleOptionModel(role: 'COO', label: 'COO'),
      RoleOptionModel(role: 'ZONAL_HEAD', label: 'Zonal Head'),
    ],
  );

  const sampleActivity = SiteActivityItemModel(
    id: 'act_1',
    siteId: 'site_123',
    role: 'CRRM',
    kind: 'GOVERNANCE',
    title: 'CRRM Visit',
    status: 'SCHEDULED',
    clientType: 'A',
    code: 'BPT_0001',
    siteName: 'BPT',
    siteCity: 'NA',
    clusterName: 'Pan India',
    functionLabel: 'CRRM',
    roleLabel: 'CRRM',
    frequencyLabel: 'Quarterly',
    priority: 'Medium',
    statusLabel: 'Scheduled',
    scheduledDate: '2027-02-02',
  );

  const sampleSiteActivitiesResponse = SiteActivitiesResponseModel(
    items: [sampleActivity],
    total: 1,
    limit: 10,
    offset: 0,
    counts: SiteActivityCountsModel(
      today: 0,
      upcoming: 1,
      pending: 1,
      overdue: 0,
      all: 1,
      scheduled: 1,
      assigned: 0,
      completed: 0,
      summaryOverdue: 0,
    ),
    view: 'mine',
    myRole: 'CRRM',
    myRoleLabel: 'CRRM / Super Admin',
  );

  setUp(() {
    MetaService.instance.setMockMeta(const MetaDataModel(
      users: [],
      sites: [MetaSiteModel(id: 'site_1', name: 'BPT')],
      units: [],
    ));
  });

  group('Activities Models', () {
    test('ActivitySiteItemModel completionPercent calculation', () {
      expect(sampleSite.completionPercent, 0);

      const partialSite = ActivitySiteItemModel(
        siteId: 'site_2',
        siteName: 'Space Intel',
        siteCode: 'SPACEI_0001',
        siteCity: 'NA',
        siteClientType: 'A',
        zoneName: 'Karnataka',
        clusterName: 'City & ORR',
        siteStatus: 'LIVE',
        pending: 12,
        completed: 1,
        total: 13,
      );
      // 1 / 13 * 100 = 7.69% -> 8%
      expect(partialSite.completionPercent, 8);
    });

    test('SiteActivityItemModel formattedDate', () {
      expect(sampleActivity.formattedDate, '2 Feb 2027');
    });
  });

  group('ActivitiesBloc', () {
    test('loads activities by site successfully', () async {
      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.add(const LoadActivitiesBySite(view: 'mine'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const ActivitiesLoading(),
          isA<ActivitiesLoaded>().having((s) => s.response.items.length, 'items.length', 1),
        ]),
      );
      bloc.close();
    });

    test('selects site and fetches site activities', () async {
      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'mine',
      ));

      bloc.add(const SelectSiteForActivities(sampleSite));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ActivitiesLoaded>()
              .having((s) => s.selectedSite?.siteId, 'siteId', 'site_123')
              .having((s) => s.isLoadingDetail, 'isLoadingDetail', true),
          isA<ActivitiesLoaded>()
              .having((s) => s.selectedSiteActivities?.items.length, 'items.length', 1)
              .having((s) => s.isLoadingDetail, 'isLoadingDetail', false),
        ]),
      );
      bloc.close();
    });
  });

  group('ActivitiesPage Widget Tests', () {
    testWidgets('Renders My Activities page with top cards and site list', (tester) async {
      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'mine',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesPage(
            isTeam: false,
            bloc: bloc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Activities'), findsOneWidget);
      expect(find.text('Total Governance Activity'), findsWidgets);
      expect(find.text('Completed Governance Activity'), findsWidgets);
      expect(find.text('Pending Governance Activity'), findsWidgets);
      expect(find.text('BPT'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Renders Team Activities page with role chips', (tester) async {
      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'below',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesPage(
            isTeam: true,
            bloc: bloc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Team Activities'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('COO'), findsOneWidget);
      expect(find.text('Zonal Head'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Tapping site opens detail view and tapping All sites returns', (tester) async {
      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'mine',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesPage(
            isTeam: false,
            bloc: bloc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on site BPT card
      await tester.tap(find.text('BPT'));
      await tester.pumpAndSettle();

      // In detail view, should see 'All sites' and 4 count cards
      expect(find.text('All sites'), findsOneWidget);
      expect(find.text('Scheduled'), findsWidgets);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Overdue'), findsOneWidget);

      // Tap All sites to return
      await tester.tap(find.text('All sites'));
      await tester.pumpAndSettle();

      // Main view again
      expect(find.text('My Activities'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Tapping role chip shows loader until new values arrive', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<ActivitiesBySiteResponseModel>();

      final mockSource = DelayActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
        onGetActivities: () => completer.future,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'below',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesPage(
            isTeam: true,
            bloc: bloc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // State is initially loaded with BPT site
      expect(find.text('BPT'), findsOneWidget);

      // Now tap on 'COO' role chip with in-flight response
      await tester.tap(find.text('COO'));
      await tester.pump();

      // While request is in-flight, loader is visible!
      expect(find.text('Loading activities...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Now complete the response
      completer.complete(sampleBySiteResponse);
      await tester.pumpAndSettle();

      // Loader is gone and site cards are visible
      expect(find.text('Loading activities...'), findsNothing);
      expect(find.text('BPT'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Renders compact mobile view without overflow and toggles between Card and Table in detail view', (tester) async {
      // Simulate mobile phone screen dimensions (375x667)
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'mine',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesPage(
            isTeam: false,
            bloc: bloc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mobile compact metric bar displays Total, Completed, Pending
      expect(find.text('Total'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('BPT'), findsOneWidget);

      // Tap on site BPT to navigate into detail view
      await tester.tap(find.text('BPT'));
      await tester.pumpAndSettle();

      // In detail view, should see 4 compact cards in 2x2 grid
      expect(find.text('Scheduled'), findsWidgets);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Overdue'), findsOneWidget);

      // Card View is active by default and displays rich activity card
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('CRRM Visit'), findsOneWidget);
      expect(find.text('2 Feb 2027'), findsOneWidget);
      expect(find.text('BPT_0001'), findsOneWidget);

      // Switch to Table View
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();

      // DataTable is rendered
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Site'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);

      // Switch back to Card View
      await tester.tap(find.text('Cards'));
      await tester.pumpAndSettle();

      expect(find.text('CRRM Visit'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Tapping on activity opens ActivityExecutionView, submits visit with green completed stepper and disabled fields, and opens MOM step', (tester) async {
      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'mine',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesPage(
            isTeam: false,
            bloc: bloc,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on site BPT card to go to Site Activities view
      await tester.tap(find.text('BPT'));
      await tester.pumpAndSettle();

      // In Site Activities view, tap on the activity card
      expect(find.text('CRRM Visit'), findsOneWidget);
      await tester.tap(find.text('CRRM Visit'));
      await tester.pumpAndSettle();

      // ActivityExecutionView should now be visible
      expect(find.text('Activities > ACT-09006'), findsOneWidget);
      expect(find.text('Visit details'), findsWidgets);
      expect(find.text('MOM'), findsWidgets);
      expect(find.text('Activity master'), findsOneWidget);
      expect(find.text('Execution flow'), findsOneWidget);

      // Submit visit
      expect(find.text('Submit visit'), findsWidgets);
      await tester.tap(find.text('Submit visit').first);
      await tester.pumpAndSettle();

      // After visit is completed, auto-advances to Step 2: MOM & Email
      expect(find.text('2. MOM & Email'), findsOneWidget);
      expect(find.text('Send MOM'), findsWidgets);
      expect(find.text('prem@gmail.com'), findsWidgets);
      expect(find.text('MAJOR POINTS'), findsOneWidget);

      // Tap on Step 1 in stepper to verify disabled fields & visit completed status
      await tester.tap(find.text('Visit details').first);
      await tester.pumpAndSettle();

      expect(find.text('Visit completed'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsWidgets);

      // Return to Step 2 MOM and send MOM
      await tester.tap(find.text('MOM').first);
      await tester.pumpAndSettle();

      expect(find.text('Send MOM'), findsWidgets);
      await tester.tap(find.text('Send MOM').first);
      await tester.pumpAndSettle();

      // Should show MOM saved green pill and Sent badge
      expect(find.text('MOM saved'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);

      // Tap Back to return to site activities
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('All sites'), findsOneWidget);

      bloc.close();
    });

    testWidgets('ActivityExecutionView renders without any horizontal overflow on narrow mobile screens (360px)', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockSource = MockActivitiesRemoteDataSource(
        bySiteResponse: sampleBySiteResponse,
        siteActivitiesResponse: sampleSiteActivitiesResponse,
      );

      final bloc = ActivitiesBloc(remoteDataSource: mockSource);
      bloc.emit(const ActivitiesLoaded(
        response: sampleBySiteResponse,
        view: 'mine',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesPage(
            isTeam: false,
            bloc: bloc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open site BPT
      await tester.tap(find.text('BPT'));
      await tester.pumpAndSettle();

      // Open activity execution view
      FlutterErrorDetails? caughtDetails;
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      await tester.tap(find.text('CRRM Visit'));
      await tester.pumpAndSettle();

      FlutterError.onError = oldOnError;

      expect(find.text('Activities > ACT-09006'), findsOneWidget);
      expect(find.text('Save draft'), findsOneWidget);
      expect(find.text('Submit visit'), findsWidgets);
      expect(caughtDetails, isNull);

      // Tapping step 2 without submitting visit details blocks navigation
      await tester.tap(find.text('MOM'));
      await tester.pumpAndSettle();
      expect(find.text('Please submit visit details first before proceeding to MOM.'), findsOneWidget);

      bloc.close();
    });
  });
}

