import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

/// HomeBody - Main dashboard following Lovable UI structure
/// Primary reference: sleep-wise-plan/src/routes/home.tsx
class HomeBody extends StatelessWidget {
  const HomeBody({super.key, required this.context});

  final BuildContext context;

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 5) return "Still up?";
    if (h < 12) return "Good morning";
    if (h < 18) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.px,
          vertical: AppSpacing.py,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting, name, moon emoji, and settings chip
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),

            // Tonight's suggestion card with gradient background
            _buildTonightsSuggestionCard(context),
            const SizedBox(height: AppSpacing.md),

            // 2-column grid with Sleep Planner and Sleep Quality
            _buildFeatureGrid(context),
            const SizedBox(height: AppSpacing.lg),

            // Latest score section
            _buildLatestScoreSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         // Greeting with name and moon emoji
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               '${_greet()},',
               style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
             ),
             Row(
               children: [
                 Text(
                   'Welcome',
                   style: AppTypography.h1.copyWith(color: AppColors.foreground),
                 ),
                 const SizedBox(width: 4),
                 const Text('🌙', style: TextStyle(fontSize: 28)),
               ],
             ),
           ],
         ),
        // Settings icon
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.settings);
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(
              Icons.settings,
              size: AppSpacing.iconMd,
              color: AppColors.foreground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTonightsSuggestionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppSpacing.radius3xl,
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.35),
            AppColors.primary.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sparkles icon and label
          Row(
            children: [
              Icon(Icons.auto_awesome, size: AppSpacing.iconSm, color: AppColors.mutedForeground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "Tonight's suggestion",
                style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Suggestion text
          Text(
            'Plan tonight',
            style: AppTypography.displayMedium.copyWith(color: AppColors.foreground),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tell us when you need to wake up.',
            style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.md),
          // Open Sleep Planner button
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppSpacing.radiusXl,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open Sleep Planner',
                    style: AppTypography.button.copyWith(color: AppColors.primaryForeground),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward, size: AppSpacing.iconMd, color: AppColors.primaryForeground),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sleep Planner card
        Expanded(
          child: _FeatureCard(
            icon: Icons.nightlight_round,
            iconColor: AppColors.primary,
            title: 'Sleep Planner',
            description: 'Find your best bedtime',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Sleep Quality card
        Expanded(
          child: _FeatureCard(
            icon: Icons.checklist,
            iconColor: AppColors.accent,
            title: 'Sleep Quality',
            description: 'Take the assessment',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestScoreSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "View history" link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest score',
              style: AppTypography.h3.copyWith(color: AppColors.foreground),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
              child: Text(
                'View history',
                style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Score card placeholder (no data state)
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppSpacing.radiusLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Take your first assessment — under 3 minutes.',
                    style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.arrow_forward, size: AppSpacing.iconMd, color: AppColors.mutedForeground),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// _FeatureCard - Internal card widget for the 2-column feature grid
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSpacing.iconLg, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.foreground),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}