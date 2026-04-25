import 'package:firebase_core/firebase_core.dart';
import '../config/env.dart';

class FirebaseInitializer {
  Future<void> initialize() async {
    if (!Env.firebaseEnabled) {
      return;
    }

    await Firebase.initializeApp();
  }
}
