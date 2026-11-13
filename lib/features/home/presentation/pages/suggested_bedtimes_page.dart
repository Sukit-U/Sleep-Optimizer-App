import 'package:flutter/material.dart';

import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/shared/widgets/app_card.dart';

/// Page showing three suggested bedtime cards, as per the design spec.
class SuggestedBedtimesPage extends StatelessWidget {
  const SuggestedBedtimesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Bedtimes'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: List.generate(3, (i) => _BedtimeCard(index: i + 1)),
          ),
        ),
      ),
    );
  }
}

class _BedtimeCard extends StatelessWidget {
  final int index;
  const _BedtimeCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bedtime #$index', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.xs),
            Text('7:00 PM – 7:30 PM', style: AppTypography.body),
          ],
        ),
      ),
    );
  }
}
