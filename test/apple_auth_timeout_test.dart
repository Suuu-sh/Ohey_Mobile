import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/data/apple_auth_service.dart';
import 'package:ohey/core/data/clerk_auth_service.dart';

void main() {
  test(
    'Apple availability probe fails closed when platform call stalls',
    () async {
      final availability = Completer<bool>();
      final service = AppleAuthService(
        availabilityChecker: () => availability.future,
        platformSupportChecker: () => true,
        availabilityTimeout: const Duration(milliseconds: 10),
      );

      expect(await service.isSupportedAndAvailable(), isFalse);
    },
  );

  test('Clerk ID-token request timeout returns an auth error', () async {
    final request = Completer<void>();

    await expectLater(
      withClerkRequestTimeout<void>(
        request.future,
        timeout: const Duration(milliseconds: 10),
      ),
      throwsA(
        isA<clerk.ClerkError>().having(
          (error) => error.message,
          'message',
          'Authentication request timed out',
        ),
      ),
    );
  });
}
