import 'package:flutter/material.dart';

import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.dark);
StorageService? appStorage;

class SleepOptimizerApp extends StatelessWidget {
  const SleepOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Sleep Optimizer',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
