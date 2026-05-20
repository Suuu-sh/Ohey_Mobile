import 'package:flutter/foundation.dart';

/// Go backend environment configuration for Nomo.
///
/// Non-release builds (Simulator / `flutter run`) are forced to the local dev
/// backend so backend-mediated writes also use dev DB. Release builds
/// (TestFlight/App Store) default to the production backend even if
/// dart-defines are missing, and may still override with `NOMO_BACKEND_URL`.
class BackendConfig {
  const BackendConfig._();

  static const _devBaseUrl = 'http://127.0.0.1:8080';
  static const _prodBaseUrl = 'https://nomo-backend-nezf.onrender.com';

  static const _definedBaseUrl = String.fromEnvironment('NOMO_BACKEND_URL');

  static String get baseUrl {
    if (!kReleaseMode) {
      return _devBaseUrl;
    }
    return _definedBaseUrl.isEmpty ? _prodBaseUrl : _definedBaseUrl;
  }
}
