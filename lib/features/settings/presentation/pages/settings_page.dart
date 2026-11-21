import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/core/services/cloud_connection_service.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../data/repositories/settings_repository.dart';

/// SettingsPage – UI styled to match design system while preserving
/// all backend logic (theme provider, firestore, app storage).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: ListView(
            children: [
              // Dark Mode Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
                  border: Border.all(color: colors.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: colors.primary,
                      size: AppSpacing.iconXl,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark mode',
                            style: AppTypography.h3.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            'Use the app\'s dark-first visual style.',
                            style: AppTypography.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDarkMode,
                      onChanged: (_) async {
                        final auth = context.read<AuthService>();
                        // Captured before the async gap; the app-scoped
                        // messenger stays valid even if this page is disposed.
                        final messenger = ScaffoldMessenger.of(context);

                        final userId = await auth.ensureSignedIn();
                        if (userId == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not sign in. Check your connection and try again.',
                              ),
                            ),
                          );
                          return;
                        }
                        final nextMode = isDarkMode
                            ? ThemeMode.light
                            : ThemeMode.dark;
                        themeProvider.setTheme(nextMode);
                        try {
                          await FirestoreSettingsRepository().saveSettings({
                            'userId': userId,
                            'theme': nextMode == ThemeMode.light
                                ? 'light'
                                : 'dark',
                          });
                        } catch (e) {
                          // Repository already fell back to local storage.
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Theme saved on this device only (offline).',
                              ),
                            ),
                          );
                        }
                      },
                      activeThumbColor: colors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Cloud Sync Card
              Builder(
                builder: (context) {
                  final cloud = context.watch<CloudConnectionService>();
                  final isInitializing = cloud.isInitializing;
                  final statusText = switch (cloud.state) {
                    CloudConnectionState.ready => 'Connected',
                    CloudConnectionState.initializing => 'Connecting…',
                    CloudConnectionState.notInitialized => 'Not connected',
                    CloudConnectionState.unavailable => 'Unavailable',
                    CloudConnectionState.firebaseInitialized =>
                      'Firebase ready, App Check pending',
                    CloudConnectionState.appCheckCompleted =>
                      'Cloud ready, sign-in pending',
                  };
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          cloud.isReady ? Icons.cloud_done : Icons.cloud_off,
                          color: cloud.isReady
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          size: AppSpacing.iconXl,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cloud sync',
                                style: AppTypography.h3.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                statusText,
                                style: AppTypography.caption.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              if (cloud.lastError != null && !cloud.isReady)
                                Text(
                                  cloud.lastError!,
                                  style: AppTypography.caption.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Only offer a retry when one could change something:
                        // a connected service has nothing to retry, and while
                        // connecting the status itself says "Connecting…".
                        if (!cloud.isReady && !isInitializing)
                          TextButton(
                            onPressed: () async {
                              try {
                                await cloud.retry();
                              } catch (_) {
                                // The stage and the error are shown above; the
                                // card is the report, so nothing is rethrown.
                              }
                            },
                            child: const Text('Retry'),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // About Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
                  border: Border.all(color: colors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: AppTypography.h3.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Snoozefriend helps students improve sleep habits through a planner, SQI, and personalized guidance.',
                      style: AppTypography.body.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
