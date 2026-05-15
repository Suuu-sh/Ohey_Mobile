/// Supabase environment configuration for Nomo.
///
/// Values must be supplied for real app runs with `--dart-define`.
/// Placeholder defaults are intentionally non-secret and only keep widget tests
/// bootable when the app does not talk to the network.
class SupabaseConfig {
  const SupabaseConfig._();

  static const environment = String.fromEnvironment(
    'NOMO_ENV',
    defaultValue: 'local',
  );

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'test_publishable_key',
  );

  static const authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'app.nomo.nomo://login-callback/',
  );

  static Uri get uri => Uri.parse(url);

  static String get expectedAuthIssuer => '${uri.origin}/auth/v1';

  static bool get isLocal => environment == 'local' || environment == 'dev';
}
