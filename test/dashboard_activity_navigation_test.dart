import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/features/activities/presentation/pages/activity_execution_page.dart';
import 'package:propcare_governance/features/dashboard/data/models/dashboard_model.dart';
import 'package:propcare_governance/features/dashboard/presentation/pages/dashboard_page.dart';

void main() {
  testWidgets('GovActivityRow renders activity and navigates to ActivityExecutionPage on tap', (tester) async {
    const item = GovernanceListItemModel(
      id: 'ACT-09006',
      title: 'CRRM Visit',
      siteName: 'Digilogy',
      roleLabel: 'CRRM / Super Admin',
      dueDate: '2027-01-30',
      assigneeName: 'PropCare Administrator',
      state: 'Upcoming',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GovActivityRow(item: item),
          ),
        ),
      ),
    );

    expect(find.text('CRRM Visit'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ActivityExecutionPage), findsOneWidget);
  });
}
