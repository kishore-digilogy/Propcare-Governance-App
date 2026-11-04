import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/sites/data/datasources/sites_remote_datasource.dart';
import 'package:propcare_governance/features/sites/data/models/site_detail_model.dart';
import 'package:propcare_governance/features/sites/data/models/site_model.dart';
import 'package:propcare_governance/features/sites/data/models/transition_detail_model.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/site_detail_bloc.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/site_detail_event.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/site_detail_state.dart';
import 'package:propcare_governance/features/sites/presentation/pages/site_detail_page.dart';

class MockSiteDetailRemoteDataSource implements SitesRemoteDataSource {
  final SiteDetailResponseModel detailResponse;
  bool specialAttentionCalled = false;
  bool classificationCalled = false;
  bool lifecycleCalled = false;

  MockSiteDetailRemoteDataSource(this.detailResponse);

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
    throw UnimplementedError();
  }

  @override
  Future<SiteDetailResponseModel> getSiteDetail(String siteId) async {
    return detailResponse;
  }

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
  }) async {
    specialAttentionCalled = true;
  }

  @override
  Future<void> updateClassification(
    String siteId, {
    required String clientType,
    required String effectiveDate,
    required String reason,
  }) async {
    classificationCalled = true;
  }

  @override
  Future<void> updateLifecycle(
    String siteId, {
    required String action,
    required String reason,
  }) async {
    lifecycleCalled = true;
  }
}

