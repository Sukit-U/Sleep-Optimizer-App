import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/core/services/cloud_connection_service.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/features/settings/presentation/providers/settings_sync_service.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/services/storage_service.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

import '../../../../core/providers/theme_provider.dart';

/// SettingsPage – UI styled to match design system while preserving
/// all backend logic (theme provider, firestore, app storage).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  SettingsSyncService? _syncService;
  SettingsSyncState _syncState = SettingsSyncState.idle;

  @override
  void initState() {
    super.initState();
    _recover();
  }

  Future<void> _recover() async {
    try {
      final auth = AuthService();
      final userId = await auth.ensureSignedIn();
      if (userId == null || !mounted) return;
      _syncService ??= SettingsSyncService(userId: userId);
      await _syncService!.recover();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPageTitle),
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
                            l10n.settingsDarkModeTitle,
                            style: AppTypography.h3.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            l10n.settingsDarkModeDesc,
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
                        final messenger = ScaffoldMessenger.of(context);

                        final nextMode = isDarkMode
                            ? ThemeMode.light
                            : ThemeMode.dark;

                        // Apply and persist locally immediately (offline-safe).
                        themeProvider.setTheme(nextMode);
                        _syncState = SettingsSyncState.pending;
                        if (mounted) setState(() {});
                        final storage = await StorageService.create();
                        await storage.saveTheme(
                          nextMode == ThemeMode.light ? 'light' : 'dark',
                        );
                        if (mounted) setState(() {});

                        // Best-effort cloud sync in the background.
                        final userId = await auth.ensureSignedIn();
                        if (userId == null) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.historySnackSignInFailed),
                              ),
                            );
                          }
                          return;
                        }
                        _syncService ??= SettingsSyncService(userId: userId);
                        await _syncService!.saveTheme(
                          nextMode == ThemeMode.light ? 'light' : 'dark',
                        );
                        if (mounted) setState(() {});
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
                  final syncState = _syncService?.state ?? _syncState;
                  final statusText = (syncState != SettingsSyncState.idle)
                      ? (syncState == SettingsSyncState.pending ? 'รอซิงค์' : syncState == SettingsSyncState.syncing ? 'กำลังซิงค์' : syncState == SettingsSyncState.synced ? 'ซิงค์แล้ว' : 'ซิงค์ไม่สำเร็จ')
                      : switch (cloud.state) {
                    CloudConnectionState.ready => l10n.statusConnected,
                    CloudConnectionState.initializing => l10n.statusConnecting,
                    CloudConnectionState.notInitialized =>
                      l10n.statusNotConnected,
                    CloudConnectionState.unavailable => l10n.statusUnavailable,
                    CloudConnectionState.firebaseInitialized =>
                      l10n.statusFirebaseReadyAppCheckPending,
                    CloudConnectionState.appCheckCompleted =>
                      l10n.statusCloudReadySignInPending,
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
                                l10n.settingsCloudSyncTitle,
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
                                  l10n.settingsCloudError,
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
                            child: Text(l10n.settingsBtnRetry),
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
                      l10n.settingsAboutTitle,
                      style: AppTypography.h3.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.settingsAboutDesc,
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











