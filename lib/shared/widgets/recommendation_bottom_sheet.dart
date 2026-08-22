import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/models/recommendation_model.dart';

/// Shows a bottom sheet with a list of recommendations.
///
/// [recs] is the list of recommendations to display.
/// Pass empty list to show "no recommendations" state.
void showRecommendationSheet(
  BuildContext context, {
  required List<Recommendation> recs,
}) {
  final colors = Theme.of(context).colorScheme;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (ctx, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.px),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radius2xl),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: AppSpacing.iconMd, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Recommendations',
                  style: AppTypography.h2.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (recs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No recommendations recorded for this assessment.',
                    style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recs.length,
                  itemBuilder: (ctx, i) => _RecommendationItem(rec: recs[i]),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _RecommendationItem extends StatelessWidget {
  final Recommendation rec;
  const _RecommendationItem({required this.rec});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: AppSpacing.cardShadow,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Text(
                  rec.priority,
                  style: AppTypography.small.copyWith(color: colors.primary),
                ),
              ),
              Text(
                rec.factor,
                style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            rec.title,
            style: AppTypography.h3.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            rec.description,
            style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Action: ${rec.action}',
            style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
