import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/widgets/tomo_toast.dart';

void main() {
  test('toast defaults to bottom placement', () {
    expect(TomoToast.defaultPlacement, TomoToastPlacement.bottom);
  });

  test(
    'toast stays below the device top chrome even without safe-area padding',
    () {
      expect(TomoToast.topOffsetFor(0), 88);
      expect(TomoToast.topOffsetFor(20), 88);
      expect(TomoToast.topOffsetFor(70), 88);
      expect(TomoToast.topOffsetFor(80), 98);
    },
  );

  test('bottom toast stays above the tab bar area', () {
    expect(TomoToast.bottomOffsetFor(0), 72);
    expect(TomoToast.bottomOffsetFor(34), 106);
  });

  test('toast accent color follows semantic icons', () {
    expect(
      TomoToast.accentColorForIcon(CupertinoIcons.bell_fill),
      TomoToast.defaultAccentColor,
    );
    expect(
      TomoToast.accentColorForIcon(CupertinoIcons.checkmark_circle_fill),
      TomoToast.successAccentColor,
    );
    expect(
      TomoToast.accentColorForIcon(
        CupertinoIcons.exclamationmark_triangle_fill,
      ),
      TomoToast.dangerAccentColor,
    );
  });

  test('toast accent color can follow page accent', () {
    const pageAccentColor = Color(0xFFC08BFF);
    const overrideAccentColor = Color(0xFFFF75B5);

    expect(
      TomoToast.accentColorForIcon(
        CupertinoIcons.bell_fill,
        pageAccentColor: pageAccentColor,
      ),
      pageAccentColor,
    );
    expect(
      TomoToast.accentColorForIcon(
        CupertinoIcons.checkmark_circle_fill,
        pageAccentColor: pageAccentColor,
      ),
      pageAccentColor,
    );
    expect(
      TomoToast.accentColorForIcon(
        CupertinoIcons.exclamationmark_triangle_fill,
        pageAccentColor: pageAccentColor,
      ),
      TomoToast.dangerAccentColor,
    );
    expect(
      TomoToast.accentColorForIcon(
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
      TomoToastAccent(
        color: pageAccentColor,
        child: Builder(
          builder: (context) {
            resolvedAccentColor = TomoToastAccent.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolvedAccentColor, pageAccentColor);
  });
}
