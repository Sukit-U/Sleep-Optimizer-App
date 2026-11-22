import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';
import 'package:snoozemate/shared/formatters/history_date_formatter.dart';

/// A card displaying a sleep plan in the history list.
///
/// Shows bedtime, wake time, cycles, date, and a delete button.
class HistorySleepPlanCard extends StatelessWidget {
  final SleepPlan plan;
  final VoidCallback? onDelete;

  const HistorySleepPlanCard({super.key, required this.plan, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final firstBedtime = plan.suggestedBedtimes.isNotEmpty
        ? plan.suggestedBedtimes.first
        : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Icon(
            Icons.nightlight_round,
            size: AppSpacing.iconMd,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstBedtime → ${formatHistoryTime(plan.wakeUpTime, l10n)}',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppSpacing.spacingXs),
                Text(
                  '${l10n.plannerCycles(plan.sleepCycles)} · ${formatHistoryDate(plan.createdAt, l10n)}',
                  style: AppTypography.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.delete_outline,
                  size: AppSpacing.iconMd,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
