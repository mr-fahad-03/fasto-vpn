import '../../../core/models/session_data.dart';
import '../../../core/networking/backend_api.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/revenuecat_service.dart';
import '../../../core/storage/app_storage.dart';

class AuthRepository {
  final BackendApi backendApi;
  final AppStorage storage;
  final FirebaseAuthService firebaseAuthService;
  final RevenueCatService revenueCatService;

  AuthRepository({
    required this.backendApi,
    required this.storage,
    required this.firebaseAuthService,
    required this.revenueCatService,
  });

  Future<SessionData?> restoreSession() async {
    final persisted = await storage.readSession();
    if (persisted == null) {
      return null;
    }

    if (persisted.isGuest) {
      if ((persisted.guestSessionId ?? '').isEmpty) {
        await storage.clearSession();
        return null;
      }

      if ((persisted.rcAppUserId ?? '').isNotEmpty) {
        await revenueCatService.logIn(persisted.rcAppUserId!);
      }

      return persisted;
    }

    final restored = await firebaseAuthService.restoreGoogleSession();
    if (restored == null) {
      await storage.clearSession();
      return null;
    }

    final handshake = await backendApi.authenticateFirebase(
      firebaseIdToken: restored.idToken,
      guestSessionId: persisted.guestSessionId,
    );

    final session = SessionData(
      mode: AuthMode.google,
      firebaseIdToken: restored.idToken,
      firebaseUid: restored.uid,
      email: restored.email,
      displayName: restored.displayName,
      userId: handshake.userId,
      rcAppUserId: handshake.rcAppUserId,
      deviceSessionId: handshake.deviceSessionId,
      guestSessionId: persisted.guestSessionId,
    );

    await storage.saveSession(session);

    if (handshake.rcAppUserId.isNotEmpty) {
      await revenueCatService.logIn(handshake.rcAppUserId);
    }

    return session;
  }

  Future<SessionData> signInAsGuest() async {
    await revenueCatService.logOut();
    final created = await backendApi.createGuestSession();

    if (created.guestSessionId.isEmpty) {
      throw Exception('Could not create guest session');
    }

    final session = SessionData(
      mode: AuthMode.guest,
      guestSessionId: created.guestSessionId,
      userId: created.userId,
      rcAppUserId: created.rcAppUserId,
    );

    await storage.saveSession(session);

    if (created.rcAppUserId.isNotEmpty) {
      await revenueCatService.logIn(created.rcAppUserId);
    }

    return session;
  }

  Future<SessionData> signInWithGoogle({SessionData? currentSession}) async {
    final result = await firebaseAuthService.signInWithGoogle();

    final handshake = await backendApi.authenticateFirebase(
      firebaseIdToken: result.idToken,
      guestSessionId: currentSession?.guestSessionId,
    );

    final session = SessionData(
      mode: AuthMode.google,
      firebaseIdToken: result.idToken,
      firebaseUid: result.uid,
      email: result.email,
      displayName: result.displayName,
      userId: handshake.userId,
      rcAppUserId: handshake.rcAppUserId,
      deviceSessionId: handshake.deviceSessionId,
      guestSessionId: currentSession?.guestSessionId,
    );

    await storage.saveSession(session);

    if (handshake.rcAppUserId.isNotEmpty) {
      await revenueCatService.logIn(handshake.rcAppUserId);
    }

    return session;
  }

  Future<SessionData?> refreshTokenIfNeeded(SessionData? current) async {
    if (current == null || current.isGuest) {
      return current;
    }

    final restored = await firebaseAuthService.restoreGoogleSession();
    if (restored == null) {
      await storage.clearSession();
      return null;
    }

    final handshake = await backendApi.authenticateFirebase(
      firebaseIdToken: restored.idToken,
      guestSessionId: current.guestSessionId,
    );

    final updated = current.copyWith(
      firebaseIdToken: restored.idToken,
      firebaseUid: restored.uid,
      email: restored.email,
      displayName: restored.displayName,
      userId: handshake.userId,
      rcAppUserId: handshake.rcAppUserId,
      deviceSessionId: handshake.deviceSessionId,
    );

    await storage.saveSession(updated);

    if (handshake.rcAppUserId.isNotEmpty) {
      await revenueCatService.logIn(handshake.rcAppUserId);
    }

    return updated;
  }

  Future<void> saveSession(SessionData session) async {
    await storage.saveSession(session);
  }

  Future<void> signOut() async {
    await firebaseAuthService.signOut();
    await revenueCatService.logOut();
    await storage.clearSession();
  }
}
