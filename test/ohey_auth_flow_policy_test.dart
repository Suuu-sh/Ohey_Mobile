import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/features/onboarding/application/ohey_auth_flow_policy.dart';

void main() {
  group('OheyAuthFlowPolicy', () {
    test('does not preload a stored session after logout suppression', () {
      expect(
        OheyAuthFlowPolicy.shouldPreloadStoredSession(
          hasActiveSession: true,
          isSessionRestoreSuppressed: true,
        ),
        isFalse,
      );
    });

    test(
      'preloads only when an active session exists and restore is allowed',
      () {
        expect(
          OheyAuthFlowPolicy.shouldPreloadStoredSession(
            hasActiveSession: true,
            isSessionRestoreSuppressed: false,
          ),
          isTrue,
        );
        expect(
          OheyAuthFlowPolicy.shouldPreloadStoredSession(
            hasActiveSession: false,
            isSessionRestoreSuppressed: false,
          ),
          isFalse,
        );
      },
    );

    test('ignores ambient auth changes unless explicit OAuth is waiting', () {
      expect(
        OheyAuthFlowPolicy.shouldHandleAuthChange(
          awaitingExplicitExternalAuth: false,
          isBusy: false,
          hasActiveSession: true,
        ),
        isFalse,
      );
      expect(
        OheyAuthFlowPolicy.shouldHandleAuthChange(
          awaitingExplicitExternalAuth: true,
          isBusy: true,
          hasActiveSession: true,
        ),
        isFalse,
      );
      expect(
        OheyAuthFlowPolicy.shouldHandleAuthChange(
          awaitingExplicitExternalAuth: true,
          isBusy: false,
          hasActiveSession: true,
        ),
        isTrue,
      );
    });

    test(
      'signup profile always uses backend signup even with a stale session',
      () {
        expect(
          OheyAuthFlowPolicy.shouldUseBackendSignup(
            isLoginFlow: false,
            hasActiveSession: true,
          ),
          isTrue,
        );
        expect(
          OheyAuthFlowPolicy.shouldUseBackendSignup(
            isLoginFlow: true,
            hasActiveSession: true,
          ),
          isFalse,
        );
      },
    );
  });
}
