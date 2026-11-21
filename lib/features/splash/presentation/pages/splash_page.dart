import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/app/router.dart';

import 'package:snoozemate/core/theme/app_spacing.dart';

const _welcomeKey = 'so.welcomeSeen';

/// Welcome screen. One job: get out of the way.
///
/// The app name and a single honest sentence, then Continue. No feature tour,
/// no glow, no gradients.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Future<void> _enter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final insets = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - insets.top - insets.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  Icon(
                    Icons.nightlight_round,
                    size: AppSpacing.iconXl,
                    color: colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Snoozefriend',
                    style: GoogleFonts.karla(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  Text(
                    'Work out when to go to bed tonight, based on when you '
                    'need to be up.',
                    style: GoogleFonts.karla(
                      fontSize: 16,
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _enter,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.karla(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'An educational tool, not a medical device.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.karla(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
