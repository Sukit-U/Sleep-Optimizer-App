import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';

/// A card displaying a sleep plan in the history list.
///
/// Shows bedtime, wake time, cycles, date, and a delete button.
class HistorySleepPlanCard extends StatelessWidget {
  final SleepPlan plan;
  final VoidCallback? onDelete;

  const HistorySleepPlanCard({
    super.key,
    required this.plan,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstBedtime = plan.suggestedBedtimes.isNotEmpty
        ? plan.suggestedBedtimes.first
        : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconXl,
            height: AppSpacing.iconXl,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
            ),
            child: Icon(
              Icons.nightlight_round,
              size: AppSpacing.iconMd,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstBedtime → ${_formatTime(plan.wakeUpTime)}',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppSpacing.spacingXs),
                Text(
                  '${plan.sleepCycles} cycles · ${_formatDate(plan.createdAt)}',
                  style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays == 0) return 'Today, ${_formatTime(dateTime)}';
    if (difference.inDays == 1) return 'Yesterday, ${_formatTime(dateTime)}';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
