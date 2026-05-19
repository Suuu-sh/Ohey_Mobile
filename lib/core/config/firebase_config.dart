import 'package:firebase_core/firebase_core.dart';

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
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
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
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  static FirebaseOptions? get currentPlatformOptions {
    if (!hasDartDefineOptions) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
      androidClientId: androidClientId.isEmpty ? null : androidClientId,
      iosClientId: iosClientId.isEmpty ? null : iosClientId,
    );
  }
}
