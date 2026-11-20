import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/governance_matrix/data/datasources/governance_matrix_remote_datasource.dart';
import 'package:propcare_governance/features/governance_matrix/data/models/governance_matrix_model.dart';
import 'package:propcare_governance/features/governance_matrix/presentation/bloc/governance_matrix_bloc.dart';
import 'package:propcare_governance/features/governance_matrix/presentation/pages/governance_matrix_page.dart';

class _FakeGovernanceMatrixRemoteDataSource
    implements GovernanceMatrixRemoteDataSource {
  final GovernanceMatrixResponseModel response;

  _FakeGovernanceMatrixRemoteDataSource(this.response);

  @override
  Future<GovernanceMatrixResponseModel> getGovernanceMatrix() async {
    return response;
  }
}

void main() {
  final sampleJson = {
    'items': [
      {
        'id': 'item-1',
        'tabKey': 'operations',
        'tabName': 'Operations',
        'clientType': 'A+',
        'billingPm': 'Above ₹10L',
        'frequencies': {
          'fieldExecutive': 'Weekly',
          'clusterExecutive': 'Weekly',
          'clusterLead': 'Every 15 Days',
          'clusterHead': 'Monthly',
        },
        'columnsConfig': [
          {'key': 'fieldExecutive', 'label': 'Field Executive'},
          {'key': 'clusterExecutive', 'label': 'Cluster Executive'},
          {'key': 'clusterLead', 'label': 'Cluster Lead'},
          {'key': 'clusterHead', 'label': 'Cluster Head'},
        ],
        'sortOrder': 1,
        'active': true,
      },
      {
        'id': 'item-2',
        'tabKey': 'operations',
        'tabName': 'Operations',
        'clientType': 'A',
        'billingPm': '₹5L - ₹10L',
        'frequencies': {
          'fieldExecutive': 'Weekly',
          'clusterExecutive': 'Every 15 Days',
          'clusterLead': 'Monthly',
          'clusterHead': 'Bi-Monthly',
        },
        'columnsConfig': [],
        'sortOrder': 2,
        'active': true,
      },
      {
        'id': 'item-3',
        'tabKey': 'ld_training',
        'tabName': 'Transition Training',
        'clientType': 'A+',
        'billingPm': 'Above ₹10L',
        'frequencies': {'frequency': 'Monthly Once / Twice'},
        'columnsConfig': [
          {'key': 'frequency', 'label': 'Frequency'}
        ],
        'sortOrder': 1,
        'active': true,
      },
      {
        'id': 'item-4',
        'tabKey': 'ehs_audit',
        'tabName': 'EHS Audit',
        'clientType': 'A+',
        'billingPm': 'Above ₹10L',
        'frequencies': {'frequency': 'Quarterly'},
        'columnsConfig': [
          {'key': 'frequency', 'label': 'Frequency'}
        ],
        'sortOrder': 1,
        'active': true,
      },
      {
        'id': 'item-5',
        'tabKey': 'hr_compliance',
        'tabName': 'HR & Compliance',
        'clientType': 'A+',
        'billingPm': 'Above ₹10L',
        'frequencies': {'frequency': 'Bi-Monthly'},
        'columnsConfig': [
          {'key': 'frequency', 'label': 'Frequency'}
        ],
        'sortOrder': 1,
        'active': true,
      },
    ]
  };

  late GovernanceMatrixResponseModel responseModel;

  setUp(() {
    responseModel = GovernanceMatrixResponseModel.fromJson(sampleJson);
  });

  testWidgets(
      'renders light header with 3D illustration, golden Matrix, tabs, frequency section, and adaptive tablet grid',
      (tester) async {
    // 1. Mobile screen test (width: 400, height: 850)
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final bloc = GovernanceMatrixBloc(
      dataSource: _FakeGovernanceMatrixRemoteDataSource(responseModel),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GovernanceMatrixPage(bloc: bloc),
      ),
    );

    // Initial pump & settle loaded state
    await tester.pumpAndSettle();

    // Verify Header Elements
    expect(find.text('Back'), findsOneWidget);
    expect(find.textContaining('Governance', findRichText: true), findsWidgets);
    expect(find.textContaining('Matrix', findRichText: true), findsWidgets);
    expect(
      find.text(
        'Client type × function × role × activity → frequency. Business users change this; developers never hard-code a frequency.',
      ),
      findsOneWidget,
    );

    // Verify Tabs
    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('L & D'), findsOneWidget);
    expect(find.text('EHS Audit'), findsOneWidget);
    expect(find.text('HR & Compliance'), findsOneWidget);

    // Verify Section Header
    expect(find.text('Operations frequency'), findsOneWidget);
    expect(
      find.text('Final frequency sheet is the authority'),
      findsOneWidget,
    );

    // Verify View Mode Buttons
    expect(find.byTooltip('Card view'), findsOneWidget);
    expect(find.byTooltip('Table view'), findsOneWidget);

    // Verify cards rendered
    expect(find.text('Client Tier A+'), findsOneWidget);
    expect(find.text('Client Tier A'), findsOneWidget);
    expect(find.text('Above ₹10L'), findsOneWidget);
    expect(find.text('₹5L - ₹10L'), findsOneWidget);

    // 2. Test switching to "L & D" tab
    await tester.tap(find.text('L & D'));
    await tester.pumpAndSettle();

    expect(find.text('L & D frequency'), findsOneWidget);
    expect(find.text('Monthly Once / Twice'), findsOneWidget);

    // 3. Test View Switcher toggle to Table view
    await tester.tap(find.byTooltip('Table view'));
    await tester.pumpAndSettle();

    expect(find.text('Client type'), findsOneWidget);
    expect(find.text('Billing PM'), findsOneWidget);

    // Switch back to Operations tab and Card view
    await tester.tap(find.text('Operations'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Card view'));
    await tester.pumpAndSettle();

    expect(find.text('Operations frequency'), findsOneWidget);

    // 4. Tablet / iPad layout test (width: 820, height: 1180)
    tester.view.physicalSize = const Size(820, 1180);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Both cards should still be present in the 2-column masonry grid on tablet
    expect(find.text('Client Tier A+'), findsOneWidget);
    expect(find.text('Client Tier A'), findsOneWidget);
  });
}
