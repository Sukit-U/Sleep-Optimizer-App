import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/theme_provider.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/error_state_widget.dart';
import 'firebase_environment.dart';
import 'app.dart';

/// Everything the widget tree needs that can only exist after booting.
class AppDependencies {
  const AppDependencies({required this.authService, required this.themeProvider});

  final AuthService authService;
  final ThemeProvider themeProvider;
}

/// Runs [boot] before building the app and, when it fails, shows a readable
/// error with a Retry action instead of a blank screen or a half-initialised
/// Firebase app.
class AppBootstrap extends StatefulWidget {
  /// Injectable for tests; production uses [_bootFirebase].
  final Future<AppDependencies> Function()? boot;

  const AppBootstrap({super.key, this.boot});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  AppDependencies? _dependencies;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final dependencies = await (widget.boot ?? _bootFirebase)();
      if (!mounted) return;
      setState(() {
        _dependencies = dependencies;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _boot();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    if (dependencies == null) {
      final error = _error;
      return MaterialApp(
        title: 'Sleep Optimizer',
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SafeArea(
            // Booting is not a failure: show progress until boot actually
            // throws, otherwise a slow start flashes "couldn't start".
            child: error == null
                ? const Center(child: CircularProgressIndicator())
                : ErrorStateWidget(
                    message: "Snoozefriend couldn't start",
                    detail: '$error',
                    onRetry: _retry,
                  ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dependencies.themeProvider),
        Provider<AuthService>.value(value: dependencies.authService),
      ],
      child: const SnoozefriendApp(),
    );
  }
}

Future<AppDependencies> _bootFirebase() async {
  // The Firebase project is fixed at build time: --dart-define=APP_ENV=dev|prod
  // (default dev) picks lib/firebase_options_dev.dart or firebase_options.dart.
  await Firebase.initializeApp(options: firebaseOptionsForEnv(appEnv));

  // Local development: run against the Firestore/Auth emulators, e.g.
  //   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
  // (emulator ports: Firestore 8080, Auth 9099).
  if (kDebugMode && const bool.fromEnvironment('USE_FIREBASE_EMULATOR')) {
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  }

  // Authenticate anonymously before anything touches Firestore. AuthService
  // retries internally; a total failure surfaces through the error screen.
  final authService = AuthService();
  await authService.ensureSignedIn();

  // Shared appStorage global (declared in app/app.dart) so pages can persist
  // theme/history locally.
  final storage = await StorageService.create();
  appStorage = storage;

  return AppDependencies(
    authService: authService,
    themeProvider: ThemeProvider(storageService: storage),
  );
}
