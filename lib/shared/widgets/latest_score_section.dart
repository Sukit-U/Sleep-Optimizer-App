import 'package:flutter/material.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.latestScoreTitle,
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: onViewHistory,
              child: Text(
                l10n.viewHistory,
                style: TextStyle(
                  fontFamily: 'Kanit',
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
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sleepQualitySubtitle,
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.sleepQualityPrompt,
                style: TextStyle(
                  fontFamily: 'Kanit',
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
                      l10n.startAssessment,
                      style: TextStyle(
                        fontFamily: 'Kanit',
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
