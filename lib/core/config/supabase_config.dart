/// Supabase environment configuration for Nomo.
///
/// Production-safe defaults are embedded so Xcode/TestFlight builds work even
/// when `--dart-define` is not passed. Override with `--dart-define` for dev.
class SupabaseConfig {
  const SupabaseConfig._();

  static const environment = String.fromEnvironment(
    'NOMO_ENV',
    defaultValue: 'production',
  );

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pwifgddolctqghygwxwj.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_pezjPt7pYRECNFdydlon8A_RpSjNulk',
  );

  static const authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'app.nomo.nomo://login-callback/',
  );

  static Uri get uri => Uri.parse(url);

  static String get expectedAuthIssuer => '${uri.origin}/auth/v1';

  static bool get isLocal => environment == 'local' || environment == 'dev';
}
