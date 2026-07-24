import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  appStorage = await StorageService.create();
  final savedTheme = appStorage?.loadTheme();
  if (savedTheme == 'light') {
    appThemeMode.value = ThemeMode.light;
  } else {
    appThemeMode.value = ThemeMode.dark;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SleepOptimizerApp();
  }
}
