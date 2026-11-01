import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

/// An empty state card with a label and call-to-action button.
///
/// Used when a list has no items to display.
class EmptyStateCard extends StatelessWidget {
  final String label;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;

  const EmptyStateCard({
    super.key,
    required this.label,
    required this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [
          BoxShadow(
            blurRadius: AppSpacing.cardShadow,
            color: colors.shadow.withValues(alpha: 0.45),
            offset: Offset(0, AppSpacing.defaultSpacing - 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onCtaPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
              ),
              child: Text(
                ctaLabel,
                style: AppTypography.button.copyWith(color: colors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
