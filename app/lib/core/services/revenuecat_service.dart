import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/env.dart';

class RevenueCatService {
  bool _initialized = false;

  bool get isConfigured => Env.revenueCatApiKey.isNotEmpty;

  Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      return;
    }

    final config = PurchasesConfiguration(Env.revenueCatApiKey);
    await Purchases.configure(config);
    _initialized = true;
  }

  Future<void> logIn(String appUserId) async {
    if (!_initialized || appUserId.isEmpty) {
      return;
    }
    await Purchases.logIn(appUserId);
  }

  Future<void> logOut() async {
    if (!_initialized) {
      return;
    }
    await Purchases.logOut();
  }

  Future<Offerings?> getOfferings() async {
    if (!_initialized) {
      return null;
    }
    return Purchases.getOfferings();
  }

  Package? findPreferredPackage(Offerings? offerings) {
    if (offerings == null) {
      return null;
    }

    Offering? offering;
    if (Env.revenueCatOfferingId.isNotEmpty) {
      offering = offerings.getOffering(Env.revenueCatOfferingId);
    }

    offering ??= offerings.current;
    if (offering == null) {
      return null;
    }

    for (final pkg in offering.availablePackages) {
      if (pkg.identifier == Env.revenueCatPackageId) {
        return pkg;
      }
    }

    return offering.availablePackages.isNotEmpty
        ? offering.availablePackages.first
        : null;
  }

  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_initialized) {
      throw Exception('RevenueCat is not initialized.');
    }

    final result = await Purchases.purchasePackage(package);
    return result;
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) {
      throw Exception('RevenueCat is not initialized.');
    }

    return Purchases.restorePurchases();
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_initialized) {
      return null;
    }
    return Purchases.getCustomerInfo();
  }
}
