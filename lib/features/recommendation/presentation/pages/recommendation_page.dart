import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import '../../../../models/recommendation_model.dart';
import '../../domain/usecases/generate_recommendations.dart';
import '../../../sleep_quality/domain/entities/sqi_result.dart';

/// RecommendationPage – UI implementation matching Lovable design.
/// Shows SQI score, factor breakdown, and personalized recommendations.
class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key, this.result});

  final SqiResult? result;

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final recommendations = result == null
        ? <Recommendation>[]
        : const GenerateRecommendations().call(
            weakFactors: result.weakFactors,
            level: result.level.name,
          );

    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          children: [
            // Inline header (Lovable reference: back button + caption + title)
            _buildHeader(l10n),

            // SQI Score display
            if (result != null) ...[
              _buildSQIScoreDisplay(result, l10n),
              const SizedBox(height: AppSpacing.lg),

              // Factor breakdown
              _buildFactorBreakdown(l10n),
              const SizedBox(height: AppSpacing.lg),

              // Recommendations
              _buildRecommendations(l10n),
            ],

            // Empty state or recommendations
            if (recommendations.isEmpty && result == null)
              _buildEmptyState(
                label: l10n.recEmptyNeedSQI,
              )
            else
              ...recommendations.isEmpty
                  ? [
                      _buildEmptyState(
                        label: l10n.recEmptyGreatHabits,
                      ),
                    ]
                  : recommendations.map((r) => _buildRecommendationItem(r, l10n)),

            // Navigation buttons
            if (result != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _buildGhostButton(
                      label: l10n.recButtonHome,
                      icon: Icons.home,
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.home,
                          (route) => route.isFirst,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildPrimaryButton(
                      label: l10n.recButtonViewHistory,
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.history);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Inline header (Lovable reference: back button pill + caption + title)
  Widget _buildHeader(AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg), // mb-6
      child: Row(
        children: [
          // Circular back button (rounded-full border pill)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: AppSpacing.iconButtonSize,
              height: AppSpacing.iconButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.outline),
              ),
              child: Icon(
                Icons.arrow_back,
                size: AppSpacing.iconSizeSm,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12), // gap-3
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recYourResult,
                  style: AppTypography.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.recSleepQualityIndex,
                  style: AppTypography.h1.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Implementation of various UI components matching Lovable design

  /// SQI Score display with circular gradient
  Widget _buildSQIScoreDisplay(SqiResult result, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    final scoreColor = _getScoreColor(result.score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          // Circular progress indicator with score
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring with gradient effect
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: result.score / 100,
                    strokeWidth: 8,
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                // Inner circle with score
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${result.score}',
                        style: AppTypography.displayLarge.copyWith(
                          color: colors.onSurface,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        l10n.recScoreSuffix,
                        style: AppTypography.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Quality level badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.spacingXs,
            ),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
            ),
            child: Text(
              l10n.sleepQualityLevel(result.level.name),
              style: AppTypography.labelSmall.copyWith(color: scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Factor breakdown section with progress bars
  Widget _buildFactorBreakdown(AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recFactorBreakdown,
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._buildFactorItems(l10n),
      ],
    );
  }

  List<Widget> _buildFactorItems(AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    final entries = widget.result!.factorScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((f) {
      final score = f.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recFactorLabel(f.key) ?? f.key,
                    style: AppTypography.body.copyWith(color: colors.onSurface),
                  ),
                  Text(
                    '$score/100',
                    style: AppTypography.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getScoreColor(score),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.roundedFull,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Recommendations section header with sparkle icon
  Widget _buildRecommendations(AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recRecommendations,
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  /// Detailed recommendation card
  Widget _buildRecommendationItem(
      Recommendation recommendation, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Text(
                  l10n.recPriorityLabel(recommendation.priority) ??
                      recommendation.priority,
                  style: AppTypography.small.copyWith(color: colors.primary),
                ),
              ),
               Text(
                 l10n.recFactorLabel(recommendation.factor) ??
                     recommendation.factor,
                 style: AppTypography.caption.copyWith(
                   color: colors.onSurfaceVariant,
                 ),
               ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
           Text(
             l10n.recTitleFor(recommendation.factor) ?? recommendation.title,
             style: AppTypography.h3.copyWith(color: colors.onSurface),
           ),
          const SizedBox(height: AppSpacing.xs),
           Text(
             l10n.recDescriptionFor(recommendation.factor) ??
                 recommendation.description,
             style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
           ),
          const SizedBox(height: AppSpacing.md),
           Text(
             l10n.recAction(l10n.recActionFor(recommendation.factor) ??
                 recommendation.action),
             style: AppTypography.caption.copyWith(
               color: colors.onSurfaceVariant,
             ),
           ),
          const SizedBox(height: AppSpacing.spacingXs),
           Text(
             l10n.recFactor(recommendation.factor),
             style: AppTypography.caption.copyWith(color: colors.secondary),
           ),
        ],
      ),
    );
  }

  /// Empty state component
  Widget _buildEmptyState({required String label}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        border: Border.all(color: colors.outline),
      ),
      child: Text(
        label,
        style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Ghost button for secondary actions
  Widget _buildGhostButton({
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSpacing.iconMd, color: colors.onSurface),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.button.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  /// Primary button for main actions
  Widget _buildPrimaryButton({required String label, VoidCallback? onPressed}) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.button.copyWith(color: colors.onPrimary),
          ),
        ),
      ),
    );
  }

  /// Get color based on score
  Color _getScoreColor(int score) {
    if (score >= 70) {
      return AppColors.success;
    } else if (score >= 40) {
      return AppColors.warning;
    } else {
      return AppColors.destructive;
    }
  }
}

