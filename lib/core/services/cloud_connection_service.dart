import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:snoozemate/app/app_check.dart';
import 'package:snoozemate/app/firebase_environment.dart';
import 'package:snoozemate/core/services/auth_service.dart';

/// Cloud connection state.
///
/// `ready` means Firebase was initialized, App Check was activated where
/// required, emulator wiring (where applicable) completed, and authentication
/// succeeded. It does NOT guarantee continuous Firestore/network availability;
/// request failures are still handled by local-first feature code.
enum CloudConnectionState {
  notInitialized,
  initializing,
  unavailable,
  firebaseInitialized,
  appCheckCompleted,
  ready,
}

/// Per-stage status for independent tracking across retries.
enum CloudStageStatus {
  notStarted,
  inProgress,
  succeeded,
  failed,
  notApplicable,
}

bool _stageSatisfied(CloudStageStatus s) =>
    s == CloudStageStatus.succeeded || s == CloudStageStatus.notApplicable;

/// Manages staged, idempotent cloud initialization with concurrent-call
/// protection and independent stage tracking.
class CloudConnectionService extends ChangeNotifier {
  CloudConnectionService({
    required this._authService,
    String Function()? getEnv,
    bool Function()? isDebugBuild,
    bool Function()? emulatorApplicable,
    Future<void> Function()? firebaseInit,
    Future<void> Function()? appCheck,
    Future<void> Function()? firestoreEmulator,
    Future<void> Function()? authEmulator,
    Future<void> Function()? authentication,
  }) : _getEnv = getEnv ?? (() => appEnv),
       _isDebugBuild = isDebugBuild ?? (() => kDebugMode),
       _emulatorApplicableOverride = emulatorApplicable {
    _firebaseInitRunner = firebaseInit ?? _firebaseInit;
    _appCheckRunner = appCheck ?? _appCheck;
    _firestoreEmulatorRunner = firestoreEmulator ?? _firestoreEmulator;
    _authEmulatorRunner = authEmulator ?? _authEmulator;
    _authenticationRunner = authentication ?? _authenticationStage;
  }

  final AuthService _authService;
  final String Function() _getEnv;
  final bool Function() _isDebugBuild;
  final bool Function()? _emulatorApplicableOverride;

  late Future<void> Function() _firebaseInitRunner;
  late Future<void> Function() _appCheckRunner;
  late Future<void> Function() _firestoreEmulatorRunner;
  late Future<void> Function() _authEmulatorRunner;
  late Future<void> Function() _authenticationRunner;

  CloudConnectionState _state = CloudConnectionState.notInitialized;
  String? _lastError;
  String? _failedStage;

  // Independent stage statuses.
  CloudStageStatus _firebaseInitialization = CloudStageStatus.notStarted;
  CloudStageStatus _appCheckActivation = CloudStageStatus.notStarted;
  CloudStageStatus _firestoreEmulatorWiring = CloudStageStatus.notStarted;
  CloudStageStatus _authEmulatorWiring = CloudStageStatus.notStarted;
  CloudStageStatus _authentication = CloudStageStatus.notStarted;

  Future<void>? _inFlight;

  // --- public state ---
  CloudConnectionState get state => _state;
  String? get lastError => _lastError;
  String? get failedStage => _failedStage;
  bool get isReady => _state == CloudConnectionState.ready;
  bool get isInitializing => _state == CloudConnectionState.initializing;

  CloudStageStatus get firebaseInitializationStatus => _firebaseInitialization;
  CloudStageStatus get appCheckActivationStatus => _appCheckActivation;
  CloudStageStatus get firestoreEmulatorWiringStatus =>
      _firestoreEmulatorWiring;
  CloudStageStatus get authEmulatorWiringStatus => _authEmulatorWiring;
  CloudStageStatus get authenticationStatus => _authentication;

  /// Connect (or retry) cloud services. Concurrent calls share one in-flight
  /// future; no duplicate initialization or overlapping stage attempts.
  Future<void> connect() => _run();
  Future<void> retry() => _run();

  Future<void> _run() {
    if (_inFlight != null) return _inFlight!;
    _inFlight = _attempt();
    return _inFlight!;
  }

