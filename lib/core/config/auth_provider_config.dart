import 'package:flutter/foundation.dart';

import 'ohey_environment.dart';

class AuthProviderConfig {
  const AuthProviderConfig._();

  static const clerkPublishableKey = String.fromEnvironment(
    OheyEnvironmentValues.clerkPublishableKeyDefineKey,
  );

  static const authRedirectUrl = String.fromEnvironment(
    OheyEnvironmentValues.authRedirectUrlDefineKey,
  );

  static const googleWebClientId = String.fromEnvironment(
    OheyEnvironmentValues.googleWebClientIdDefineKey,
  );

  static const googleIosClientId = String.fromEnvironment(
    OheyEnvironmentValues.googleIosClientIdDefineKey,
  );

  static const appleOAuthEnabled = bool.fromEnvironment(
    'OHEY_ENABLE_APPLE_OAUTH',
    defaultValue: true,
  );

  static bool get isClerkEnabled => clerkPublishableKey.trim().isNotEmpty;

  static String get redirectUrl {
    if (authRedirectUrl.trim().isNotEmpty) return authRedirectUrl;
    if (!kReleaseMode) return OheyEnvironmentValues.devAuthRedirectUrl;
    return OheyEnvironmentValues.environment ==
            OheyEnvironmentValues.devEnvironment
        ? OheyEnvironmentValues.devAuthRedirectUrl
        : OheyEnvironmentValues.productionAuthRedirectUrl;
  }

  static bool isAllowedOAuthCallback(Uri uri) {
    final expected = Uri.parse(redirectUrl);
    return uri.scheme.toLowerCase() == expected.scheme.toLowerCase() &&
        uri.host.toLowerCase() == expected.host.toLowerCase() &&
        _normalizedPath(uri.path) == _normalizedPath(expected.path);
  }
}

String _normalizedPath(String path) {
  if (path.isEmpty) return '/';
  return path;
}
