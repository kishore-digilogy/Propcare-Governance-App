import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/widgets/custom_dropdown_button2.dart';

void main() {
  testWidgets('CustomDropdownButton2 renders and selects items with fixed height', (tester) async {
    String? selectedValue = 'cluster_1';
    final options = List.generate(
      30,
      (i) => DropdownItemOption(value: 'cluster_$i', label: 'Cluster $i'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (ctx, setState) {
              return CustomDropdownButton2<String?>(
                label: 'Cluster',
                selectedValue: selectedValue,
                options: options,
                enableSearch: true,
                maxHeight: 260,
                onSelect: (val) {
                  setState(() => selectedValue = val);
                },
              );
            },
          ),
        ),
      ),
    );

    // Initial label check
    expect(find.text('Cluster'), findsOneWidget);
    expect(find.text('Cluster 1'), findsOneWidget);

    // Tap to open dropdown
    await tester.tap(find.text('Cluster 1'));
    await tester.pumpAndSettle();

    // Verify search input is displayed (from enableSearch: true)
    expect(find.text('Search name or role...'), findsOneWidget);

    // Tap another option visible in the fixed 260px menu viewport
    await tester.tap(find.text('Cluster 2').last);
    await tester.pumpAndSettle();

    // Verify value was updated
    expect(selectedValue, 'cluster_2');
  });
}
