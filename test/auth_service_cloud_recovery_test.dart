import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/core/services/auth_service.dart';

/// A minimal hand-rolled [FirebaseAuth] stand-in is not feasible (too many
/// abstract members), so these tests exercise [AuthService] through its public
/// contract and the injected-auth seam that the production code relies on.

class _CountingAuth implements FirebaseAuth {
  _CountingAuth();
  int signInCalls = 0;
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? u) => _currentUser = u;

  @override
  Future<UserCredential> signInAnonymously() async {
    signInCalls++;
    final u = _FakeUser('uid-$signInCalls');
    _currentUser = u;
    return _FakeCredential(u);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUser implements User {
  _FakeUser(this._uid);
  final String _uid;
  @override
  String get uid => _uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeCredential implements UserCredential {
  _FakeCredential(this._user);
  final User _user;
  @override
  User? get user => _user;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService cloud recovery', () {
    test(
      'ensureSignedIn reuses existing user and does not sign in again',
      () async {
        final auth = _CountingAuth();
        final user = _FakeUser('existing-uid');
        auth.currentUser = user;

        final service = AuthService(firebaseAuth: auth);

        final uid1 = await service.ensureSignedIn(maxAttempts: 1);
        expect(uid1, 'existing-uid');
        expect(auth.signInCalls, 0);

        final uid2 = await service.ensureSignedIn(maxAttempts: 1);
        expect(uid2, 'existing-uid');
        expect(auth.signInCalls, 0);
      },
    );

    test(
      'ensureSignedIn signs in once then reuses on subsequent calls',
      () async {
        final auth = _CountingAuth();
        final service = AuthService(firebaseAuth: auth);

        final uid1 = await service.ensureSignedIn(maxAttempts: 1);
        expect(uid1, isNotNull);
        expect(auth.signInCalls, 1);

        final uid2 = await service.ensureSignedIn(maxAttempts: 1);
        expect(uid2, uid1);
        expect(auth.signInCalls, 1);
      },
    );

    test('ensureSignedIn returns null when all attempts fail', () async {
      final auth = _FailingAuth();
      final service = AuthService(firebaseAuth: auth);

      final uid = await service.ensureSignedIn(maxAttempts: 2);
      expect(uid, isNull);
      expect(auth.signInCalls, 2);
    });

    test(
      'signInAnonymously throws StateError when auth is unavailable',
      () async {
        final service = AuthService(firebaseAuth: null);
        expect(() => service.signInAnonymously(), throwsA(isA<StateError>()));
      },
    );

    test('resolveAuth is callable and does not throw', () {
      final auth = _CountingAuth();
      final service = AuthService(firebaseAuth: auth);
      expect(() => service.resolveAuth(), returnsNormally);
    });

    test('uid reflects currentUser', () {
      final auth = _CountingAuth();
      final service = AuthService(firebaseAuth: auth);
      auth.currentUser = _FakeUser('u-1');
      expect(service.uid, 'u-1');
    });
  });
}

class _FailingAuth implements FirebaseAuth {
  int signInCalls = 0;

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInAnonymously() async {
    signInCalls++;
    throw Exception('network error');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
