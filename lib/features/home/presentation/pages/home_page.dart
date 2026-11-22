import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snoozemate/app/router.dart';
import 'package:snoozemate/core/l10n/app_localizations.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/features/home/presentation/widgets/home_body.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// The tab to highlight, taken from the route. Home is only ever shown as
  /// `/`, so a tab pushed on top and then popped cannot leave the bar
  /// highlighting the screen the user just came back from.
  int get _currentIndex {
    final name = ModalRoute.of(context)?.settings.name ?? AppRoutes.home;
    final index = _tabs.indexWhere((tab) => tab.route == name);
    return index < 0 ? 0 : index;
  }

  final List<_TabItem> _tabs = [
    _TabItem(route: AppRoutes.home, icon: Icons.home),
    _TabItem(route: AppRoutes.sleepPlanner, icon: Icons.nightlight_round),
    _TabItem(route: AppRoutes.sleepQuality, icon: Icons.checklist_rtl_rounded),
    _TabItem(route: AppRoutes.history, icon: Icons.history),
    _TabItem(route: AppRoutes.settings, icon: Icons.settings),
  ];

  String _tabLabel(String route) {
    final l10n = context.l10n;
    switch (route) {
      case AppRoutes.home:
        return l10n.navHome;
      case AppRoutes.sleepPlanner:
        return l10n.navPlanner;
      case AppRoutes.sleepQuality:
        return l10n.navSqi;
      case AppRoutes.history:
        return l10n.navHistory;
      case AppRoutes.settings:
        return l10n.navSettings;
      default:
        return route;
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    final route = _tabs[index].route;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(route, (route) => route.isFirst);
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
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: colors.outline, width: 1),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm - 2,
                    ),
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
                          _tabLabel(tab.route),
                          style: TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: AppTypography.navLabel.fontSize,
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
    );
  }
}

class _TabItem {
  final String route;
  final IconData icon;

  const _TabItem({required this.route, required this.icon});
}
