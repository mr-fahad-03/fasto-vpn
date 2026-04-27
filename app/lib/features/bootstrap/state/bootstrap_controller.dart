import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/services/service_providers.dart';
import 'bootstrap_state.dart';

class BootstrapController extends AsyncNotifier<BootstrapState> {
  @override
  Future<BootstrapState> build() async {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }

    final firebaseInitializer = ref.read(firebaseInitializerProvider);
    final revenueCat = ref.read(revenueCatServiceProvider);
    final adService = ref.read(adServiceProvider);
    final storage = ref.read(appStorageProvider);

    await firebaseInitializer.initialize();
    await revenueCat.initialize();
    await adService.initialize();

    final onboardingDone = await storage.isOnboardingDone();

    return BootstrapState(
      initialized: true,
      onboardingDone: onboardingDone,
    );
  }

  Future<void> markOnboardingDone() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    await ref.read(appStorageProvider).setOnboardingDone(true);
    state = AsyncData(current.copyWith(onboardingDone: true));
  }
}

final bootstrapControllerProvider =
    AsyncNotifierProvider<BootstrapController, BootstrapState>(BootstrapController.new);
