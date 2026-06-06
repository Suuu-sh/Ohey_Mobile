import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../application/ohey_user_controller.dart';
import '../config/ohey_revenuecat_config.dart';
import '../data/supabase_client_provider.dart';

final oheyPlusServiceProvider = Provider<OheyPlusService>((ref) {
  return OheyPlusService(ref);
});

final oheyPlusCustomerInfoProvider = FutureProvider<rc.CustomerInfo?>((
  ref,
) async {
  return ref.watch(oheyPlusServiceProvider).customerInfo();
});

final oheyPlusActiveProvider = Provider<bool>((ref) {
  final backendPlus = ref.watch(oheyUserProvider)?.isPlus ?? false;
  final revenueCatPlus = ref
      .watch(oheyPlusCustomerInfoProvider)
      .maybeWhen(
        data: (info) => OheyPlusService.hasPlusEntitlement(info),
        orElse: () => false,
      );
  return backendPlus || revenueCatPlus;
});

final oheyPlusOfferingProvider = FutureProvider<rc.Offering?>((ref) async {
  return ref.watch(oheyPlusServiceProvider).currentOffering();
});

class OheyPlusService {
  OheyPlusService(this._ref);

  final Ref _ref;
  bool _configureStarted = false;
  String? _configuredAppUserId;

  Future<bool> configureForCurrentUser() async {
    if (!OheyRevenueCatConfig.isConfigured) return false;

    final supabase = _ref.read(supabaseClientProvider);
    final appUserId = supabase.auth.currentUser?.id;
    if (appUserId == null || appUserId.trim().isEmpty) return false;

    if (_configureStarted && _configuredAppUserId == appUserId) return true;

    final alreadyConfigured = await _isConfigured();
    if (alreadyConfigured) {
      await rc.Purchases.logIn(appUserId);
    } else {
      await rc.Purchases.configure(
        rc.PurchasesConfiguration(OheyRevenueCatConfig.iosApiKey)
          ..appUserID = appUserId,
      );
      _configureStarted = true;
    }
    _configuredAppUserId = appUserId;
    return true;
  }

  Future<rc.CustomerInfo?> customerInfo() async {
    final configured = await configureForCurrentUser();
    if (!configured) return null;
    return rc.Purchases.getCustomerInfo();
  }

  Future<rc.Offering?> currentOffering() async {
    final configured = await configureForCurrentUser();
    if (!configured) return null;
    final offerings = await rc.Purchases.getOfferings();
    return offerings.getOffering(OheyRevenueCatConfig.offeringId) ??
        offerings.current;
  }

  rc.Package? preferredPackage(rc.Offering? offering) {
    if (offering == null) return null;
    final productId = OheyRevenueCatConfig.productId;
    for (final package in offering.availablePackages) {
      if (package.storeProduct.identifier == productId) return package;
    }
    final monthly = offering.monthly;
    if (monthly != null) return monthly;
    return offering.availablePackages.isEmpty
        ? null
        : offering.availablePackages.first;
  }

  Future<rc.CustomerInfo?> purchase(rc.Package package) async {
    final configured = await configureForCurrentUser();
    if (!configured) return null;
    final result = await rc.Purchases.purchase(
      rc.PurchaseParams.package(package),
    );
    _ref.invalidate(oheyPlusCustomerInfoProvider);
    return result.customerInfo;
  }

  Future<rc.CustomerInfo?> restore() async {
    final configured = await configureForCurrentUser();
    if (!configured) return null;
    final info = await rc.Purchases.restorePurchases();
    _ref.invalidate(oheyPlusCustomerInfoProvider);
    return info;
  }

  Future<void> logOutIfConfigured() async {
    if (!OheyRevenueCatConfig.isConfigured) return;
    if (!await _isConfigured()) return;
    try {
      await rc.Purchases.logOut();
      _configuredAppUserId = null;
    } catch (error, stackTrace) {
      debugPrint('RevenueCat logout skipped: $error\n$stackTrace');
    }
  }

  bool isCancellation(Object error) {
    if (error is! PlatformException) return false;
    final purchasesErrorCode = rc.PurchasesErrorHelper.getErrorCode(error);
    return purchasesErrorCode == rc.PurchasesErrorCode.purchaseCancelledError;
  }

  static bool hasPlusEntitlement(rc.CustomerInfo? info) {
    if (info == null) return false;
    final entitlement =
        info.entitlements.active[OheyRevenueCatConfig.entitlementId];
    return entitlement?.isActive ?? false;
  }

  Future<bool> _isConfigured() async {
    try {
      return await rc.Purchases.isConfigured;
    } catch (_) {
      return false;
    }
  }
}
