import 'package:flutter/foundation.dart';

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

  static const _definedPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _devPublishableKey,
  );

  static const authRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'app.nomo.nomo://login-callback/',
  );

  static const _devSupabaseUrl = 'https://wwyaftonswgxnjcceyfb.supabase.co';
  static const _devPublishableKey =
      'sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty';
  static const _prodSupabaseUrl = 'https://pwifgddolctqghygwxwj.supabase.co';
  static const _mistypedProdSupabaseUrl =
      'https://pwifgddolctqhygywxwj.supabase.co';

  /// Canonical Supabase URL used by the app.
  ///
  /// Local `flutter run` / Simulator checks are non-release builds, and must
  /// always stay on dev-nomo even if a production dart-define file is passed by
  /// mistake. TestFlight/App Store builds are release builds, so they continue
  /// to use the explicitly supplied production values.
  ///
  /// A previous production build path could supply a transposed project ref
  /// (`...qhygy...`) through dart-defines. That hostname does not exist and
  /// causes `SocketException: Failed host lookup`. Normalize that exact known
  /// typo for release builds so affected invocations still connect to the
  /// intended `nomo` Supabase project.
  static String get url {
    if (!kReleaseMode) {
      return _devSupabaseUrl;
    }

    final normalized = _definedUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized == _mistypedProdSupabaseUrl) {
      return _prodSupabaseUrl;
    }
    return normalized;
  }

  static String get publishableKey {
    if (!kReleaseMode) {
      return _devPublishableKey;
    }
    return _definedPublishableKey;
  }

  static Uri get uri => Uri.parse(url);

  static String get expectedAuthIssuer => '${uri.origin}/auth/v1';

  static bool get isLocal =>
      !kReleaseMode || environment == 'local' || environment == 'dev';
}
