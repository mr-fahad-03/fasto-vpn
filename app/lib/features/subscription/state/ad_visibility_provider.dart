import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'entitlement_controller.dart';

final adVisibilityProvider = Provider<bool>((ref) {
  final entitlement = ref.watch(entitlementControllerProvider).valueOrNull;
  if (entitlement == null) {
    return false;
  }

  return !entitlement.hasPremium && entitlement.adsEnabled;
});
