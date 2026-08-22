import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';

/// A section displaying the latest SQI score or a prompt to take the assessment.
///
/// Shows "View history" link and "Start Assessment" CTA.
class LatestScoreSection extends StatelessWidget {
  final VoidCallback? onViewHistory;
  final VoidCallback? onStartAssessment;

  const LatestScoreSection({
    super.key,
    this.onViewHistory,
    this.onStartAssessment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest score',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: onViewHistory,
              child: Text(
                'View history',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            border: Border.all(color: colors.outline.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sleep Quality Index',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete your first assessment to see your sleep quality score.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onStartAssessment,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Assessment',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
