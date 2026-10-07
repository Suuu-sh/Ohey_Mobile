import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/widgets/ohey_startup_splash.dart';

void main() {
  testWidgets('shows the preparing hint only after five seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OheyStartupSplash(elapsedAtStart: Duration.zero)),
    );

    expect(find.text('準備中…'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('準備中…'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('準備中…'), findsOneWidget);
  });

  testWidgets('cancels the delayed hint timer when splash is removed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OheyStartupSplash(elapsedAtStart: Duration.zero)),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 5));

    expect(tester.takeException(), isNull);
    expect(find.text('準備中…'), findsNothing);
  });
}
