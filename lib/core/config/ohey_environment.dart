/// Shared environment constants for Ohey Mobile.
///
/// Keep public, non-secret environment identifiers here so backend, Clerk redirect,
/// and scripts do not drift. Private values still belong in
/// `/Users/yota/Projects/Secrets/Ohey` and CI/Render secrets.
class OheyEnvironmentValues {
  const OheyEnvironmentValues._();

  static const environmentDefineKey = 'OHEY_ENV';
  static const backendUrlDefineKey = 'OHEY_BACKEND_URL';
  static const authRedirectUrlDefineKey = 'OHEY_AUTH_REDIRECT_URL';
  static const authProviderDefineKey = 'AUTH_PROVIDER';
  static const clerkPublishableKeyDefineKey = 'CLERK_PUBLISHABLE_KEY';

  static const devEnvironment = 'dev';
  static const productionEnvironment = 'production';

  static const environment = String.fromEnvironment(
    environmentDefineKey,
    defaultValue: productionEnvironment,
  );

  static const devBackendUrl = 'https://dev-ohey-backend.onrender.com';
  static const productionBackendUrl = 'https://api.oheyapp.com';

  static const devAuthRedirectUrl = 'app.ohey.com.dev://login-callback/';
  static const productionAuthRedirectUrl = 'app.ohey.com://login-callback/';
}
