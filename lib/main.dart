import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/services/storage_service.dart';
import 'core/providers/theme_provider.dart';

late StorageService appStorage;
late ValueNotifier<ThemeMode> appThemeMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  appStorage = await StorageService.create();
  appThemeMode = ValueNotifier<ThemeMode>(
    appStorage.loadTheme() == 'light' ? ThemeMode.light : ThemeMode.dark,
  );

  final themeProvider = ThemeProvider(storageService: appStorage);

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
    return const SleepOptimizerApp();
  }
}
