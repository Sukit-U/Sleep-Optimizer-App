import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app/app.dart'; // provides the shared `appStorage` global
import 'core/services/storage_service.dart';
import 'core/services/auth_service.dart';
import 'core/providers/theme_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before any Firebase services are used. A failure
  // (e.g. missing platform config) must not blank-screen the app; pages
  // surface their own error states instead.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Local development: run against the Firestore/Auth emulators, e.g.
    //   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
    // (emulator ports: Firestore 8080, Auth 9099).
    if (kDebugMode && const bool.fromEnvironment('USE_FIREBASE_EMULATOR')) {
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Authenticate anonymously before anything touches Firestore. Failed
  // attempts are retried with a delay (transient offline, provider enabled
  // late); if every attempt fails the app still boots and pages surface
  // their own recovery via ensureSignedIn on the next save.
  final authService = AuthService();
  await authService.ensureSignedIn();

  // Initialize the shared appStorage global (declared in app/app.dart) once,
  // so pages (settings, sleep quality) can persist theme/history locally.
  final storage = await StorageService.create();
  appStorage = storage;
  final themeProvider = ThemeProvider(storageService: storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        Provider<AuthService>.value(value: authService),
      ],
      child: const SnoozefriendApp(),
    ),
  );
}
