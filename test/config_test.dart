import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/config/auth_provider_config.dart';
import 'package:ohey/core/config/backend_config.dart';
import 'package:ohey/core/config/ohey_environment.dart';

void main() {
  test('production backend default uses shared API proxy hostname', () {
    expect(
      OheyEnvironmentValues.productionBackendUrl,
      'https://api.oheyapp.com',
    );
  });

  test('Apple OAuth is enabled by default for configured builds', () {
    expect(AuthProviderConfig.appleOAuthEnabled, isTrue);
  });

  test('Clerk session tokens use the backend audience JWT template', () {
    expect(AuthProviderConfig.clerkJwtTemplateName, 'ohey-mobile');
  });

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

  test('iOS app privacy manifest is bundled in the Runner target', () {
    final manifest = File(
      'ios/Runner/PrivacyInfo.xcprivacy',
    ).readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(manifest, contains('NSPrivacyCollectedDataTypeEmailAddress'));
    expect(manifest, contains('NSPrivacyCollectedDataTypeOtherUserContent'));
    expect(manifest, contains('NSPrivacyCollectedDataTypeContacts'));
    expect(
      manifest,
      isNot(contains('NSPrivacyCollectedDataTypePreciseLocation')),
    );
    expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
  });

  test('iOS Debug configuration supports Simulator verification', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(
      project,
      contains('SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";'),
    );
  });

  test('iOS declares only permissions used by the current release', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(info, contains('NSCameraUsageDescription'));
    expect(info, contains('NSUserTrackingUsageDescription'));
    expect(info, isNot(contains('NSLocationWhenInUseUsageDescription')));
    expect(info, isNot(contains('NSPhotoLibraryAddUsageDescription')));
    expect(appDelegate, isNot(contains('ohey/place_search')));
    expect(appDelegate, isNot(contains('ohey/qr_saver')));
  });

  test('release code never reads or logs the advertising identifier', () {
    final adsConsentService = File(
      'lib/core/services/ohey_ads_consent_service.dart',
    ).readAsStringSync();

    expect(adsConsentService, isNot(contains('getAdvertisingIdentifier')));
    expect(adsConsentService, isNot(contains('iOS IDFA')));
  });
}
