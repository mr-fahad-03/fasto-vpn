import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/session_data.dart';
import '../../../core/networking/backend_api.dart';
import '../../../core/services/service_providers.dart';
import '../../bootstrap/state/bootstrap_controller.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    backendApi: ref.watch(backendApiProvider),
    storage: ref.watch(appStorageProvider),
    firebaseAuthService: ref.watch(firebaseAuthServiceProvider),
    revenueCatService: ref.watch(revenueCatServiceProvider),
  );
});

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Ensure bootstrap (including Firebase initialization) is complete first.
    await ref.read(bootstrapControllerProvider.future);

    final repository = ref.read(authRepositoryProvider);
    try {
      final restored = await repository.restoreSession();

      return AuthState(
        initializing: false,
        busy: false,
        session: restored,
      );
    } catch (error) {
      // Never keep the app blocked on splash if session restore fails.
      await ref.read(appStorageProvider).clearSession();

      return AuthState(
        initializing: false,
        busy: false,
        session: null,
        error: 'Session restore failed: $error',
      );
    }
  }

  Future<void> continueAsGuest() async {
    final current = state.valueOrNull ?? AuthState.initial();
    state = AsyncData(current.copyWith(busy: true, clearError: true));

    try {
      final session = await ref.read(authRepositoryProvider).signInAsGuest();
      state = AsyncData(current.copyWith(initializing: false, busy: false, session: session, clearError: true));
    } catch (error) {
      state = AsyncData(current.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    final current = state.valueOrNull ?? AuthState.initial();
    state = AsyncData(current.copyWith(busy: true, clearError: true));

    try {
      final session = await ref.read(authRepositoryProvider).signInWithGoogle(
            currentSession: current.session,
          );
      state = AsyncData(current.copyWith(initializing: false, busy: false, session: session, clearError: true));
    } catch (error) {
      state = AsyncData(current.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<void> signOut() async {
    final current = state.valueOrNull ?? AuthState.initial();
    state = AsyncData(current.copyWith(busy: true, clearError: true));

    try {
      await ref.read(authRepositoryProvider).signOut();
      state = AsyncData(current.copyWith(initializing: false, busy: false, clearSession: true, clearError: true));
    } catch (error) {
      state = AsyncData(current.copyWith(busy: false, error: error.toString()));
    }
  }

  Future<void> refreshGoogleTokenIfNeeded() async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final refreshed = await ref.read(authRepositoryProvider).refreshTokenIfNeeded(current.session);
    state = AsyncData(current.copyWith(session: refreshed));
  }

  Future<void> setGuestSessionId(String sessionId) async {
    if (sessionId.isEmpty) {
      return;
    }

    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    if (current.session == null) {
      final session = SessionData(mode: AuthMode.guest, guestSessionId: sessionId);
      await ref.read(authRepositoryProvider).saveSession(session);
      state = AsyncData(current.copyWith(session: session, clearError: true));
      return;
    }

    if (!current.session!.isGuest) {
      return;
    }

    final updated = current.session!.copyWith(guestSessionId: sessionId);
    await ref.read(authRepositoryProvider).saveSession(updated);
    state = AsyncData(current.copyWith(session: updated, clearError: true));
  }

  Future<void> syncSessionIdentity({
    String? userId,
    String? rcAppUserId,
    String? deviceSessionId,
  }) async {
    final current = state.valueOrNull;
    if (current == null || current.session == null) {
      return;
    }

    var changed = false;
    var updated = current.session!;

    if (userId != null && userId.isNotEmpty && userId != updated.userId) {
      updated = updated.copyWith(userId: userId);
      changed = true;
    }

    if (rcAppUserId != null && rcAppUserId.isNotEmpty && rcAppUserId != updated.rcAppUserId) {
      updated = updated.copyWith(rcAppUserId: rcAppUserId);
      changed = true;
    }

    if (deviceSessionId != null && deviceSessionId.isNotEmpty && deviceSessionId != updated.deviceSessionId) {
      updated = updated.copyWith(deviceSessionId: deviceSessionId);
      changed = true;
    }

    if (!changed) {
      return;
    }

    await ref.read(authRepositoryProvider).saveSession(updated);
    state = AsyncData(current.copyWith(session: updated, clearError: true));
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(clearError: true));
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
