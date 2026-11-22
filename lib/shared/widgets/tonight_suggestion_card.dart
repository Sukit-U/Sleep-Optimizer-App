import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';

/// A CTA card for the home screen suggesting to plan tonight's sleep.
///
/// Quiet by design: a surface, a heading, one sentence and one button. The
/// bedtime planner is the app's main action, so it does not need decoration.
class TonightSuggestionCard extends StatelessWidget {
  final VoidCallback? onPlanTonight;

  const TonightSuggestionCard({super.key, this.onPlanTonight});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tonightCardHeading,
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tonightCardTitle,
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.tonightCardDescription,
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 15,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPlanTonight,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(l10n.tonightCardButton),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
