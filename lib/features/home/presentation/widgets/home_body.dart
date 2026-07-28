import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 5) return "Still up?";
    if (h < 12) return "Good morning";
    if (h < 18) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 24),
        _buildTonightsSuggestionCard(context),
        const SizedBox(height: 20),
        _buildFeatureGrid(context),
        const SizedBox(height: 24),
        _buildLatestScoreSection(context),
      ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greet()},',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            Row(
              children: [
                Text(
                  'Welcome',
                  style: GoogleFonts.sora(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('🌙', style: TextStyle(fontSize: 24)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTonightsSuggestionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.35),
            AppColors.primary.withValues(alpha: 0.20),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                "Tonight's suggestion",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Plan tonight',
            style: GoogleFonts.sora(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us when you need to wake up.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.60),
                    blurRadius: 30,
                    spreadRadius: -12,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open Sleep Planner',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryForeground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primaryForeground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _FeatureCard(
              icon: Icons.nightlight_round,
              iconColor: AppColors.primary,
              title: 'Sleep Planner',
              description: 'Find your best bedtime',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FeatureCard(
              icon: Icons.checklist_rtl_rounded,
              iconColor: AppColors.accent,
              title: 'Sleep Quality',
              description: 'Take the assessment',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestScoreSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest score',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
              child: Text(
                'View history',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Take your first assessment — under 3 minutes.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.foreground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
