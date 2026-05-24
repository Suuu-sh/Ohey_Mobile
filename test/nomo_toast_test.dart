import 'package:flutter_test/flutter_test.dart';
import 'package:nomo/core/widgets/nomo_toast.dart';

void main() {
  test(
    'toast stays below the device top chrome even without safe-area padding',
    () {
      expect(NomoToast.topOffsetFor(0), 88);
      expect(NomoToast.topOffsetFor(20), 88);
      expect(NomoToast.topOffsetFor(70), 88);
      expect(NomoToast.topOffsetFor(80), 98);
    },
  );
}
