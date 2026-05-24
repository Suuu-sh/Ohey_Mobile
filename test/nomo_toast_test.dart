import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomo/core/widgets/nomo_toast.dart';

void main() {
  test('toast defaults to bottom placement', () {
    expect(NomoToast.defaultPlacement, NomoToastPlacement.bottom);
  });

  test(
    'toast stays below the device top chrome even without safe-area padding',
    () {
      expect(NomoToast.topOffsetFor(0), 88);
      expect(NomoToast.topOffsetFor(20), 88);
      expect(NomoToast.topOffsetFor(70), 88);
      expect(NomoToast.topOffsetFor(80), 98);
    },
  );

  test('bottom toast stays above the tab bar area', () {
    expect(NomoToast.bottomOffsetFor(0), 72);
    expect(NomoToast.bottomOffsetFor(34), 106);
  });

  test('toast accent color follows semantic icons', () {
    expect(
      NomoToast.accentColorForIcon(CupertinoIcons.bell_fill),
      NomoToast.defaultAccentColor,
    );
    expect(
      NomoToast.accentColorForIcon(CupertinoIcons.checkmark_circle_fill),
      NomoToast.successAccentColor,
    );
    expect(
      NomoToast.accentColorForIcon(
        CupertinoIcons.exclamationmark_triangle_fill,
      ),
      NomoToast.dangerAccentColor,
    );
  });

  test('toast accent color can follow page accent', () {
    const pageAccentColor = Color(0xFFC08BFF);
    const overrideAccentColor = Color(0xFFFF75B5);

    expect(
      NomoToast.accentColorForIcon(
        CupertinoIcons.bell_fill,
        pageAccentColor: pageAccentColor,
      ),
      pageAccentColor,
    );
    expect(
      NomoToast.accentColorForIcon(
        CupertinoIcons.checkmark_circle_fill,
        pageAccentColor: pageAccentColor,
      ),
      pageAccentColor,
    );
    expect(
      NomoToast.accentColorForIcon(
        CupertinoIcons.exclamationmark_triangle_fill,
        pageAccentColor: pageAccentColor,
      ),
      NomoToast.dangerAccentColor,
    );
    expect(
      NomoToast.accentColorForIcon(
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
      NomoToastAccent(
        color: pageAccentColor,
        child: Builder(
          builder: (context) {
            resolvedAccentColor = NomoToastAccent.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolvedAccentColor, pageAccentColor);
  });
}
