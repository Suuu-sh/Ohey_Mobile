import 'package:flutter/foundation.dart';

/// AdMob configuration for Ohey.
///
/// Debug/Profile builds use Google test IDs. Release builds use only explicit
/// production dart-defines and disable ads if they are missing or still set to
/// Google's sample IDs. This prevents TestFlight/App Store builds from serving
/// sample ads by accident.
class OheyAdsConfig {
  const OheyAdsConfig._();

  static const iosAppIdDefineKey = 'OHEY_ADMOB_IOS_APP_ID';
  static const androidAppIdDefineKey = 'OHEY_ADMOB_ANDROID_APP_ID';
  static const iosNativeAdUnitIdDefineKey = 'OHEY_ADMOB_IOS_NATIVE_AD_UNIT_ID';
  static const androidNativeAdUnitIdDefineKey =
      'OHEY_ADMOB_ANDROID_NATIVE_AD_UNIT_ID';
  static const forceTestAdsDefineKey = 'OHEY_ADMOB_FORCE_TEST_ADS';

  static const googleTestIosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const googleTestAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const googleTestIosNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';
  static const googleTestAndroidNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  static const _definedIosNativeAdUnitId = String.fromEnvironment(
    iosNativeAdUnitIdDefineKey,
  );
  static const _definedAndroidNativeAdUnitId = String.fromEnvironment(
    androidNativeAdUnitIdDefineKey,
  );
  static const _forceTestAds = bool.fromEnvironment(forceTestAdsDefineKey);

  static bool get isEnabled => nativeAdUnitId.isNotEmpty;

  static String get nativeAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _nativeAdUnitIdForPlatform(
        defined: _definedIosNativeAdUnitId,
        testId: googleTestIosNativeAdUnitId,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _nativeAdUnitIdForPlatform(
        defined: _definedAndroidNativeAdUnitId,
        testId: googleTestAndroidNativeAdUnitId,
      );
    }
    return '';
  }

  static String _nativeAdUnitIdForPlatform({
    required String defined,
    required String testId,
  }) {
    if (!kReleaseMode || _forceTestAds) return testId;

    final normalized = defined.trim();
    if (normalized.isEmpty || _isGoogleSampleId(normalized)) return '';
    return normalized;
  }

  static bool _isGoogleSampleId(String value) =>
      value.startsWith('ca-app-pub-3940256099942544/');
}
