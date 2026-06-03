import 'package:flutter/foundation.dart';

import 'ohey_environment.dart';

/// Supabase environment configuration for Ohey.
///
/// Non-release builds (Simulator / `flutter run`) are forced to dev-ohey so
/// local checks never touch production accidentally. Release builds
/// (TestFlight/App Store) default to production even if dart-defines are
/// missing, and may still override values explicitly via `--dart-define`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const environment = String.fromEnvironment(
    OheyEnvironmentValues.environmentDefineKey,
    defaultValue: kReleaseMode
        ? OheyEnvironmentValues.productionEnvironment
        : OheyEnvironmentValues.devEnvironment,
  );

  static const _definedUrl = String.fromEnvironment(
    OheyEnvironmentValues.supabaseUrlDefineKey,
  );

  static const _definedPublishableKey = String.fromEnvironment(
    OheyEnvironmentValues.supabasePublishableKeyDefineKey,
  );

  static const _definedAuthRedirectUrl = String.fromEnvironment(
    OheyEnvironmentValues.supabaseAuthRedirectUrlDefineKey,
  );

  /// Canonical Supabase URL used by the app.
  ///
  /// Local `flutter run` / Simulator checks are non-release builds, and must
  /// always stay on dev-ohey even if a production dart-define file is passed by
  /// mistake. TestFlight/App Store builds are release builds, so they default
  /// to production and can be overridden by production dart-defines.
  ///
  /// A previous production build path could supply a transposed project ref
  /// (`...qhygy...`) through dart-defines. That hostname does not exist and
  /// causes `SocketException: Failed host lookup`. Normalize that exact known
  /// typo for release builds so affected invocations still connect to the
  /// intended `ohey` Supabase project.
  static String get url {
    if (!kReleaseMode) {
      return OheyEnvironmentValues.devSupabaseUrl;
    }

    final normalized =
        (_definedUrl.isEmpty
                ? OheyEnvironmentValues.productionSupabaseUrl
                : _definedUrl)
            .trim()
            .replaceFirst(RegExp(r'/+$'), '');
    if (normalized == OheyEnvironmentValues.mistypedProductionSupabaseUrl) {
      return OheyEnvironmentValues.productionSupabaseUrl;
    }
    return normalized;
  }

  static String get publishableKey {
    if (!kReleaseMode) {
      return OheyEnvironmentValues.devSupabasePublishableKey;
    }
    return _definedPublishableKey.isEmpty
        ? OheyEnvironmentValues.productionSupabasePublishableKey
        : _definedPublishableKey;
  }

  static String get authRedirectUrl {
    if (!kReleaseMode) {
      return OheyEnvironmentValues.devAuthRedirectUrl;
    }
    return _definedAuthRedirectUrl.isEmpty
        ? OheyEnvironmentValues.productionAuthRedirectUrl
        : _definedAuthRedirectUrl;
  }

  static Uri get uri => Uri.parse(url);

  static String get expectedAuthIssuer => '${uri.origin}/auth/v1';

  static bool get isLocal =>
      !kReleaseMode || environment == 'local' || environment == 'dev';
}
