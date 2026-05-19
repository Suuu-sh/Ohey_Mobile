import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase/FCM environment configuration for Nomo.
///
/// If the Firebase dart-defines below are supplied, the app initializes Firebase
/// from those values. Otherwise it falls back to the native Firebase files:
///
/// - iOS: `GoogleService-Info.plist` in the Runner bundle
/// - Android: `google-services.json` for the selected Android flavor/source set
class NomoFirebaseConfig {
  const NomoFirebaseConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const androidClientId = String.fromEnvironment(
    'FIREBASE_ANDROID_CLIENT_ID',
  );
  static const iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');

  static bool get hasDartDefineOptions =>
      _platformApiKey.isNotEmpty &&
      _platformAppId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  static String get _platformApiKey {
    if (defaultTargetPlatform == TargetPlatform.iOS && iosApiKey.isNotEmpty) {
      return iosApiKey;
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        androidApiKey.isNotEmpty) {
      return androidApiKey;
    }
    return apiKey;
  }

  static String get _platformAppId {
    if (defaultTargetPlatform == TargetPlatform.iOS && iosAppId.isNotEmpty) {
      return iosAppId;
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        androidAppId.isNotEmpty) {
      return androidAppId;
    }
    return appId;
  }

  static FirebaseOptions? get currentPlatformOptions {
    if (!hasDartDefineOptions) return null;
    return FirebaseOptions(
      apiKey: _platformApiKey,
      appId: _platformAppId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
      androidClientId: androidClientId.isEmpty ? null : androidClientId,
      iosClientId: iosClientId.isEmpty ? null : iosClientId,
    );
  }
}
