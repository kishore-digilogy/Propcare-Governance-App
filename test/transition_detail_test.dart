import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/sites/data/datasources/sites_remote_datasource.dart';
import 'package:propcare_governance/features/sites/data/models/site_detail_model.dart';
import 'package:propcare_governance/features/sites/data/models/site_model.dart';
import 'package:propcare_governance/features/sites/data/models/transition_detail_model.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/transition_detail_bloc.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/transition_detail_event.dart';
import 'package:propcare_governance/features/sites/presentation/bloc/transition_detail_state.dart';
import 'package:propcare_governance/features/sites/presentation/pages/transition_site_detail_page.dart';

class MockTransitionDetailRemoteDataSource implements SitesRemoteDataSource {
  final TransitionSiteDetailResponseModel detailResponse;

  MockTransitionDetailRemoteDataSource(this.detailResponse);

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
    throw UnimplementedError();
  }

  @override
  Future<TransitionSiteDetailResponseModel> getTransitionDetail(String siteId) async {
    return detailResponse;
  }

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
  const sampleJson = {
    "site": {
      "id": "93130acb-01ba-4883-aef5-baf9e6d7f85e",
      "name": "Space Intel",
      "code": "SPACEI_0001",
      "clientName": "Space Intel",
      "clientEmail": "kishore@gmail.com",
      "contactPersonName": "Kishore",
      "contactPhone": "9087654321",
      "city": "NA",
      "state": "NA",
      "zoneName": "Karnataka",
      "clusterName": "City & ORR",
      "serviceName": "HK",
      "billingPm": "740000.00",
      "clientType": "A",
      "contractAwardDate": "2026-10-30",
      "contractStartDate": "2026-10-31",
      "contractEndDate": "2026-11-30",
      "status": "LIVE",
      "mode": "NEW",
      "manpowerRequired": 32,
      "manpowerDeployed": 0,
      "shortage": 32,
      "ldStatus": "OPEN",
      "ldTransitionComplete": false,
      "ldVerifiedAt": null
    },
    "ldPreview": {
      "kickoff": {
        "withClient": "YES",
        "date": "2026-10-30",
        "participants": ["CRRM", "Ops", "Client"],
        "meeting": "COMPLETED",
        "contractAwardDate": "2026-10-30",
        "contractStartDate": "2026-10-31",
        "contractEndDate": "2026-11-30"
      },
      "review": {
        "status": "OPEN",
        "submittedAt": null,
        "verifiedAt": null,
        "note": ""
      },
      "internal": [
        {
          "phase": "INTERNAL",
          "key": "closing_of_agreement",
          "title": "Closing of Agreement",
          "sortOrder": 0,
          "canRaiseTicket": false,
          "id": "INTERNAL:closing_of_agreement",
          "status": "",
          "done": false,
          "remark": "",
          "startDate": "2026-11-16",
          "endDate": "2026-11-30",
          "targetDate": "2026-11-30"
        }
      ],
      "ldTransition": [
        {
          "phase": "LD_TRANSITION",
          "key": "ld_kickoff",
          "title": "L&D transition kick-off completed",
          "sortOrder": 0,
          "canRaiseTicket": false,
          "id": "LD_TRANSITION:ld_kickoff",
          "status": "",
          "done": false,
          "remark": "",
          "startDate": null,
          "endDate": null
        },
        {
          "phase": "LD_TRANSITION",
          "key": "ld_training_plan",
          "title": "Site training plan shared with operations",
          "sortOrder": 1,
          "canRaiseTicket": false,
          "id": "LD_TRANSITION:ld_training_plan",
          "status": "",
          "done": false,
          "remark": "",
          "startDate": null,
          "endDate": null
        },
        {
          "phase": "LD_TRANSITION",
          "key": "ld_stability_ready",
          "title": "Site ready for L&D stability check",
          "sortOrder": 2,
          "canRaiseTicket": false,
          "id": "LD_TRANSITION:ld_stability_ready",
          "status": "",
          "done": false,
          "remark": "",
          "startDate": null,
          "endDate": null
        }
      ]
    },
    "transitions": []
  };

  group('TransitionSiteDetailResponseModel parsing tests', () {
    test('parses site info, dates, and preview correctly', () {
      final model = TransitionSiteDetailResponseModel.fromJson(sampleJson);
      expect(model.site.name, 'Space Intel');
      expect(model.site.code, 'SPACEI_0001');
      expect(model.site.formattedAwardDate, '30 Oct 2026');
      expect(model.site.formattedStartDate, '31 Oct 2026');
      expect(model.site.formattedEndDate, '30 Nov 2026');

      expect(model.ldPreview.kickoff.isWithClientYes, isTrue);
      expect(model.ldPreview.kickoff.isPreTransitionMeetingYes, isTrue);

      expect(model.ldPreview.internal.length, 1);
      expect(model.ldPreview.internal.first.title, 'Closing of Agreement');
      expect(model.ldPreview.internal.first.formattedStartDate, '16 Nov 2026');
      expect(model.ldPreview.internal.first.formattedTargetDate, '30 Nov 2026');
      expect(model.ldPreview.internal.first.displayStatus, 'Pending');

      expect(model.ldPreview.ldTransition.length, 3);
      expect(model.ldPreview.ldTransition.first.title, 'L&D transition kick-off completed');
    });
  });

  group('TransitionDetailBloc tests', () {
    test('loads transition detail successfully and sets default step to 2', () async {
      final model = TransitionSiteDetailResponseModel.fromJson(sampleJson);
      final ds = MockTransitionDetailRemoteDataSource(model);
      final bloc = TransitionDetailBloc(dataSource: ds);

      expect(bloc.state, isA<TransitionDetailInitial>());

      bloc.add(const LoadTransitionDetail(siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TransitionDetailLoading>(),
          isA<TransitionDetailLoaded>().having(
            (s) => s.selectedStep,
            'selectedStep',
            2,
          ),
        ]),
      );

      bloc.add(const SelectTransitionStep(3));
      await expectLater(
        bloc.stream,
        emits(
          isA<TransitionDetailLoaded>().having((s) => s.selectedStep, 'selectedStep', 3),
        ),
      );
    });
  });

  group('TransitionSiteDetailPage UI widget tests', () {
    testWidgets('renders top nav, header card with dates, 4-step stepper, and step 2 cards',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final model = TransitionSiteDetailResponseModel.fromJson(sampleJson);
      final ds = MockTransitionDetailRemoteDataSource(model);
      final bloc = TransitionDetailBloc(dataSource: ds);

      await tester.pumpWidget(
        MaterialApp(
          home: TransitionSiteDetailPage(
            siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e',
            bloc: bloc,
          ),
        ),
      );

      bloc.add(const LoadTransitionDetail(siteId: '93130acb-01ba-4883-aef5-baf9e6d7f85e'));
      await tester.pumpAndSettle();

      // Top back nav
      expect(find.text('Back to Sites List'), findsOneWidget);

      // Header site info
      expect(find.text('Space Intel'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('SPACEI_0001'), findsOneWidget);

      // Contract date boxes
      expect(find.text('Contract Award Date'), findsOneWidget);
      expect(find.text('30 Oct 2026'), findsWidgets);
      expect(find.text('Contract Start Date'), findsOneWidget);
      expect(find.text('31 Oct 2026'), findsOneWidget);
      expect(find.text('Contract End Date'), findsOneWidget);
      expect(find.text('30 Nov 2026'), findsWidgets);

      // 4 steps in stepper
      expect(find.text('Site Creation'), findsOneWidget);
      expect(find.text('Internal Checklist'), findsWidgets);
      expect(find.text('L&D Checklist'), findsOneWidget);
      expect(find.text('Stability Verify'), findsOneWidget);

      // Step 2 contents: Client Kick-Off and Internal Checklist
      expect(find.text('Client Kick-Off'), findsOneWidget);
      expect(find.text('Sales + Ops + CRRM'), findsOneWidget);
      expect(find.text('Kick-Off With Client'), findsOneWidget);
      expect(find.text('Pre-Transition Meeting'), findsOneWidget);

      // Internal checklist item card view
      expect(find.text('Closing of Agreement'), findsOneWidget);
      expect(find.text('Start: '), findsWidgets);
      expect(find.text('Target: '), findsWidgets);
      expect(find.text('16 Nov 2026'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Continue To L&D Checklist →'), findsOneWidget);

      // Scroll and Tap 'Continue To L&D Checklist →'
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue To L&D Checklist →'));
      await tester.pumpAndSettle();

      // Now Step 3 contents should be visible
      expect(find.text('L&D Transition Checklist'), findsOneWidget);
      expect(find.text('L&D transition kick-off completed'), findsOneWidget);
      expect(find.text('Continue To Stability Verify →'), findsOneWidget);

      // Scroll and Tap 'Continue To Stability Verify →'
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue To Stability Verify →'));
      await tester.pumpAndSettle();

      // Now Step 4 contents should be visible
      expect(
        find.text('Stability Verify is done by L&D Head in the L&D Transition module.'),
        findsOneWidget,
      );
    });
  });
}
