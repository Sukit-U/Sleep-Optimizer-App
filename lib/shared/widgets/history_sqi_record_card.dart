import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

/// A card displaying an SQI record in the history list.
///
/// Shows score, quality level, date, and a delete button.
class SQIRecordCard extends StatelessWidget {
  final SQIRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SQIRecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: AppSpacing.iconMd,
              color: colors.secondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${record.sqiScore}',
                        style: AppTypography.h2.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '· ${l10n.sleepQualityLevel(record.sleepQualityLevel)}',
                        style: AppTypography.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacingXs),
                  Text(
                    _formatDate(record.createdAt, l10n),
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
      ),
    );
  }

  String _formatDate(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays == 0) {
      return l10n.historyDateToday(_formatTime(dateTime, l10n));
    }
    if (difference.inDays == 1) {
      return l10n.historyDateYesterday(_formatTime(dateTime, l10n));
    }
    if (difference.inDays < 7) {
      return l10n.historyDateDaysAgo(difference.inDays);
    }
    return l10n.formatDateFull(dateTime.day, dateTime.month, dateTime.year);
  }

  String _formatTime(DateTime dateTime, AppLocalizations l10n) {
    return l10n.formatTime(dateTime.hour, dateTime.minute);
  }
}
