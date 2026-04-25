import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/models/entitlement.dart';
import '../../../core/models/session_data.dart';
import '../../../core/networking/backend_api.dart';
import '../../../core/services/revenuecat_service.dart';

class SubscriptionRepository {
  final BackendApi backendApi;
  final RevenueCatService revenueCatService;

  SubscriptionRepository({
    required this.backendApi,
    required this.revenueCatService,
  });

  Future<ApiEnvelope<Entitlement>> fetchEntitlement(SessionData? session) {
    return backendApi.getEntitlement(session);
  }

  Future<Offerings?> getOfferings() {
    return revenueCatService.getOfferings();
  }

  Package? getPreferredPackage(Offerings? offerings) {
    return revenueCatService.findPreferredPackage(offerings);
  }

  Future<CustomerInfo?> purchase(Package package) {
    return revenueCatService.purchasePackage(package);
  }

  Future<CustomerInfo?> restore() {
    return revenueCatService.restorePurchases();
  }

  Future<CustomerInfo?> customerInfo() {
    return revenueCatService.getCustomerInfo();
  }
}
