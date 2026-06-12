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
    return OheyEnvironmentValues.environment ==
            OheyEnvironmentValues.devEnvironment
        ? OheyEnvironmentValues.devAuthRedirectUrl
        : OheyEnvironmentValues.productionAuthRedirectUrl;
  }
}
