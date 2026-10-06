import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/widgets/ohey_bottom_sheet.dart';

void main() {
  testWidgets('close button renders and invokes its callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: OheyCloseButton(onTap: () => tapped = true)),
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.bySemanticsLabel('閉じる'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    expect(tapped, isTrue);
  });

  testWidgets('disabled close button does not invoke its callback', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OheyCloseButton(enabled: false, onTap: () => tapped = true),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    expect(tapped, isFalse);
  });
}
