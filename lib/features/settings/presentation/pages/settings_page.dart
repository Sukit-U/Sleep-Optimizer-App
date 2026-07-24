import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (context, mode, child) {
            final isDarkMode = mode == ThemeMode.dark;

            return ListView(
              children: [
                Card(
                  child: SwitchListTile(
                    title: const Text('Dark mode'),
                    subtitle: const Text('Use the app’s dark-first visual style.'),
                    value: isDarkMode,
                    onChanged: (_) async {
                      final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                      appThemeMode.value = nextMode;
                      await FirestoreSettingsRepository().saveSettings(
                        {
                          'userId': 'local-user',
                          'theme': nextMode == ThemeMode.light ? 'light' : 'dark',
                        },
                      );
                      await appStorage?.saveTheme(nextMode == ThemeMode.light ? 'light' : 'dark');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    title: Text('About'),
                    subtitle: Text(
                      'Sleep Optimizer helps students improve sleep habits through a planner, SQI, and personalized guidance.',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
