import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0h';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.nightlight_round,
              color: colors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bedtimeString,
                    style: GoogleFonts.sora(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cycles cycles • ${_formatDuration(durationMinutes)}',
                    style: GoogleFonts.inter(
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
                      'Recommended',
                      style: GoogleFonts.inter(
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
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
