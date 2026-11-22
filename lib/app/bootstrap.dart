import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/theme_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/services/auth_service.dart';
import '../core/services/cloud_connection_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/error_state_widget.dart';
import 'app.dart';
import 'firebase_environment.dart';

/// Everything the widget tree needs that can only exist after booting.
class AppDependencies {
  const AppDependencies({
    required this.authService,
    required this.themeProvider,
    required this.localeProvider,
    required this.cloudConnectionService,
  });

  final AuthService authService;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  final CloudConnectionService cloudConnectionService;
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
        title: 'Snozemate',
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SafeArea(
            // Booting is not a failure: show progress until boot actually
            // throws, otherwise a slow start flashes "couldn't start".
            child: error == null
                ? const Center(child: CircularProgressIndicator())
                : ErrorStateWidget(
                    message: 'Snoozemate เริ่มต้นไม่ได้',
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
        ChangeNotifierProvider.value(value: dependencies.localeProvider),
        Provider<AuthService>.value(value: dependencies.authService),
        ChangeNotifierProvider<CloudConnectionService>.value(
          value: dependencies.cloudConnectionService,
        ),
      ],
      child: const SnoozefriendApp(),
    );
  }
}

/// Boots the app: local dependencies first, then the cloud as a best-effort
/// step.
///
/// Local state ([StorageService], [ThemeProvider]) is created first and is not
/// caught: without it there is no app to run. The cloud sequence
/// ([initializeCloud]) runs afterwards inside a try/catch, so a Firebase init
/// failure, App Check activation error, or offline first launch leaves the app
/// running with a usable [AuthService] whose [AuthService.uid] is `null`.
///
/// [createAuthService] and [createCloudConnectionService] are injectable for
/// tests.
Future<AppDependencies> bootDependencies({
  required Future<void> Function(AuthService authService) initializeCloud,
  AuthService Function()? createAuthService,
  CloudConnectionService Function(AuthService authService)?
  createCloudConnectionService,
}) async {
  // Shared appStorage global (declared in app/app.dart) so pages can persist
  // theme/history locally. Required for the app to run at all.
  final storage = await StorageService.create();
  appStorage = storage;
  final authService = (createAuthService ?? AuthService.new)();

  final cloudConnectionService = createCloudConnectionService != null
      ? createCloudConnectionService(authService)
      : CloudConnectionService(authService: authService);

  try {
    await initializeCloud(authService);
  } catch (error) {
    // Cloud is optional. Log and continue: local features must still work.
    debugPrint('Cloud services unavailable; continuing offline: $error');
  }

  return AppDependencies(
    authService: authService,
    themeProvider: ThemeProvider(storageService: storage),
    localeProvider: LocaleProvider(storageService: storage)..loadLocale(),
    cloudConnectionService: cloudConnectionService,
  );
}

Future<AppDependencies> _bootFirebase() {
  final authService = AuthService();
  final cloudConnectionService = CloudConnectionService(
    authService: authService,
    getEnv: () => appEnv,
    isDebugBuild: () => kDebugMode,
  );
  return bootDependencies(
    createAuthService: () => authService,
    createCloudConnectionService: (_) => cloudConnectionService,
    initializeCloud: (auth) async {
      // Single cloud-init path: staged, idempotent, runs once.
      await cloudConnectionService.connect();
    },
  );
}

