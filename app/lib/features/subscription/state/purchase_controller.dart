import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/state/auth_controller.dart';
import 'entitlement_controller.dart';
import 'purchase_state.dart';

class PurchaseController extends AsyncNotifier<PurchaseState> {
  Future<void> _refreshEntitlementWithBackoff({required bool expectPremium}) async {
    final delays = <Duration>[
      Duration.zero,
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
    ];

    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }

      await ref.read(entitlementControllerProvider.notifier).refresh();
      final entitlement = ref.read(entitlementControllerProvider).valueOrNull;

      if (entitlement == null) {
        continue;
      }

      if (!expectPremium || entitlement.hasPremium) {
        return;
      }
    }
  }

  @override
  Future<PurchaseState> build() async {
    return _loadInitial();
  }

  Future<PurchaseState> _loadInitial() async {
    final repository = ref.read(subscriptionRepositoryProvider);

    try {
      final offerings = await repository.getOfferings();
      final selected = repository.getPreferredPackage(offerings);
      final customerInfo = await repository.customerInfo();

      return PurchaseState.initial().copyWith(
        loadingOfferings: false,
        offerings: offerings,
        selectedPackage: selected,
        customerInfo: customerInfo,
        clearError: true,
      );
    } catch (error) {
      return PurchaseState.initial().copyWith(
        loadingOfferings: false,
        error: error.toString(),
      );
    }
  }

  Future<void> refreshOfferings() async {
    final current = state.valueOrNull ?? PurchaseState.initial();
    state = AsyncData(current.copyWith(loadingOfferings: true, clearError: true));

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final offerings = await repository.getOfferings();
      final selected = repository.getPreferredPackage(offerings);
      state = AsyncData(current.copyWith(
        loadingOfferings: false,
        offerings: offerings,
        selectedPackage: selected,
        clearError: true,
      ));
    } catch (error) {
      state = AsyncData(current.copyWith(
        loadingOfferings: false,
        error: error.toString(),
      ));
    }
  }

  Future<void> purchaseSelected() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final authState = ref.read(authControllerProvider).valueOrNull;
    if (authState?.session == null || authState!.session!.isGuest) {
      state = AsyncData(current.copyWith(error: 'Please sign in with Google to purchase premium.'));
      return;
    }

    final package = current.selectedPackage;
    if (package == null) {
      state = AsyncData(current.copyWith(error: 'Premium plan is not available right now.'));
      return;
    }

    state = AsyncData(current.copyWith(purchasing: true, clearError: true));

    try {
      final customerInfo = await ref.read(subscriptionRepositoryProvider).purchase(package);
      state = AsyncData(current.copyWith(
        purchasing: false,
        customerInfo: customerInfo,
        clearError: true,
      ));
      await _refreshEntitlementWithBackoff(expectPremium: true);
    } catch (error) {
      state = AsyncData(current.copyWith(purchasing: false, error: error.toString()));
    }
  }

  Future<void> restorePurchases() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(restoring: true, clearError: true));

    try {
      final customerInfo = await ref.read(subscriptionRepositoryProvider).restore();
      state = AsyncData(current.copyWith(
        restoring: false,
        customerInfo: customerInfo,
        clearError: true,
      ));
      await _refreshEntitlementWithBackoff(expectPremium: false);
    } catch (error) {
      state = AsyncData(current.copyWith(restoring: false, error: error.toString()));
    }
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(clearError: true));
  }
}

final purchaseControllerProvider =
    AsyncNotifierProvider<PurchaseController, PurchaseState>(PurchaseController.new);
