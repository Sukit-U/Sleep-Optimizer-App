import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

/// A reusable card widget for the Home screen.
/// Displays an icon, title and description and navigates to the given route.
class HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;

  const HomeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: colors.outline, width: 1),
          boxShadow: [BoxShadow(blurRadius: AppSpacing.cardShadow, color: colors.shadow.withValues(alpha: 0.45), offset: Offset(0, AppSpacing.defaultSpacing - 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.iconXxl, color: colors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.h2.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}