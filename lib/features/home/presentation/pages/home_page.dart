import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snoozemate/features/home/presentation/widgets/home_body.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<_TabItem> _tabs = [
    _TabItem(route: AppRoutes.home, label: 'Home', icon: Icons.home),
    _TabItem(
      route: AppRoutes.sleepPlanner,
      label: 'Planner',
      icon: Icons.nightlight_round,
    ),
    _TabItem(
      route: AppRoutes.sleepQuality,
      label: 'SQI',
      icon: Icons.checklist_rtl_rounded,
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
    setState(() {
      _currentIndex = index;
    });
    final route = _tabs[index].route;
    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = math.min(448.0, screenWidth - 32);

    return Center(
      child: SizedBox(
        width: containerWidth,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              SafeArea(child: HomeBody()),

              // Floating Pill Bottom Nav
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.md,
                child: _buildFloatingBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: colors.outline,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.60),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final active = index == _currentIndex;
                  final tab = _tabs[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabTapped(index),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 20,
                              color: active
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.xs - 2),
                            Text(
                              tab.label,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: active
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
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
