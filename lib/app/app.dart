import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import 'router.dart';

StorageService? appStorage;

class SleepOptimizerApp extends StatelessWidget {
  const SleepOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sleep Optimizer',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
initialRoute: '/splash',
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
