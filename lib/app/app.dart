import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';

/// Shared storage instance, initialized once in `main()` (see lib/main.dart).
/// Pages import this global to persist theme and history locally.
StorageService? appStorage;

class SnoozefriendApp extends StatelessWidget {
  const SnoozefriendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: localeProvider.locale.languageCode == 'th'
              ? 'Snoozemate'
              : 'Snoozemate',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('th')],
          locale: const Locale('th'),
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
