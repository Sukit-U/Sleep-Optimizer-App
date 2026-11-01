import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';

/// A CTA card for the home screen suggesting to plan tonight's sleep.
///
/// Shows a gradient background with a call-to-action button.
class TonightSuggestionCard extends StatelessWidget {
  final VoidCallback? onPlanTonight;

  const TonightSuggestionCard({
    super.key,
    this.onPlanTonight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
        border: Border.all(color: colors.outline),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.secondary.withValues(alpha: 0.35),
            colors.primary.withValues(alpha: 0.20),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                "Tonight's suggestion",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Plan tonight',
            style: GoogleFonts.sora(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us when you need to wake up.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPlanTonight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.60),
                    blurRadius: 30,
                    spreadRadius: -12,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open Sleep Planner',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: colors.onPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
