import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/core/presentation/widgets/app_bar.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

import '../../../../app/app.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/repositories/settings_repository.dart';

/// SettingsPage – UI styled to match design system while preserving
/// all backend logic (theme provider, firestore, app storage).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: const AppBarWidget(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.px,
            vertical: AppSpacing.py,
          ),
          child: ListView(
            children: [
              // Screen Title
              Text(
                'Settings',
                style: AppTypography.h1.copyWith(color: AppColors.foreground),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Dark Mode Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: AppSpacing.cardShadow,
                    offset: const Offset(0, 2),
                  )],
                ),
                child: Row(
                  children: [
                    Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.primary,
                      size: AppSpacing.iconXl,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark mode',
                            style: AppTypography.h3.copyWith(color: AppColors.foreground),
                          ),
                          Text(
                            'Use the app\'s dark-first visual style.',
                            style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDarkMode,
                      onChanged: (_) async {
                        final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                        themeProvider.setTheme(nextMode);
                        await FirestoreSettingsRepository().saveSettings(
                          {
                            'userId': 'local-user',
                            'theme': nextMode == ThemeMode.light ? 'light' : 'dark',
                          },
                        );
                        await appStorage?.saveTheme(nextMode == ThemeMode.light ? 'light' : 'dark');
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // About Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: AppSpacing.cardShadow,
                    offset: const Offset(0, 2),
                  )],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: AppTypography.h3.copyWith(color: AppColors.foreground),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sleep Optimizer helps students improve sleep habits through a planner, SQI, and personalized guidance.',
                      style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
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