import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseState {
  final bool loadingOfferings;
  final bool purchasing;
  final bool restoring;
  final Offerings? offerings;
  final Package? selectedPackage;
  final CustomerInfo? customerInfo;
  final String? error;

  const PurchaseState({
    required this.loadingOfferings,
    required this.purchasing,
    required this.restoring,
    this.offerings,
    this.selectedPackage,
    this.customerInfo,
    this.error,
  });

  factory PurchaseState.initial() {
    return const PurchaseState(
      loadingOfferings: true,
      purchasing: false,
      restoring: false,
      offerings: null,
      selectedPackage: null,
      customerInfo: null,
      error: null,
    );
  }

  PurchaseState copyWith({
    bool? loadingOfferings,
    bool? purchasing,
    bool? restoring,
    Offerings? offerings,
    bool clearOfferings = false,
    Package? selectedPackage,
    bool clearSelectedPackage = false,
    CustomerInfo? customerInfo,
    bool clearCustomerInfo = false,
    String? error,
    bool clearError = false,
  }) {
    return PurchaseState(
      loadingOfferings: loadingOfferings ?? this.loadingOfferings,
      purchasing: purchasing ?? this.purchasing,
      restoring: restoring ?? this.restoring,
      offerings: clearOfferings ? null : (offerings ?? this.offerings),
      selectedPackage: clearSelectedPackage ? null : (selectedPackage ?? this.selectedPackage),
      customerInfo: clearCustomerInfo ? null : (customerInfo ?? this.customerInfo),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
