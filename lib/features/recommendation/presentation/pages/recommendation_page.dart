import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import '../../domain/entities/recommendation.dart';
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
        ? <RecommendationEntity>[]
        : const GenerateRecommendations().call(weakFactors: result.weakFactors);

    return Scaffold(
      body: SafeArea(
        child: Padding(
padding: const EdgeInsets.symmetric(
  horizontal: AppSpacing.spacingXs,
  vertical: AppSpacing.spacingXs,
),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: AppSpacing.iconButtonSize,
                      height: AppSpacing.iconButtonSize,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: AppSpacing.iconMd,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your result',
                        style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                      ),
                      Text(
                        'Sleep Quality Index',
                        style: AppTypography.h1.copyWith(color: AppColors.foreground),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

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
                Expanded(
                  child: _buildEmptyState(
                    label: 'Complete your SQI to receive personalized recommendations.',
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: recommendations.isEmpty
                        ? [
                            _buildEmptyState(
                              label: 'Your habits look great — keep it up!',
                            ),
                          ]
                        : recommendations
                            .map((r) => _buildRecommendationItem(r))
                            .toList(),
                  ),
                ),

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
                          // Navigate to home
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildPrimaryButton(
                        label: 'View history',
                        onPressed: () {
                          // Navigate to history
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Implementation of various UI components matching Lovable design

  /// SQI Score display with circular gradient
  Widget _buildSQIScoreDisplay(SqiResult result) {
    final scoreColor = _getScoreColor(result.score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                    backgroundColor: AppColors.mutedBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                // Inner circle with score
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${result.score}',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.foreground,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.mutedForeground,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Factor breakdown',
          style: AppTypography.h2.copyWith(color: AppColors.foreground),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._buildFactorItems(result),
      ],
    );
  }

  List<Widget> _buildFactorItems(SqiResult result) {
    final factors = [
      {'key': 'duration', 'label': 'Sleep Duration', 'score': 75},
      {'key': 'latency', 'label': 'Sleep Latency', 'score': 60},
      {'key': 'efficiency', 'label': 'Sleep Efficiency', 'score': 82},
    ];

    return factors.map((f) {
      final score = f['score'] as int;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                    f['label'] as String,
                    style: AppTypography.body.copyWith(color: AppColors.foreground),
                  ),
                  Text(
                    '$score/100',
                    style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
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
  Widget _buildRecommendations(List<RecommendationEntity> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: AppSpacing.iconMd,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Personalized recommendations',
              style: AppTypography.h2.copyWith(color: AppColors.foreground),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  /// Detailed recommendation card
  Widget _buildRecommendationItem(RecommendationEntity recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Text(
                  'Priority ${recommendation.priority.name}',
                  style: AppTypography.small.copyWith(color: AppColors.primary),
                ),
              ),
              Text(
                recommendation.factor,
                style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            recommendation.title,
            style: AppTypography.h3.copyWith(color: AppColors.foreground),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            recommendation.description,
            style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Action: ${recommendation.action}',
            style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.spacingXs),
          Text(
            'Factor: ${recommendation.factor}',
            style: AppTypography.caption.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  /// Empty state component
  Widget _buildEmptyState({required String label}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: AppSpacing.cardShadow,
              offset: const Offset(0, 2),
            )],
          ),
      child: Text(
        label,
        style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Ghost button for secondary actions
  Widget _buildGhostButton({required String label, IconData? icon, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSpacing.iconMd, color: AppColors.foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.button.copyWith(color: AppColors.foreground),
            ),
          ],
        ),
      ),
    );
  }

  /// Primary button for main actions
  Widget _buildPrimaryButton({required String label, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.roundedXl),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.button.copyWith(color: AppColors.primaryForeground),
          ),
        ),
      ),
    );
  }

  /// Get color based on quality level
  Color _getQualityColor(String level) {
    switch (level.toLowerCase()) {
      case 'excellent':
        return AppColors.success;
      case 'good':
        return AppColors.primary;
      case 'fair':
        return AppColors.warning;
      case 'poor':
      case 'very poor':
        return AppColors.destructive;
      default:
        return AppColors.primary;
    }
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