  Future<void> _attempt() async {
    _state = CloudConnectionState.initializing;
    notifyListeners();

    String? activeStage;
    try {
      // Stage 1: Firebase initialization (with env compatibility check).
      if (_firebaseInitialization != CloudStageStatus.succeeded) {
        activeStage = 'firebaseInitialization';
        _firebaseInitialization = CloudStageStatus.inProgress;
        notifyListeners();
        await _firebaseInitRunner();
        _firebaseInitialization = CloudStageStatus.succeeded;
        notifyListeners();
      }

      // Stage 2: App Check activation.
      if (!_stageSatisfied(_appCheckActivation)) {
        if (!_appCheckApplicable()) {
          _appCheckActivation = CloudStageStatus.notApplicable;
          notifyListeners();
        } else if (_appCheckActivation == CloudStageStatus.failed) {
          activeStage = 'appCheckActivation';
          throw StateError(
            'App Check activation previously failed; safe in-process '
            're-activation is not available. Restart the app to retry.',
          );
        } else {
          activeStage = 'appCheckActivation';
          _appCheckActivation = CloudStageStatus.inProgress;
          notifyListeners();
          await _appCheckRunner();
          _appCheckActivation = CloudStageStatus.succeeded;
          notifyListeners();
        }
      }

      // Stage 3a: Firestore emulator wiring.
      if (!_stageSatisfied(_firestoreEmulatorWiring)) {
        if (!_emulatorApplicable()) {
          _firestoreEmulatorWiring = CloudStageStatus.notApplicable;
          notifyListeners();
        } else {
          activeStage = 'firestoreEmulatorWiring';
          _firestoreEmulatorWiring = CloudStageStatus.inProgress;
          notifyListeners();
          await _firestoreEmulatorRunner();
          _firestoreEmulatorWiring = CloudStageStatus.succeeded;
          notifyListeners();
        }
      }

      // Stage 3b: Auth emulator wiring.
      if (!_stageSatisfied(_authEmulatorWiring)) {
        if (!_emulatorApplicable()) {
          _authEmulatorWiring = CloudStageStatus.notApplicable;
          notifyListeners();
        } else {
          activeStage = 'authEmulatorWiring';
          _authEmulatorWiring = CloudStageStatus.inProgress;
          notifyListeners();
          await _authEmulatorRunner();
          _authEmulatorWiring = CloudStageStatus.succeeded;
          notifyListeners();
        }
      }

      // Stage 4: Authentication.
      if (_authentication != CloudStageStatus.succeeded) {
        activeStage = 'authentication';
        _authentication = CloudStageStatus.inProgress;
        notifyListeners();
        await _authenticationRunner();
        _authentication = CloudStageStatus.succeeded;
        notifyListeners();
      }

      _lastError = null;
      _failedStage = null;
      _state = CloudConnectionState.ready;
    } catch (e) {
      if (activeStage != null) {
        _markStageFailed(activeStage);
      }
      _failedStage = activeStage;
      _lastError = e.toString();
      _state = CloudConnectionState.unavailable;
      rethrow;
    } finally {
      _inFlight = null;
      notifyListeners();
    }
  }

  void _markStageFailed(String stage) {
    switch (stage) {
      case 'firebaseInitialization':
        _firebaseInitialization = CloudStageStatus.failed;
        break;
      case 'appCheckActivation':
        _appCheckActivation = CloudStageStatus.failed;
        break;
      case 'firestoreEmulatorWiring':
        _firestoreEmulatorWiring = CloudStageStatus.failed;
        break;
      case 'authEmulatorWiring':
        _authEmulatorWiring = CloudStageStatus.failed;
        break;
      case 'authentication':
        _authentication = CloudStageStatus.failed;
        break;
    }
  }

  // --- stage implementations ---

  Future<void> _firebaseInit() async {
    final env = _getEnv();
    final expected = firebaseOptionsForEnv(env);

    if (Firebase.apps.isNotEmpty) {
      final existing = Firebase.app();
      if (!_optionsCompatible(existing.options, expected)) {
        throw StateError(
          'Firebase already initialized with incompatible environment/options '
          'for APP_ENV=$env. Refusing to mix configurations.',
        );
      }
      // Compatible: treat as satisfied, do not initialize again.
      return;
    }

    await Firebase.initializeApp(options: expected);
  }

  bool _optionsCompatible(FirebaseOptions a, FirebaseOptions b) {
    return a.projectId == b.projectId &&
        a.appId == b.appId &&
        a.apiKey == b.apiKey &&
        a.messagingSenderId == b.messagingSenderId;
  }

  bool _appCheckApplicable() {
    // Current implementation activates App Check for all supported builds.
    return true;
  }

  Future<void> _appCheck() async {
    await activateAppCheck(env: _getEnv(), isDebugBuild: _isDebugBuild());
  }

  bool _emulatorApplicable() {
    if (_emulatorApplicableOverride != null) {
      return _emulatorApplicableOverride();
    }
    return _isDebugBuild() &&
        const bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  }

  Future<void> _firestoreEmulator() async {
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  }

  Future<void> _authEmulator() async {
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  }

  Future<void> _authenticationStage() async {
    _authService.resolveAuth();
    await _authService.ensureSignedIn(maxAttempts: 1);
  }
}
