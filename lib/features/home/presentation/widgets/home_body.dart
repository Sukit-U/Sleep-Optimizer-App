import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/shared/widgets/home_feature_card.dart';
import 'package:snoozemate/shared/widgets/tonight_suggestion_card.dart';
import 'package:snoozemate/shared/widgets/latest_score_section.dart';

/// Selects the appropriate greeting based on the hour of day (local time).
///
/// Ranges (continuous, non-overlapping, no gaps):
/// - 00:00–04:59: Late night
/// - 05:00–11:59: Morning
/// - 12:00–17:59: Afternoon
/// - 18:00–21:59: Evening
/// - 22:00–23:59: Night
String selectGreeting(int hour, AppLocalizations l10n) {
  if (hour < 5) return l10n.homeGreetingLateNight;
  if (hour < 12) return l10n.homeGreetingMorning;
  if (hour < 18) return l10n.homeGreetingAfternoon;
  if (hour < 22) return l10n.homeGreetingEvening;
  return l10n.homeGreetingNight;
}

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  String _greet(BuildContext context) {
    final h = DateTime.now().hour;
    final l10n = context.l10n;
    return selectGreeting(h, l10n);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          TonightSuggestionCard(
            onPlanTonight: () =>
                Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
          ),
          const SizedBox(height: 20),
          _buildFeatureGrid(context),
          const SizedBox(height: 24),
          LatestScoreSection(
            onViewHistory: () =>
                Navigator.of(context).pushNamed(AppRoutes.history),
            onStartAssessment: () =>
                Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greet(context)},',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              l10n.homeHeading,
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: HomeFeatureCard(
              icon: Icons.nightlight_round,
              iconColor: colors.primary,
              title: l10n.featurePlannerTitle,
              description: l10n.featurePlannerDesc,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeFeatureCard(
              icon: Icons.checklist_rtl_rounded,
              iconColor: colors.secondary,
              title: l10n.featureQualityTitle,
              description: l10n.featureQualityDesc,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
            ),
          ),
        ],
      ),
    );
  }
}
