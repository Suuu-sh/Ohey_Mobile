import 'package:flutter/foundation.dart';

import 'ohey_environment.dart';

/// Go backend environment configuration for Ohey.
///
/// Non-release builds (Simulator / `flutter run`) are forced to the dev Render
/// backend so backend-mediated writes also use dev DB. Release builds
/// (TestFlight/App Store) default to the production backend even if
/// dart-defines are missing, and may still override with `OHEY_BACKEND_URL`.
class BackendConfig {
  const BackendConfig._();

  static const _definedBaseUrl = String.fromEnvironment(
    OheyEnvironmentValues.backendUrlDefineKey,
  );

  static String get baseUrl {
    if (!kReleaseMode) {
      return OheyEnvironmentValues.devBackendUrl;
    }
    return _definedBaseUrl.isEmpty
        ? OheyEnvironmentValues.productionBackendUrl
        : _definedBaseUrl;
  }
}
