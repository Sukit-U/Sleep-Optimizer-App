import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Centralized authentication service.
///
/// Wraps [FirebaseAuth] so that the rest of the app never interacts with
/// FirebaseAuth directly. For the current MVP this uses Anonymous
/// Authentication. If a user is already signed in, the existing session
/// is reused to avoid creating multiple anonymous accounts.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The currently signed-in user, or `null` if no session exists.
  User? get currentUser => _auth.currentUser;

  /// The current Firebase UID, or `null` if sign-in failed (e.g. offline).
  String? get uid => currentUser?.uid;

  /// Signs in anonymously, reusing the existing session when available.
  ///
  /// Returns the [User] object.
  Future<User> signInAnonymously() async {
    // Reuse existing anonymous session if one exists.
    final existing = _auth.currentUser;
    if (existing != null) {
      return existing;
    }

    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// Returns the signed-in UID, retrying a failed anonymous sign-in.
  ///
  /// Boot and save paths call this so transient failures — offline at
  /// launch, or the Anonymous provider being enabled while the app is
  /// running — recover without an app restart. Returns `null` only when
  /// every attempt failed.
  Future<String?> ensureSignedIn({int maxAttempts = 3}) async {
    final existing = currentUser?.uid;
    if (existing != null) return existing;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final user = await signInAnonymously();
        return user.uid;
      } catch (e) {
        debugPrint('Anonymous sign-in attempt $attempt/$maxAttempts failed: $e');
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    return null;
  }
}
