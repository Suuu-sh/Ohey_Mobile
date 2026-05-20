/// Supabase environment configuration for Nomo.
///
/// Development-safe defaults are embedded so local `flutter run` never touches
/// production accidentally. TestFlight/production builds must pass explicit
/// production values via `--dart-define`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const environment = String.fromEnvironment(
    'NOMO_ENV',
    defaultValue: 'dev',
  );

  static const _definedUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _devSupabaseUrl,
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty',
  );

  static const authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'app.nomo.nomo://login-callback/',
  );

  static const _devSupabaseUrl = 'https://wwyaftonswgxnjcceyfb.supabase.co';
  static const _prodSupabaseUrl = 'https://pwifgddolctqghygwxwj.supabase.co';
  static const _mistypedProdSupabaseUrl =
      'https://pwifgddolctqhygywxwj.supabase.co';

  /// Canonical Supabase URL used by the app.
  ///
  /// A previous production build path could supply a transposed project ref
  /// (`...qhygy...`) through dart-defines. That hostname does not exist and
  /// causes `SocketException: Failed host lookup` on both Simulator and
  /// TestFlight. Normalize that exact known typo so affected build/run
  /// invocations still connect to the intended `nomo` Supabase project.
  static String get url {
    final normalized = _definedUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized == _mistypedProdSupabaseUrl) {
      return _prodSupabaseUrl;
    }
    return normalized;
  }

  static Uri get uri => Uri.parse(url);

  static String get expectedAuthIssuer => '${uri.origin}/auth/v1';

  static bool get isLocal => environment == 'local' || environment == 'dev';
}
