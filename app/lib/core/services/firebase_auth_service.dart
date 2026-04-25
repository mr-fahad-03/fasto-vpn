import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/env.dart';

class GoogleAuthResult {
  final String idToken;
  final String uid;
  final String? email;
  final String? displayName;

  const GoogleAuthResult({
    required this.idToken,
    required this.uid,
    this.email,
    this.displayName,
  });
}

class FirebaseAuthService {
  final FirebaseAuth? _firebaseAuthOverride;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuthOverride = firebaseAuth,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<GoogleAuthResult> signInWithGoogle() async {
    if (!Env.firebaseEnabled) {
      throw Exception('Firebase is disabled. Enable FIREBASE_ENABLED=true to sign in with Google.');
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in canceled');
    }

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Unable to complete Google sign-in');
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Unable to obtain Firebase ID token');
    }

    return GoogleAuthResult(
      idToken: idToken,
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  Future<GoogleAuthResult?> restoreGoogleSession() async {
    if (!Env.firebaseEnabled) {
      return null;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      return null;
    }

    return GoogleAuthResult(
      idToken: idToken,
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  Future<void> signOut() async {
    if (Env.firebaseEnabled) {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    }
  }
}
