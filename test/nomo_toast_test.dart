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
    expect(NomoToast.bottomOffsetFor(0), 104);
    expect(NomoToast.bottomOffsetFor(34), 138);
  });
}
