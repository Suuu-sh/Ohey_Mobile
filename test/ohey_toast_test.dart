import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/widgets/ohey_toast.dart';

void main() {
  test('toast defaults to bottom placement', () {
    expect(OheyToast.defaultPlacement, OheyToastPlacement.bottom);
  });

  test(
    'toast stays below the device top chrome even without safe-area padding',
    () {
      expect(OheyToast.topOffsetFor(0), 88);
      expect(OheyToast.topOffsetFor(20), 88);
      expect(OheyToast.topOffsetFor(70), 88);
      expect(OheyToast.topOffsetFor(80), 98);
    },
  );

  test('bottom toast stays above the tab bar area', () {
    expect(OheyToast.bottomOffsetFor(0), 82);
    expect(OheyToast.bottomOffsetFor(34), 82);
  });

  test('toast accent color follows semantic icons', () {
    expect(
      OheyToast.accentColorForIcon(CupertinoIcons.bell_fill),
      OheyToast.defaultAccentColor,
    );
    expect(
      OheyToast.accentColorForIcon(CupertinoIcons.checkmark_circle_fill),
      OheyToast.successAccentColor,
    );
    expect(
      OheyToast.accentColorForIcon(
        CupertinoIcons.exclamationmark_triangle_fill,
      ),
      OheyToast.dangerAccentColor,
    );
  });

  test('toast accent color can follow page accent', () {
    const pageAccentColor = Color(0xFFC08BFF);
    const overrideAccentColor = Color(0xFFFF75B5);

    expect(
      OheyToast.accentColorForIcon(
        CupertinoIcons.bell_fill,
        pageAccentColor: pageAccentColor,
      ),
      pageAccentColor,
    );
    expect(
      OheyToast.accentColorForIcon(
        CupertinoIcons.checkmark_circle_fill,
        pageAccentColor: pageAccentColor,
      ),
      pageAccentColor,
    );
    expect(
      OheyToast.accentColorForIcon(
        CupertinoIcons.exclamationmark_triangle_fill,
        pageAccentColor: pageAccentColor,
      ),
      OheyToast.dangerAccentColor,
    );
    expect(
      OheyToast.accentColorForIcon(
        CupertinoIcons.exclamationmark_triangle_fill,
        pageAccentColor: pageAccentColor,
        overrideAccentColor: overrideAccentColor,
      ),
      overrideAccentColor,
    );
  });

  testWidgets('toast page accent is available from descendants', (
    tester,
  ) async {
    const pageAccentColor = Color(0xFF9AF21A);
    Color? resolvedAccentColor;

    await tester.pumpWidget(
      OheyToastAccent(
        color: pageAccentColor,
        child: Builder(
          builder: (context) {
            resolvedAccentColor = OheyToastAccent.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolvedAccentColor, pageAccentColor);
  });
}
