import 'package:flutter/foundation.dart';

import 'ohey_environment.dart';

class OheyRevenueCatConfig {
  const OheyRevenueCatConfig._();

  static const iosApiKeyDefineKey = 'OHEY_REVENUECAT_IOS_API_KEY';
  static const entitlementIdDefineKey = 'OHEY_REVENUECAT_ENTITLEMENT_ID';
  static const offeringIdDefineKey = 'OHEY_REVENUECAT_OFFERING_ID';
  static const productIdDefineKey = 'OHEY_REVENUECAT_PRODUCT_ID';

  static const defaultEntitlementId = 'plus';
  static const defaultOfferingId = 'default';
  static const defaultProductId = 'ohey_plus_monthly';

  static const iosApiKey = String.fromEnvironment(iosApiKeyDefineKey);
  static const entitlementId = String.fromEnvironment(
    entitlementIdDefineKey,
    defaultValue: defaultEntitlementId,
  );
  static const offeringId = String.fromEnvironment(
    offeringIdDefineKey,
    defaultValue: defaultOfferingId,
  );
  static const productId = String.fromEnvironment(
    productIdDefineKey,
    defaultValue: defaultProductId,
  );

  static const environment = String.fromEnvironment(
    OheyEnvironmentValues.environmentDefineKey,
    defaultValue: OheyEnvironmentValues.devEnvironment,
  );

  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isConfigured =>
      isSupportedPlatform && iosApiKey.trim().isNotEmpty;

  static bool get isProduction =>
      environment == OheyEnvironmentValues.productionEnvironment;
}
