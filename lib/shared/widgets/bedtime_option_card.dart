import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/theme/app_colors.dart';

/// A bedtime option card showing cycles, duration, and bedtime string.
///
/// Used in the sleep planner's "suggested bedtimes" list.
/// When [isFeasible] is false the card is styled distinctly and is never
/// marked as recommended, so users do not mistake an infeasible plan for a
/// recommendation.
class BedtimeOptionCard extends StatelessWidget {
  final int cycles;
  final String bedtimeString;
  final int durationMinutes;
  final bool isRecommended;
  final bool isSelected;
  final bool isFeasible;
  final String? feasibilityReason;
  final VoidCallback? onTap;

  const BedtimeOptionCard({
    super.key,
    required this.cycles,
    required this.bedtimeString,
    required this.durationMinutes,
    this.isRecommended = false,
    this.isSelected = false,
    this.isFeasible = true,
    this.feasibilityReason,
    this.onTap,
  });

  String _formatDuration(BuildContext context) {
    final l10n = context.l10n;
    final minutes = durationMinutes;
    if (minutes == 0) return l10n.plannerDurationZero();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l10n.plannerDurationM(m);
    if (m == 0) return l10n.plannerDurationH(h);
    return l10n.plannerDurationHM(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final feasible = isFeasible;
    final borderColor = feasible
        ? (isSelected ? colors.primary : colors.outline)
        : AppColors.warning;
    final borderWidth = isSelected ? 2.0 : 1.0;
    final bedtimeColor = feasible ? colors.onSurface : AppColors.warning;
    final showRecommended = feasible && isRecommended;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: feasible ? colors.primary : AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bedtimeString,
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: bedtimeColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.plannerCycles(cycles)} • ${_formatDuration(context)}',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          l10n.plannerRecommended,
                          style: TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.check,
                          color: feasible ? colors.primary : AppColors.warning,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (!feasible &&
                feasibilityReason != null &&
                feasibilityReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      feasibilityReason!,
                      style: TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
