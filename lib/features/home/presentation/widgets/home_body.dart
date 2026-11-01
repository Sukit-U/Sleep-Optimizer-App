import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snoozemate/shared/widgets/home_feature_card.dart';
import 'package:snoozemate/shared/widgets/tonight_suggestion_card.dart';
import 'package:snoozemate/shared/widgets/latest_score_section.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 5) return "Still up?";
    if (h < 12) return "Good morning";
    if (h < 18) return "Good afternoon";
    return "Good evening";
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greet()},',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
            Row(
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.sora(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('🌙', style: TextStyle(fontSize: 24)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: HomeFeatureCard(
              icon: Icons.nightlight_round,
              iconColor: colors.primary,
              title: 'Sleep Planner',
              description: 'Find your best bedtime',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.sleepPlanner),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeFeatureCard(
              icon: Icons.checklist_rtl_rounded,
              iconColor: colors.secondary,
              title: 'Sleep Quality',
              description: 'Take the assessment',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.sleepQuality),
            ),
          ),
        ],
      ),
    );
  }
}
