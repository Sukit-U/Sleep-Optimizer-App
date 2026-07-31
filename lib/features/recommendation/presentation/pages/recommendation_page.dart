import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.px,
            vertical: AppSpacing.py,
          ),
          children: [
            // Inline header (Lovable reference: back button + caption + title)
            _buildHeader(),

            // SQI Score display
            if (result != null) ...[
              _buildSQIScoreDisplay(result),
              const SizedBox(height: AppSpacing.lg),

              // Factor breakdown
              _buildFactorBreakdown(result),
              const SizedBox(height: AppSpacing.lg),

              // Recommendations
              _buildRecommendations(recommendations),
            ],

            // Empty state or recommendations
            if (recommendations.isEmpty && result == null)
              _buildEmptyState(
                label: 'Complete your SQI to receive personalized recommendations.',
              )
            else
              ...recommendations.isEmpty
                  ? [
                      _buildEmptyState(
                        label: 'Your habits look great — keep it up!',
                      ),
                    ]
                  : recommendations.map((r) => _buildRecommendationItem(r)),

            // Navigation buttons
            if (result != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _buildGhostButton(
                      label: 'Home',
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
                      label: 'View history',
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
  Widget _buildHeader() {
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
                  'Your result',
                  style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
                ),
                Text(
                  'Sleep Quality Index',
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
  Widget _buildSQIScoreDisplay(SqiResult result) {
    final colors = Theme.of(context).colorScheme;
    final scoreColor = _getScoreColor(result.score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.roundedLg),            boxShadow: [BoxShadow(
            color: colors.shadow,
            blurRadius: AppSpacing.cardShadow,
            offset: const Offset(0, 2),
          )],
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
                        '/ 100',
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
              result.level.name,
              style: AppTypography.labelSmall.copyWith(color: scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Factor breakdown section with progress bars
  Widget _buildFactorBreakdown(SqiResult result) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Factor breakdown',
          style: AppTypography.h2.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._buildFactorItems(result),
      ],
    );
  }

  List<Widget> _buildFactorItems(SqiResult result) {
    final colors = Theme.of(context).colorScheme;
    final entries = result.factorScores.entries.toList()
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
            boxShadow: [BoxShadow(
              color: colors.shadow,
              blurRadius: AppSpacing.cardShadow,
              offset: const Offset(0, 2),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    f.key,
                    style: AppTypography.body.copyWith(color: colors.onSurface),
                  ),
                  Text(
                    '$score/100',
                    style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
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
                      borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
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
  Widget _buildRecommendations(List<Recommendation> recommendations) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: AppSpacing.iconMd,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Personalized recommendations',
              style: AppTypography.h2.copyWith(color: colors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  /// Detailed recommendation card
  Widget _buildRecommendationItem(Recommendation recommendation) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
            boxShadow: [BoxShadow(
              color: colors.shadow,
              blurRadius: AppSpacing.cardShadow,
              offset: const Offset(0, 2),
            )],
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
                  'Priority ${recommendation.priority}',
                  style: AppTypography.small.copyWith(color: colors.primary),
                ),
              ),
              Text(
                recommendation.factor,
                style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            recommendation.title,              style: AppTypography.h3.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            recommendation.description,
            style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Action: ${recommendation.action}',
            style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.spacingXs),
          Text(
            'Factor: ${recommendation.factor}',
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
            boxShadow: [BoxShadow(
              color: colors.shadow,
              blurRadius: AppSpacing.cardShadow,
              offset: const Offset(0, 2),
            )],
          ),
      child: Text(
        label,
        style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Ghost button for secondary actions
  Widget _buildGhostButton({required String label, IconData? icon, VoidCallback? onPressed}) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
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