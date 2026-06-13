class OheyAuthFlowPolicy {
  const OheyAuthFlowPolicy._();

  static bool shouldPreloadStoredSession({
    required bool hasActiveSession,
    required bool isSessionRestoreSuppressed,
  }) {
    return hasActiveSession && !isSessionRestoreSuppressed;
  }

  static bool shouldHandleAuthChange({
    required bool awaitingExplicitExternalAuth,
    required bool isBusy,
    required bool hasActiveSession,
  }) {
    return awaitingExplicitExternalAuth && !isBusy && hasActiveSession;
  }

  static bool shouldUseBackendSignup({
    required bool isLoginFlow,
    required bool hasActiveSession,
  }) {
    return !isLoginFlow || !hasActiveSession;
  }
}
