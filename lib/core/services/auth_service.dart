import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Centralized authentication service.
///
/// Wraps [FirebaseAuth] so that the rest of the app never interacts with
/// FirebaseAuth directly. For the current MVP this uses Anonymous
/// Authentication. If a user is already signed in, the existing session
/// is reused to avoid creating multiple anonymous accounts.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) : _injectedAuth = firebaseAuth;

  /// An injected [FirebaseAuth] (tests), or `null` to resolve the live one.
  final FirebaseAuth? _injectedAuth;

  FirebaseAuth? _resolvedAuth;
  bool _resolvedAuthOnce = false;

  /// The [FirebaseAuth] instance, or `null` when Firebase has not been
  /// initialized. Resolves on first access, and retries if Firebase becomes
  /// available after a previous null resolution. Tests can inject a custom
  /// [FirebaseAuth] via the constructor to avoid live initialization.
  FirebaseAuth? get _auth {
    if (_resolvedAuthOnce && _resolvedAuth != null) {
      return _resolvedAuth;
    }
    _resolvedAuthOnce = true;
    final injected = _injectedAuth;
    if (injected != null) {
      _resolvedAuth = injected;
    } else if (Firebase.apps.isNotEmpty) {
      try {
        _resolvedAuth = FirebaseAuth.instance;
      } catch (_) {
        _resolvedAuth = null;
      }
    } else {
      _resolvedAuth = null;
    }
    return _resolvedAuth;
  }

  /// Manually refresh/resolve the Firebase Auth instance. Call this when Firebase
  /// becomes available after being unavailable (e.g. after a successful network
  /// recovery). This clears any cached unresolved/null auth so the next access
  /// will re-resolve against the live Firebase app.
  void resolveAuth() {
    _resolvedAuth = null;
    _resolvedAuthOnce = false;
  }

  /// The currently signed-in user, or `null` if no session exists or Firebase
  /// is unavailable (e.g. offline).
  User? get currentUser => _auth?.currentUser;

  /// The current Firebase UID, or `null` if sign-in failed (e.g. offline).
  String? get uid => currentUser?.uid;

  /// Signs in anonymously, reusing the existing session when available.
  ///
  /// Returns the [User] object. Throws a [StateError] when Firebase Auth is not
  /// available, which [ensureSignedIn] treats as a failed attempt.
  Future<User> signInAnonymously() async {
    final auth = _auth;
    if (auth == null) {
      throw StateError(
        'Firebase Auth is not available (Firebase was not initialized).',
      );
    }

    // Reuse existing anonymous session if one exists.
    final existing = auth.currentUser;
    if (existing != null) {
      return existing;
    }

    final credential = await auth.signInAnonymously();
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
        debugPrint(
          'Anonymous sign-in attempt $attempt/$maxAttempts failed: $e',
        );
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    return null;
  }
}
