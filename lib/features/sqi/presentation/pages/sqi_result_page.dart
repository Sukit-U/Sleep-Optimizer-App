import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/core/presentation/widgets/app_button.dart';
import 'package:snoozemate/features/sqi/models/sqi_models.dart';

/// SQI Result Screen matching Lovable design system
/// Shows the user's SQI score, sleep quality level, and personalized recommendations
class SQIResultPage extends StatelessWidget {
  final SQIRecord sqiRecord;
  final List<Recommendation> recommendations;

  const SQIResultPage({
    super.key,
    required this.sqiRecord,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'SQI Results',
          style: GoogleFonts.sora(
            fontSize: AppTypography.h3.fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient orb background
          Positioned(
            top: -AppSpacing.huge * 2,
            right: -AppSpacing.huge * 2,
            child: _buildOrb(AppSpacing.huge * 8, AppColors.accent.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: -AppSpacing.huge * 3,
            left: -AppSpacing.huge * 2,
            child: _buildOrb(AppSpacing.huge * 6, AppColors.primary.withValues(alpha: 0.35)),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.defaultSpacing,
                vertical: AppSpacing.defaultSpacing,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.defaultSpacing),

                  // SQI Score Card
                  _buildScoreCard(context),

                  SizedBox(height: AppSpacing.lg),

                  // Recommendations Section
                  _buildRecommendationsSection(),

                  SizedBox(height: AppSpacing.xxl),

                  // Back to Home Button
                  AppButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'Back to Home',
                    fullWidth: true,
                  ),

                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    // Determine score color based on level
    Color scoreColor;
    switch (sqiRecord.sleepQualityLevel) {
      case 'Excellent':
        scoreColor = AppColors.success;
        break;
      case 'Good':
        scoreColor = AppColors.info;
        break;
      case 'Fair':
        scoreColor = AppColors.warning;
        break;
      case 'Poor':
        scoreColor = AppColors.destructive;
        break;
      default:
        scoreColor = AppColors.primary;
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Text(
            'Your SQI Score',
            style: GoogleFonts.sora(
              fontSize: AppTypography.h4.fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Score with orb effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Orb background
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scoreColor.withValues(alpha: 0.2),
                      scoreColor.withValues(alpha: 0.1),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // Score text
              Text(
                '${sqiRecord.sqiScore}',
                style: GoogleFonts.sora(
                  fontSize: AppTypography.displayLarge.fontSize,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.sm),

          // Sleep quality level
          Text(
            'Sleep Quality: ${sqiRecord.sleepQualityLevel}',
            style: GoogleFonts.sora(
              fontSize: AppTypography.h3.fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),

          SizedBox(height: AppSpacing.sm),

          // Date
          Text(
            'Assessment taken on ${_formatDate(sqiRecord.createdAt)}',
            style: GoogleFonts.inter(
              fontSize: AppTypography.caption.fontSize,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recommendations',
          style: GoogleFonts.sora(
            fontSize: AppTypography.h4.fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // Recommendation cards
        ...recommendations.map((recommendation) => _buildRecommendationCard(recommendation)),
      ],
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    // Determine card color based on priority
    Color cardColor;
    Color textColor;
    Color iconColor;

    switch (recommendation.priority) {
      case 'Critical':
        cardColor = AppColors.destructive.withValues(alpha: 0.1);
        textColor = AppColors.destructive;
        iconColor = AppColors.destructive;
        break;
      case 'High':
        cardColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        iconColor = AppColors.warning;
        break;
      case 'Medium':
        cardColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        iconColor = AppColors.info;
        break;
      case 'Low':
        cardColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        iconColor = AppColors.success;
        break;
      default:
        cardColor = AppColors.surface;
        textColor = AppColors.foreground;
        iconColor = AppColors.primary;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.defaultSpacing),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRecommendationIcon(recommendation.factor),
                  size: AppSpacing.iconMd,
                  color: iconColor,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  recommendation.title,
                  style: GoogleFonts.sora(
                    fontSize: AppTypography.h5.fontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    recommendation.priority,
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.caption.fontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              recommendation.description,
              style: GoogleFonts.inter(
                fontSize: AppTypography.body.fontSize,
                color: AppColors.foreground,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: AppSpacing.iconSm,
                  color: AppColors.mutedForeground,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    recommendation.action,
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.caption.fontSize,
                      fontStyle: FontStyle.italic,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRecommendationIcon(String factor) {
    switch (factor) {
      case 'Sleep Duration':
        return Icons.nightlight_round;
      case 'Screen Time':
        return Icons.screen_lock_portrait;
      case 'Stress':
        return Icons.self_improvement;
      case 'Exercise':
        return Icons.directions_run;
      case 'General':
        return Icons.star;
      default:
        return Icons.lightbulb;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}