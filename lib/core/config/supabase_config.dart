/// Supabase environment configuration for Nomo.
///
/// Local debug runs intentionally default to the `dev-nomo` Supabase project.
/// Override these values for production/release builds with `--dart-define`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const environment = String.fromEnvironment(
    'NOMO_ENV',
    defaultValue: 'local',
  );

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wwyaftonswgxnjcceyfb.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty',
  );

  static const authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'app.nomo.nomo://login-callback/',
  );

  static Uri get uri => Uri.parse(url);

  static String get expectedAuthIssuer => '${uri.origin}/auth/v1';

  static bool get isLocal => environment == 'local' || environment == 'dev';
}