void main() {
  const sampleDetail = SiteDetailResponseModel(
    site: SiteDetailModel(
      id: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
      name: 'Space Intel',
      code: 'SPACEI_0001',
      clientName: 'Space Intel',
      contactPersonName: 'Kishore',
      contactPhone: '9087654321',
      clientEmail: 'kishore@gmail.com',
      zone: 'Karnataka',
      zoneName: 'Karnataka',
      cluster: 'City & ORR',
      clusterName: 'City & ORR',
      group: 'City & ORR',
      groupName: 'City & ORR',
      service: 'HK',
      serviceName: 'HK',
      billingPm: '740000.00',
      clientType: 'A',
      status: 'LIVE',
      zonalHead: 'Ramana Murthy',
      groupClusterHead: 'Somu',
      clusterHead: 'Rajan',
      clusterLead: 'Azarudeen',
      fieldExecutive: 'Mohan Babu',
      manpowerRequired: 32,
      manpowerDeployed: 0,
      shortage: 32,
      openIssuesCount: 2,
      machineryCount: 8,
      nextActivityDate: '2026-11-06',
      nextActivityTitle: 'Field Executive Visit',
      contractAwardDate: '2026-10-30',
      actualStartDate: '2026-10-30',
    ),
    activities: [
      SiteActivityModel(
        id: '0b3787db-4a8d-4903-876e-8d01b5a9b7fb',
        title: 'Field Executive Visit',
        code: 'ACT-0B378',
        role: 'FIELD_EXECUTIVE',
        spocName: 'Mohan Babu',
        freq: 'Every 7 DAYs',
        dueDate: '2026-11-06',
        status: 'OPEN',
      ),
    ],
  );

  group('SiteDetailModel Tests', () {
    test('formats billing, start dates, and breadcrumbs correctly', () {
      final site = sampleDetail.site;
      expect(site.formattedBillingPm, '₹7.40L');
      expect(site.formattedContractAwardDate, '30 Oct 2026');
      expect(site.formattedActualStartDate, '30 Oct 2026');
      expect(site.formattedNextActivityDay, '6 Nov');
      expect(site.zoneAndClusterBreadcrumb, 'Karnataka Zone  >  City & ORR');
      expect(site.zoneGroupDisplay, 'Karnataka - City & ORR');
    });

    test('formats activity due dates and status correctly', () {
      final act = sampleDetail.activities.first;
      expect(act.formattedDueDate, '6 Nov 2026');
      expect(act.roleLabel, 'Field Executive');
      expect(act.statusDisplay, 'Scheduled');
    });
  });

  group('SiteDetailBloc Tests', () {
    test('loads site detail successfully', () async {
      final mock = MockSiteDetailRemoteDataSource(sampleDetail);
      final bloc = SiteDetailBloc(dataSource: mock);

      bloc.add(const LoadSiteDetail('93130acb-01ba-4883-aef5-baf9e6d7f85e'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const SiteDetailLoading(),
          isA<SiteDetailLoaded>()
              .having((s) => s.detail.site.name, 'name', 'Space Intel')
              .having((s) => s.detail.activities.length, 'activities', 1),
        ]),
      );
    });

    test('submits special attention and updates state', () async {
      final mock = MockSiteDetailRemoteDataSource(sampleDetail);
      final bloc = SiteDetailBloc(dataSource: mock);
      bloc.emit(const SiteDetailLoaded(detail: sampleDetail));

      bloc.add(const SubmitSpecialAttention(
        siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
        enabled: true,
        fromDate: '2026-11-02',
        toDate: '2026-11-09',
        reason: 'Client escalation',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SiteDetailLoaded>().having((s) => s.isSubmitting, 'submitting', true),
          isA<SiteDetailLoaded>()
              .having((s) => s.isSubmitting, 'submitting', false)
              .having((s) => s.successMessage, 'msg', contains('Special attention')),
        ]),
      );
      expect(mock.specialAttentionCalled, isTrue);
    });

    test('submits client classification and updates state', () async {
      final mock = MockSiteDetailRemoteDataSource(sampleDetail);
      final bloc = SiteDetailBloc(dataSource: mock);
      bloc.emit(const SiteDetailLoaded(detail: sampleDetail));

      bloc.add(const SubmitClassification(
        siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
        clientType: 'B',
        effectiveDate: '2026-11-02',
        reason: 'Billing adjustment',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SiteDetailLoaded>().having((s) => s.isSubmitting, 'submitting', true),
          isA<SiteDetailLoaded>()
              .having((s) => s.isSubmitting, 'submitting', false)
              .having((s) => s.successMessage, 'msg', contains('Client type updated to B')),
        ]),
      );
      expect(mock.classificationCalled, isTrue);
    });

    test('submits lifecycle action and updates state', () async {
      final mock = MockSiteDetailRemoteDataSource(sampleDetail);
      final bloc = SiteDetailBloc(dataSource: mock);
      bloc.emit(const SiteDetailLoaded(detail: sampleDetail));

      bloc.add(const SubmitLifecycle(
        siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
        action: 'inactive',
        reason: 'Contract terminated',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SiteDetailLoaded>().having((s) => s.isSubmitting, 'submitting', true),
          isA<SiteDetailLoaded>()
              .having((s) => s.isSubmitting, 'submitting', false)
              .having((s) => s.successMessage, 'msg', contains('marked as inactive')),
        ]),
      );
      expect(mock.lifecycleCalled, isTrue);
    });
  });

  group('SiteDetailPage Widget Tests', () {
    testWidgets('renders all site detail sections, stat cards, and triggers dialogs', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mock = MockSiteDetailRemoteDataSource(sampleDetail);
      final bloc = SiteDetailBloc(dataSource: mock);
      bloc.emit(const SiteDetailLoaded(detail: sampleDetail));

      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailPage(
            siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
            bloc: bloc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header title and code
      expect(find.text('Space Intel'), findsWidgets);
      expect(find.text('SPACEI_0001'), findsWidgets);

      // Status chip & client type
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Billing PM ₹7.40L'), findsOneWidget);

      // 3 Action Buttons
      expect(find.text('Mark special attention'), findsOneWidget);
      expect(find.text('Client type'), findsOneWidget);
      expect(find.text('Mark inactive'), findsOneWidget);

      // 4 Stat Cards
      expect(find.text('Manpower'), findsOneWidget);
      expect(find.text('0/32'), findsOneWidget);
      expect(find.text('Open issues'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Machinery'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Next Activity'), findsOneWidget);
      expect(find.text('6 Nov'), findsOneWidget);

      // Governance Activities Table
      expect(find.text('Governance Activities'), findsOneWidget);
      expect(find.text('Field Executive Visit'), findsWidgets);
      expect(find.text('Mohan Babu'), findsWidgets);
      expect(find.text('Every 7 DAYs'), findsOneWidget);

      // Site Master Card
      expect(find.text('Site Master'), findsOneWidget);
      expect(find.text('Kishore'), findsOneWidget);
      expect(find.text('9087654321'), findsOneWidget);
      expect(find.text('kishore@gmail.com'), findsOneWidget);
      expect(find.text('Ramana Murthy'), findsOneWidget);
      expect(find.text('Azarudeen'), findsWidgets);

      // Test Dialog: Open Client Type Dialog
      await tester.tap(find.text('Client type'));
      await tester.pumpAndSettle();

      expect(find.text('Current: A (Billing PM ₹7.40L)'), findsOneWidget);
      expect(find.text('Update client type'), findsOneWidget);

      // Close Dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Test Dialog: Open Special Attention Dialog
      await tester.tap(find.text('Mark special attention'));
      await tester.pumpAndSettle();

      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);

      // Close Dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Test Dialog: Open Mark Inactive Dialog
      await tester.tap(find.text('Mark inactive'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Inactive'), findsOneWidget);
    });

    testWidgets('Tapping on a governance activity card navigates to ActivityExecutionPage', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mock = MockSiteDetailRemoteDataSource(sampleDetail);
      final bloc = SiteDetailBloc(dataSource: mock);
      bloc.emit(const SiteDetailLoaded(detail: sampleDetail));

      await tester.pumpWidget(
        MaterialApp(
          home: SiteDetailPage(
            siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
            bloc: bloc,
            activityExecutionPageBuilder: (ctx, actId) => Scaffold(
              body: Text('Activity Execution Page: $actId'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll until the governance activity card is visible
      await tester.scrollUntilVisible(
        find.text('ACT-0B378'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find the governance activity card
      expect(find.text('ACT-0B378'), findsOneWidget);

      // Tap on the activity card
      await tester.tap(find.text('ACT-0B378'));
      await tester.pumpAndSettle();

      // Verify navigation to ActivityExecutionPage
      expect(find.text('Activity Execution Page: 0b3787db-4a8d-4903-876e-8d01b5a9b7fb'), findsOneWidget);
    });
  });
}
