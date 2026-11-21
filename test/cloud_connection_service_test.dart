import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/core/services/cloud_connection_service.dart';

class _FakeAuth implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  void resolveAuth() {}

  @override
  Future<String?> ensureSignedIn({int maxAttempts = 3}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudConnectionService', () {
    test('reaches ready when all stages succeed', () async {
      final svc = CloudConnectionService(
        authService: _FakeAuth(),
        getEnv: () => 'dev',
        isDebugBuild: () => false,
        firebaseInit: () async {},
        appCheck: () async {},
        firestoreEmulator: () async {},
        authEmulator: () async {},
        authentication: () async {},
      );

      await svc.connect();
      expect(svc.state, CloudConnectionState.ready);
      expect(svc.isReady, isTrue);
    });

    test(
      'App Check exception containing "already" and "provider" is NOT success',
      () async {
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => false,
          firebaseInit: () async {},
          appCheck: () async {
            throw Exception('provider already invalid');
          },
          firestoreEmulator: () async {},
          authEmulator: () async {},
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        expect(svc.state, CloudConnectionState.unavailable);
        expect(svc.appCheckActivationStatus, CloudStageStatus.failed);
        expect(svc.isReady, isFalse);
      },
    );

    test(
      'App Check exception containing "already" and "activation" is NOT success',
      () async {
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => false,
          firebaseInit: () async {},
          appCheck: () async {
            throw Exception('already activated');
          },
          firestoreEmulator: () async {},
          authEmulator: () async {},
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        expect(svc.state, CloudConnectionState.unavailable);
        expect(svc.appCheckActivationStatus, CloudStageStatus.failed);
        expect(svc.isReady, isFalse);
      },
    );

    test(
      'ambiguous App Check failure leaves stage unsatisfied and ready unreachable',
      () async {
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => false,
          firebaseInit: () async {},
          appCheck: () async {
            throw Exception('platform error 123');
          },
          firestoreEmulator: () async {},
          authEmulator: () async {},
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        expect(svc.appCheckActivationStatus, CloudStageStatus.failed);
        expect(svc.state, CloudConnectionState.unavailable);
        expect(svc.isReady, isFalse);
      },
    );

    test(
      'ready cannot be reached after unverified App Check failure on retry',
      () async {
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => false,
          firebaseInit: () async {},
          appCheck: () async {
            throw Exception('app check failed');
          },
          firestoreEmulator: () async {},
          authEmulator: () async {},
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        await expectLater(svc.retry(), throwsA(isA<StateError>()));
        expect(svc.state, CloudConnectionState.unavailable);
        expect(svc.appCheckActivationStatus, CloudStageStatus.failed);
        expect(svc.isReady, isFalse);
      },
    );

    test(
      'verified App Check success is not repeated during later retries',
      () async {
        int appCheckCalls = 0;
        int authCalls = 0;
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => false,
          firebaseInit: () async {},
          appCheck: () async {
            appCheckCalls++;
          },
          firestoreEmulator: () async {},
          authEmulator: () async {},
          authentication: () async {
            authCalls++;
            if (authCalls == 1) throw Exception('auth failed');
          },
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        await svc.retry();
        expect(svc.state, CloudConnectionState.ready);
        expect(appCheckCalls, 1, reason: 'App Check must not repeat');
        expect(authCalls, 2);
      },
    );

    test(
      'previously successful Firebase init preserved after App Check failure',
      () async {
        int firebaseCalls = 0;
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => false,
          firebaseInit: () async {
            firebaseCalls++;
          },
          appCheck: () async {
            throw Exception('app check failed');
          },
          firestoreEmulator: () async {},
          authEmulator: () async {},
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        expect(svc.firebaseInitializationStatus, CloudStageStatus.succeeded);
        expect(svc.appCheckActivationStatus, CloudStageStatus.failed);

        await expectLater(svc.retry(), throwsA(isA<StateError>()));
        expect(firebaseCalls, 1, reason: 'Firebase init must not repeat');
        expect(svc.firebaseInitializationStatus, CloudStageStatus.succeeded);
        expect(svc.appCheckActivationStatus, CloudStageStatus.failed);
      },
    );

    test('concurrent connect calls share one in-flight future', () async {
      final gate = Completer<void>();
      int firebaseCalls = 0;
      final svc = CloudConnectionService(
        authService: _FakeAuth(),
        getEnv: () => 'dev',
        isDebugBuild: () => false,
        firebaseInit: () async {
          firebaseCalls++;
          await gate.future;
        },
        appCheck: () async {},
        firestoreEmulator: () async {},
        authEmulator: () async {},
        authentication: () async {},
      );

      final f1 = svc.connect();
      final f2 = svc.connect();
      final f3 = svc.retry();

      expect(identical(f1, f2), isTrue);
      expect(identical(f1, f3), isTrue);

      gate.complete();
      await Future.wait([f1, f2, f3]);

      expect(firebaseCalls, 1);
      expect(svc.state, CloudConnectionState.ready);
    });

    test(
      'partial recovery: auth failure then retry skips earlier stages',
      () async {
        int firebaseCalls = 0;
        int appCheckCalls = 0;
        int fsEmuCalls = 0;
        int authEmuCalls = 0;
        int authCalls = 0;
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => true,
          emulatorApplicable: () => true,
          firebaseInit: () async {
            firebaseCalls++;
          },
          appCheck: () async {
            appCheckCalls++;
          },
          firestoreEmulator: () async {
            fsEmuCalls++;
          },
          authEmulator: () async {
            authEmuCalls++;
          },
          authentication: () async {
            authCalls++;
            if (authCalls == 1) throw Exception('auth failed');
          },
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        expect(svc.authenticationStatus, CloudStageStatus.failed);

        await svc.retry();
        expect(svc.state, CloudConnectionState.ready);
        expect(firebaseCalls, 1);
        expect(appCheckCalls, 1);
        expect(fsEmuCalls, 1);
        expect(authEmuCalls, 1);
        expect(authCalls, 2);
      },
    );

    test(
      'Firestore emulator failure then retry skips it on success of retry',
      () async {
        int fsEmuCalls = 0;
        int authEmuCalls = 0;
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => true,
          emulatorApplicable: () => true,
          firebaseInit: () async {},
          appCheck: () async {},
          firestoreEmulator: () async {
            fsEmuCalls++;
            if (fsEmuCalls == 1) throw Exception('fs emu failed');
          },
          authEmulator: () async {
            authEmuCalls++;
          },
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        expect(svc.firestoreEmulatorWiringStatus, CloudStageStatus.failed);
        // auth emulator not attempted in failed attempt
        expect(authEmuCalls, 0);

        await svc.retry();
        expect(svc.state, CloudConnectionState.ready);
        expect(fsEmuCalls, 2);
        expect(authEmuCalls, 1);
      },
    );

    test(
      'Auth emulator failure then retry skips Firestore emulator sub-stage',
      () async {
        int fsEmuCalls = 0;
        int authEmuCalls = 0;
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => true,
          emulatorApplicable: () => true,
          firebaseInit: () async {},
          appCheck: () async {},
          firestoreEmulator: () async {
            fsEmuCalls++;
          },
          authEmulator: () async {
            authEmuCalls++;
            if (authEmuCalls == 1) throw Exception('auth emu failed');
          },
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        expect(svc.firestoreEmulatorWiringStatus, CloudStageStatus.succeeded);
        expect(svc.authEmulatorWiringStatus, CloudStageStatus.failed);

        await svc.retry();
        expect(svc.state, CloudConnectionState.ready);
        expect(fsEmuCalls, 1, reason: 'Firestore emulator must not repeat');
        expect(authEmuCalls, 2);
      },
    );

    test('emulator wiring notApplicable when not in emulator mode', () async {
      final svc = CloudConnectionService(
        authService: _FakeAuth(),
        getEnv: () => 'dev',
        isDebugBuild: () => false,
        firebaseInit: () async {},
        appCheck: () async {},
        firestoreEmulator: () async {
          throw StateError('should not be called');
        },
        authEmulator: () async {
          throw StateError('should not be called');
        },
        authentication: () async {},
      );

      await svc.connect();
      expect(svc.state, CloudConnectionState.ready);
      expect(svc.firestoreEmulatorWiringStatus, CloudStageStatus.notApplicable);
      expect(svc.authEmulatorWiringStatus, CloudStageStatus.notApplicable);
    });

    test('environment mismatch failure is reported and retryable', () async {
      int calls = 0;
      final svc = CloudConnectionService(
        authService: _FakeAuth(),
        getEnv: () => 'dev',
        isDebugBuild: () => false,
        firebaseInit: () async {
          calls++;
          throw StateError(
            'Firebase already initialized with incompatible environment/options '
            'for APP_ENV=dev. Refusing to mix configurations.',
          );
        },
        appCheck: () async {},
        firestoreEmulator: () async {},
        authEmulator: () async {},
        authentication: () async {},
      );

      await expectLater(svc.connect(), throwsA(isA<StateError>()));
      expect(svc.state, CloudConnectionState.unavailable);
      expect(svc.failedStage, 'firebaseInitialization');
      expect(svc.lastError, contains('Refusing to mix configurations'));

      // A later retry still attempts stage 1 again (recoverable if context changes).
      await expectLater(svc.retry(), throwsA(isA<StateError>()));
      expect(calls, 2);
    });

    test(
      'retry after failure clears in-flight future and allows new attempt',
      () async {
        int calls = 0;
        final svc = CloudConnectionService(
          authService: _FakeAuth(),
          getEnv: () => 'dev',
          isDebugBuild: () => false,
          firebaseInit: () async {
            calls++;
            if (calls == 1) throw Exception('boom');
          },
          appCheck: () async {},
          firestoreEmulator: () async {},
          authEmulator: () async {},
          authentication: () async {},
        );

        await expectLater(svc.connect(), throwsA(isA<Exception>()));
        await svc.retry();
        expect(svc.state, CloudConnectionState.ready);
        expect(calls, 2);
      },
    );
  });
}
