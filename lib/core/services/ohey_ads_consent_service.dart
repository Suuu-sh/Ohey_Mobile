import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ohey_ads_config.dart';

/// Coordinates AdMob initialization with Google's UMP consent flow.
///
/// Release builds only enable ads when production ad unit IDs are provided via
/// dart-define. When ads are enabled, ad requests are gated on UMP's
/// `canRequestAds()` result so that required consent can be gathered before the
/// first ad load.
class OheyAdsConsentService {
  const OheyAdsConsentService._();

  static Future<bool>? _prepareFuture;
  static Future<InitializationStatus>? _mobileAdsInitializationFuture;

  /// Returns true when the app may request ads in the current consent state.
  static Future<bool> prepareToRequestAds() {
    if (!OheyAdsConfig.isEnabled) return Future<bool>.value(false);
    return _prepareFuture ??= _prepareToRequestAds();
  }

  /// Returns true when Google requires an in-app privacy options entry point.
  static Future<bool> isPrivacyOptionsRequired() async {
    if (!OheyAdsConfig.isEnabled) return false;

    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (error, stackTrace) {
      debugPrint(
        'OheyAdsConsentService: failed to read privacy options status: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Ensures UMP has refreshed consent state before deciding whether the app
  /// must expose a privacy options entry point.
  static Future<bool> shouldShowPrivacyOptionsEntryPoint() async {
    if (!OheyAdsConfig.isEnabled) return false;

    await prepareToRequestAds();
    return isPrivacyOptionsRequired();
  }

  /// Presents Google's privacy options form when it is required and available.
  ///
  /// Returns true when the form was shown without an SDK error.
  static Future<bool> showPrivacyOptionsForm() async {
    if (!OheyAdsConfig.isEnabled) return false;

    await prepareToRequestAds();
    if (!await isPrivacyOptionsRequired()) return false;

    final error = await _showPrivacyOptionsForm();
    if (error != null) {
      debugPrint(
        'OheyAdsConsentService: failed to show privacy options form '
        '(${error.errorCode}): ${error.message}',
      );
      return false;
    }
    return true;
  }

  static Future<bool> _prepareToRequestAds() async {
    await _requestAppTrackingAuthorizationIfNeeded();

    try {
      await _requestConsentInfoUpdate();
    } catch (error, stackTrace) {
      // Google recommends checking canRequestAds() even after consent gathering
      // errors because the SDK may be able to use a previous session's state.
      debugPrint('OheyAdsConsentService: consent info update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      final formError = await _loadAndShowConsentFormIfRequired();
      if (formError != null) {
        debugPrint(
          'OheyAdsConsentService: consent form failed '
          '(${formError.errorCode}): ${formError.message}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('OheyAdsConsentService: consent form error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    final canRequestAds = await _canRequestAds();
    if (canRequestAds) {
      await _initializeMobileAds();
    }
    return canRequestAds;
  }

  static Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      completer.complete,
      completer.completeError,
    );
    return completer.future;
  }

  static Future<FormError?> _loadAndShowConsentFormIfRequired() {
    final completer = Completer<FormError?>();
    ConsentForm.loadAndShowConsentFormIfRequired(completer.complete);
    return completer.future;
  }

  static Future<FormError?> _showPrivacyOptionsForm() {
    final completer = Completer<FormError?>();
    ConsentForm.showPrivacyOptionsForm(completer.complete);
    return completer.future;
  }

  static Future<bool> _canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (error, stackTrace) {
      debugPrint('OheyAdsConsentService: failed to read canRequestAds: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<InitializationStatus> _initializeMobileAds() {
    return _mobileAdsInitializationFuture ??= MobileAds.instance.initialize();
  }

  static Future<void> _requestAppTrackingAuthorizationIfNeeded() async {
    if (!Platform.isIOS) return;

    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // iOS requires the app to ask explicitly before the system ATT prompt
        // can appear. Waiting briefly avoids presenting it during launch
        // transition animations.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final updatedStatus =
            await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint(
          'OheyAdsConsentService: ATT status after request: $updatedStatus',
        );
      } else {
        debugPrint('OheyAdsConsentService: ATT status: $status');
      }

      final advertisingIdentifier =
          await AppTrackingTransparency.getAdvertisingIdentifier();
      debugPrint(
        'OheyAdsConsentService: iOS IDFA for AdMob test device registration: '
        '$advertisingIdentifier',
      );
    } catch (error, stackTrace) {
      debugPrint('OheyAdsConsentService: ATT request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
