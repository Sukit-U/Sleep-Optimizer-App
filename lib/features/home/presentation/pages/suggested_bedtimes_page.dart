import 'package:flutter/material.dart';

import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/shared/widgets/app_card.dart';

/// Page showing three suggested bedtime cards, as per the design spec.
class SuggestedBedtimesPage extends StatelessWidget {
  const SuggestedBedtimesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plannerSuggestedBedtimes),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: List.generate(
              3,
              (i) => _BedtimeCard(index: i + 1, l10n: l10n),
            ),
          ),
        ),
      ),
    );
  }
}

class _BedtimeCard extends StatelessWidget {
  final int index;
  final AppLocalizations l10n;

  const _BedtimeCard({required this.index, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.bedtimeLabel(index), style: AppTypography.h2),
            const SizedBox(height: AppSpacing.xs),
            Text('7:00 PM – 7:30 PM', style: AppTypography.body),
          ],
        ),
      ),
    );
  }
}
