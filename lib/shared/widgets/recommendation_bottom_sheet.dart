import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
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
  int unavailableCount = 0,
}) {
  final colors = Theme.of(context).colorScheme;
  final l10n = context.l10n;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (ctx, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          // The sheet body is the page; the cards on it are the raised surfaces.
          color: Theme.of(ctx).scaffoldBackgroundColor,
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
            Text(
              l10n.recRecommendations,
              style: AppTypography.h2.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (recs.isEmpty && unavailableCount == 0)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.recBottomSheetNoneRecorded,
                    style: AppTypography.body.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (recs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.recBottomSheetSomeUnavailable,
                    style: AppTypography.body.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recs.length,
                  itemBuilder: (ctx, i) => _RecommendationItem(rec: recs[i], l10n: l10n),
                ),
              ),
              if (unavailableCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.recBottomSheetSomeUnavailable,
                    style: AppTypography.body.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _RecommendationItem extends StatelessWidget {
  final Recommendation rec;
  final AppLocalizations l10n;
  const _RecommendationItem({required this.rec, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        border: Border.all(color: colors.outline),
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
                  l10n.recPriorityLabel(rec.priority) ?? 'ความสำคัญ',
                  style: AppTypography.small.copyWith(color: colors.primary),
                ),
              ),
              Text(
                l10n.recFactorLabel(rec.factor) ?? 'ปัจจัย',
                style: AppTypography.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
           Text(
             l10n.recTitleFor(rec.factor) ?? rec.title,
             style: AppTypography.h3.copyWith(color: colors.onSurface),
           ),
          const SizedBox(height: AppSpacing.xs),
           Text(
             l10n.recDescriptionFor(rec.factor) ?? rec.description,
             style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
           ),
          const SizedBox(height: AppSpacing.md),
          Text(
             l10n.recAction(l10n.recActionFor(rec.factor) ?? rec.action),
            style: AppTypography.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

