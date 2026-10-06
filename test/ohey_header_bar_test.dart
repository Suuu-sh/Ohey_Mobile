import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/theme/app_colors.dart';
import 'package:ohey/core/widgets/ohey_header_bar.dart';

void main() {
  testWidgets('header bar keeps its theme background and has no border', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final (isWhite, expectedColor) in [
      (true, AppColors.white),
      (false, AppColors.darkBackground),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 86,
              child: OheyHeaderBar(isWhite: isWhite),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(OheyHeaderBar)), const Size(390, 86));
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(OheyHeaderBar),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, expectedColor);
      expect(decoration.border, isNull);
    }
  });
}
