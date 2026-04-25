import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/entitlement.dart';
import '../../../core/models/session_data.dart';
import '../../../core/networking/backend_api.dart';
import '../../../core/services/service_providers.dart';
import '../../auth/state/auth_controller.dart';
import '../data/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    backendApi: ref.watch(backendApiProvider),
    revenueCatService: ref.watch(revenueCatServiceProvider),
  );
});

class EntitlementController extends AsyncNotifier<Entitlement> {
  @override
  Future<Entitlement> build() async {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final session = authState?.session;
    return _load(session);
  }

  Future<Entitlement> _load(SessionData? session) async {
    try {
      final result = await ref.read(subscriptionRepositoryProvider).fetchEntitlement(session);

      final guestSessionId = result.guestSessionId;
      if (guestSessionId != null && guestSessionId.isNotEmpty) {
        await ref.read(authControllerProvider.notifier).setGuestSessionId(guestSessionId);
      }

      await ref.read(authControllerProvider.notifier).syncSessionIdentity(
            userId: result.data.userId,
            rcAppUserId: result.data.rcAppUserId,
          );

      return result.data;
    } catch (_) {
      return Entitlement.free;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final authState = ref.read(authControllerProvider).valueOrNull;
    final entitlement = await _load(authState?.session);
    state = AsyncData(entitlement);
  }
}

final entitlementControllerProvider =
    AsyncNotifierProvider<EntitlementController, Entitlement>(EntitlementController.new);
