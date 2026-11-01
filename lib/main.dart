import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart'; // provides the shared `appStorage` global
import 'core/services/storage_service.dart';
import 'core/providers/theme_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before any Firebase services are used
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the shared appStorage global (declared in app/app.dart) once,
  // so pages (settings, sleep quality) can persist theme/history locally.
  final storage = await StorageService.create();
  appStorage = storage;
  final themeProvider = ThemeProvider(storageService: storage);

  runApp(
    ChangeNotifierProvider(
      create: (context) => themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SnoozefriendApp();
  }
}
