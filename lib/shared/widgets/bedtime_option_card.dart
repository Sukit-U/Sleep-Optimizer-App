import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';

/// A bedtime option card showing cycles, duration, and bedtime string.
///
/// Used in the sleep planner's "suggested bedtimes" list.
class BedtimeOptionCard extends StatelessWidget {
  final int cycles;
  final String bedtimeString;
  final int durationMinutes;
  final bool isRecommended;
  final bool isSelected;
  final VoidCallback? onTap;

  const BedtimeOptionCard({
    super.key,
    required this.cycles,
    required this.bedtimeString,
    required this.durationMinutes,
    this.isRecommended = false,
    this.isSelected = false,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.nightlight_round, color: colors.primary, size: 24),
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
                      color: colors.onSurface,
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
                if (isRecommended)
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
                    child: Icon(Icons.check, color: colors.primary, size: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
