import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';

/// Reusable container that matches the Lovable `card-surface` utility:
/// surface @ 92%, border @ 80%, radius-2xl, backdrop-blur 8px.
///
/// Used by the Home feature grid, "Latest score" empty card, and any other
/// Home tile that should match Lovable styling.
class HomeCardSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const HomeCardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radius2xl);

    final decoration = BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: radius,
      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
    );

    final body = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: decoration,
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return body;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: body);
  }
}