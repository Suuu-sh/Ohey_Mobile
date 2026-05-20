import 'package:flutter/foundation.dart';

/// Go backend environment configuration for Nomo.
///
/// The default points to the dev backend so local builds without dart defines
/// cannot write to production by mistake. TestFlight/production builds must
/// pass an explicit production `NOMO_BACKEND_URL`.

class BackendConfig {
  const BackendConfig._();

  static const _devBaseUrl = 'http://127.0.0.1:8080';

  static const _definedBaseUrl = String.fromEnvironment(
    'NOMO_BACKEND_URL',
    defaultValue: _devBaseUrl,
  );

  /// Local `flutter run` / Simulator checks are non-release builds, and must
  /// always stay on the dev backend so backend-mediated writes also use dev DB.
  static String get baseUrl {
    if (!kReleaseMode) {
      return _devBaseUrl;
    }
    return _definedBaseUrl;
  }
}
