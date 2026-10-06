import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/theme/app_colors.dart';
import 'package:ohey/core/widgets/ohey_header_bar.dart';

void main() {
  testWidgets('header divider matches the home bar in both themes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final (isWhite, expectedColor) in [
      (true, AppColors.chunkyBorderLight),
      (false, AppColors.chunkyBorderDark),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OheyHeaderDivider(isWhite: isWhite)),
        ),
      );

      expect(
        tester.getSize(find.byType(OheyHeaderDivider)),
        const Size(390, 2),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(OheyHeaderDivider),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        expectedColor,
      );
    }
  });
}
