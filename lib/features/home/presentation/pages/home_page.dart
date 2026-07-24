import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../shared/widgets/feature_card.dart';
import '../../../../shared/widgets/section_title.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Sleep Optimizer'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FeatureCard(
                  title: 'Sleep Planner',
                  subtitle: 'Plan a bedtime around your wake-up goal.',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
                ),
                FeatureCard(
                  title: 'Sleep Quality',
                  subtitle: 'Check your SQI and review your habits.',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
                ),
                FeatureCard(
                  title: 'Recommendation',
                  subtitle: 'View action-focused suggestions for improvement.',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.recommendation),
                ),
                FeatureCard(
                  title: 'History',
                  subtitle: 'Review previous sleep patterns and results.',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
                ),
                FeatureCard(
                  title: 'Settings',
                  subtitle: 'Adjust app preferences and application info.',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
