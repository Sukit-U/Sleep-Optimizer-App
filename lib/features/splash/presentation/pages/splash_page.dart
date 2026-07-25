import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:snoozemate/app/router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_colors.dart';

/// Splash screen that matches the layout defined in CompleteScreenSpecifications
/// - Gradient background
/// - Moon icon with glow effect
/// - App name with fade‑in animation
/// - Auto‑navigate to the Home screen after a short delay
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation: fade‑in for the whole content, and scale for the moon icon
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Navigate to home after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        // Full‑screen gradient background as per Design‑System.md
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Moon icon with scaling animation and glow using AppColors.primaryGlow
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  Icons.nightlight_round,
                  size: AppSpacing.iconXl, // 64px as defined in the design system
                  color: AppColors.primaryGlow,
                ),
              ),
              const SizedBox(height: AppSpacing.md), // 12px vertical gap
              // App name text – uses the heading style from the design system
              Text(
                'SleepSci',
                style: AppTypography.h1.copyWith(
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}