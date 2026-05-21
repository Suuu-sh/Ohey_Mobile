import 'package:flutter/foundation.dart';

/// Supabase environment configuration for Nomo.
///
/// Non-release builds (Simulator / `flutter run`) are forced to dev-nomo so
/// local checks never touch production accidentally. Release builds
/// (TestFlight/App Store) default to production even if dart-defines are
/// missing, and may still override values explicitly via `--dart-define`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const environment = String.fromEnvironment(
    'NOMO_ENV',
    defaultValue: kReleaseMode ? 'production' : 'dev',
  );

  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');

  static const _definedPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const _definedAuthRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
  );

  static const _devSupabaseUrl = 'https://wwyaftonswgxnjcceyfb.supabase.co';
  static const _devPublishableKey =
      'sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty';
  static const _prodSupabaseUrl = 'https://pwifgddolctqghygwxwj.supabase.co';
  static const _prodPublishableKey =
      'sb_publishable_pezjPt7pYRECNFdydlon8A_RpSjNulk';
  static const _prodAuthRedirectUrl = 'app.nomo.nomo://login-callback/';
  static const _devAuthRedirectUrl = 'app.nomo.nomo.dev://login-callback/';
  static const _mistypedProdSupabaseUrl =
      'https://pwifgddolctqhygywxwj.supabase.co';

  /// Canonical Supabase URL used by the app.
  ///
  /// Local `flutter run` / Simulator checks are non-release builds, and must
  /// always stay on dev-nomo even if a production dart-define file is passed by
  /// mistake. TestFlight/App Store builds are release builds, so they default
  /// to production and can be overridden by production dart-defines.
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

    final normalized = (_definedUrl.isEmpty ? _prodSupabaseUrl : _definedUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    if (normalized == _mistypedProdSupabaseUrl) {
      return _prodSupabaseUrl;
    }
    return normalized;
  }

  static String get publishableKey {
    if (!kReleaseMode) {
      return _devPublishableKey;
    }
    return _definedPublishableKey.isEmpty
        ? _prodPublishableKey
        : _definedPublishableKey;
  }

  static String get authRedirectUrl {
    if (!kReleaseMode) {
      return _devAuthRedirectUrl;
    }
    return _definedAuthRedirectUrl.isEmpty
        ? _prodAuthRedirectUrl
        : _definedAuthRedirectUrl;
  }

  static Uri get uri => Uri.parse(url);

  static String get expectedAuthIssuer => '${uri.origin}/auth/v1';

  static bool get isLocal =>
      !kReleaseMode || environment == 'local' || environment == 'dev';
}
