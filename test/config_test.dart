import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/config/auth_provider_config.dart';
import 'package:ohey/core/config/backend_config.dart';

void main() {
  test('debug/test builds use dev Clerk redirect and dev Render backend', () {
    expect(
      AuthProviderConfig.redirectUrl,
      'app.ohey.com.dev://login-callback/',
    );
    expect(BackendConfig.baseUrl, 'https://dev-ohey-backend.onrender.com');
  });

  test('OAuth callbacks are accepted only for the configured redirect URL', () {
    expect(
      AuthProviderConfig.isAllowedOAuthCallback(
        Uri.parse('app.ohey.com.dev://login-callback/?token=abc'),
      ),
      isTrue,
    );
    expect(
      AuthProviderConfig.isAllowedOAuthCallback(
        Uri.parse('app.ohey.com://login-callback/?token=abc'),
      ),
      isFalse,
    );
  });

  test(
    'iOS native OAuth callback scheme is provided by an override xcconfig',
    () {
      final debugConfig = File('ios/Flutter/Debug.xcconfig').readAsStringSync();
      final releaseConfig = File(
        'ios/Flutter/Release.xcconfig',
      ).readAsStringSync();

      expect(debugConfig, contains('OheyLocalOverrides.xcconfig'));
      expect(releaseConfig, contains('OheyLocalOverrides.xcconfig'));
      expect(
        releaseConfig,
        isNot(
          contains(
            r'GOOGLE_IOS_REVERSED_CLIENT_ID=$(GOOGLE_IOS_REVERSED_CLIENT_ID)',
          ),
        ),
      );
    },
  );
}
