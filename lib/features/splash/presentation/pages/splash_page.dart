import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';


const _welcomeKey = 'so.welcomeSeen';

/// Welcome screen matching Lovable index.tsx layout:
/// • Two ambient‑orb radial gradients (background)
/// • App icon container (96×96, rounded-3xl, gradient) + Moon icon + Sparkles badge
/// • Title + subtitle
/// • 3 feature rows (card-surface style)
/// • "Continue" btn-primary
/// • Disclaimer text
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Lovable design color tokens (oklch → closest sRGB)
  // These are now replaced by AppColors

  Future<void> _enter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  void initState() {
    super.initState();
    // No auto-navigation, user taps "Continue"
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Ambient orb 1: purple at top-center ──
          Positioned(
            top: -size.height * 0.13,
            left: size.width * 0.5 - 160,
            child: _AmbientOrb(
              size: AppSpacing.huge * 8, // 320
              color: AppColors.accent.withValues(alpha: 0.60 * 0.6),
            ),
          ),
          // ── Ambient orb 2: blue at bottom-right ──
          Positioned(
            bottom: -size.height * 0.17,
            right: -AppSpacing.huge * 2.4, // -96
            child: _AmbientOrb(
              size: AppSpacing.huge * 9.6, // 384
              color: AppColors.primary.withValues(alpha: 0.60 * 0.4),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.px),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xxl),

                      // ── Header: icon + title + subtitle ──
                      _buildHeader(),

                      SizedBox(height: AppSpacing.huge),

                      // ── Feature rows ──
                      _buildFeatureList(),

                      const Spacer(),
                      SizedBox(height: AppSpacing.huge),

                      // ── Continue button + disclaimer ──
                      _buildCTA(),

                      SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon container — 96×96, rounded-3xl, gradient, shadow
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: AppSpacing.iconSplashContainer,
              height: AppSpacing.iconSplashContainer,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.30),
                    AppColors.accent.withValues(alpha: 0.30),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.50),
                    blurRadius: 60,
                    offset: Offset(0, AppSpacing.xxl - 8), // 20
                    spreadRadius: -AppSpacing.xxl + 4, // -20
                  ),
                ],
              ),
              child: Icon(
                Icons.nightlight_round,
                size: AppSpacing.iconXxl + 4, // 44
                color: AppColors.primary,
              ),
            ),
            // Sparkles badge — top-right corner
            Positioned(
              top: -AppSpacing.sm - 2, // -6
              right: -AppSpacing.sm - 2, // -6
              child: Icon(Icons.auto_awesome, size: AppSpacing.iconSm, color: AppColors.accent),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.defaultSpacing),

        Text(
          'Sleep Optimizer',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(
            fontSize: AppTypography.h1.fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: AppTypography.h1.letterSpacing,
            height: AppTypography.h1.height,
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        Text(
          'Plan smarter nights. Build healthier habits.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: AppTypography.body.fontSize,
            fontWeight: AppTypography.body.fontWeight,
            color: AppColors.mutedForeground,
            height: AppTypography.body.height,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      _FeatureData(
        icon: Icons.nightlight_round,
        iconColor: AppColors.primary,
        title: 'Sleep Planner',
        description: 'Find bedtimes aligned with complete sleep cycles.',
      ),
      _FeatureData(
        icon: Icons.checklist,
        iconColor: AppColors.accent,
        title: 'Sleep Quality Index',
        description: 'A 3-minute assessment of your sleep habits.',
      ),
      _FeatureData(
        icon: Icons.auto_awesome,
        iconColor: AppColors.primary,
        title: 'Personalized advice',
        description: 'Small, actionable steps — one habit at a time.',
      ),
    ];

    return Column(
      children: features.map((f) => _FeatureRow(feature: f)).toList(),
    );
  }

  Widget _buildCTA() {
    return Column(
      children: [
        // Continue button — btn-primary style (pill, blue, shadow)
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _enter,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md + 2), // 14
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.60),
                    blurRadius: 30,
                    spreadRadius: -AppSpacing.md, // -12
                    offset: Offset(0, AppSpacing.defaultSpacing - 6), // 10
                  ),
                ],
              ),
              child: Text(
                'Continue',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: AppTypography.button.fontSize,
                  fontWeight: AppTypography.button.fontWeight,
                  color: AppColors.primaryForeground,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: AppSpacing.defaultSpacing),

        Text(
          'Educational tool. Not a medical device.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: AppTypography.caption.fontSize! - 1, // 11
            fontWeight: AppTypography.caption.fontWeight,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ──────────────────────────────────────────────────────────────────────────────

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

class _FeatureRow extends StatelessWidget {
  final _FeatureData feature;

  const _FeatureRow({required this.feature});

  // Lovable design tokens (inline so widget is self-contained)
  // These are now replaced by AppColors
  // static const _fgMain = Color(0xFFF7F8FA);
  // static const _mutedFg = Color(0xFFADB0BC);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.defaultSpacing),
        decoration: BoxDecoration(
          // card-surface: surface 92% opacity, border, radius-2xl (24px), backdrop-blur-ish
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.80), width: 1),
        ),
        child: Row(
          children: [
            // Icon inside a square 40×40 background/40 container (rounded-xl)
            Container(
              width: AppSpacing.iconMdContainer,
              height: AppSpacing.iconMdContainer,
              decoration: BoxDecoration(
                // bg-background/40 equivalent
                color: AppColors.background.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(feature.icon, size: AppSpacing.iconMd - 2, color: feature.iconColor), // 18
            ),

            SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.body.fontSize,
                      fontWeight: AppTypography.body.fontWeight,
                      color: AppColors.foreground,
                      height: AppTypography.body.height,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs - 2), // 2
                  Text(
                    feature.description,
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.caption.fontSize,
                      fontWeight: AppTypography.caption.fontWeight,
                      color: AppColors.mutedForeground,
                      height: AppTypography.caption.height,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
