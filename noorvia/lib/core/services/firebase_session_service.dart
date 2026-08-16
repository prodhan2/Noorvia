import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Ensures every app installation has a stable Firebase uid even when the
/// user has not created a visible account yet. This lets private per-user
/// data (for example namaz tracking) be protected by Firestore rules.
class FirebaseSessionService {
  FirebaseSessionService._();

  static Future<User?> ensureSignedIn() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) return auth.currentUser;
      final credential = await auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      debugPrint('Firebase anonymous sign-in unavailable: $e');
      return null;
    }
  }
}
