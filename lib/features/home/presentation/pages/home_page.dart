import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/features/home/presentation/widgets/home_body.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _currentIndex = 0;

  // Matching Lovable tabs: Home, Planner, SQI, History, Settings
  final List<_TabItem> _tabs = [
    _TabItem(route: AppRoutes.home, label: 'Home', icon: Icons.home_filled),
    _TabItem(
      route: AppRoutes.sleepPlanner,
      label: 'Planner',
      icon: Icons.nightlight_round,
    ),
    _TabItem(
      route: AppRoutes.sleepQuality,
      label: 'SQI',
      icon: Icons.fact_check,
    ),
    _TabItem(route: AppRoutes.history, label: 'History', icon: Icons.history),
    _TabItem(
      route: AppRoutes.settings,
      label: 'Settings',
      icon: Icons.settings,
    ),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    // Switch completely without keeping backstack, matching actual nav behavior
    final route = _tabs[index].route;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use AppColors for background and other theme properties
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Orbs for Home Scaffold
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: MediaQuery.of(context).size.width * 0.1,
            child: _buildOrb(AppSpacing.huge * 8, AppColors.accent.withOpacity(0.35)), // 300
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            right: -50,
            child: _buildOrb(AppSpacing.huge * 6.25, AppColors.primary.withOpacity(0.35)), // 250
          ),

          SafeArea(child: HomeBody(context: context)),

          // Floating Pill Bottom Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.md, // 16
            child: _buildFloatingBottomNav(),
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.defaultSpacing), // 16.0
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull), // 9999
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm), // 8
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull), // 9999
                border: Border.all(
                  color: AppColors.border.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.45), // Colors.black45
                    blurRadius: AppSpacing.lg, // 20
                    offset: Offset(0, AppSpacing.defaultSpacing - 6), // 10
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_tabs.length, (index) {
                  final active = index == _currentIndex;
                  final tab = _tabs[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(index),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm), // 8
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, // 12
                                vertical: AppSpacing.xs, // 4
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tab.icon,
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.mutedForeground,
                                    size: AppSpacing.iconMd + 2, // 22
                                  ),
                                  SizedBox(height: AppSpacing.xs - 2), // 2
                                  Text(
                                    tab.label,
                                    style: GoogleFonts.inter(
                                      fontSize: AppTypography.caption.fontSize, // 10
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: active
                                          ? AppColors.primary
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String route;
  final String label;
  final IconData icon;

  const _TabItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}