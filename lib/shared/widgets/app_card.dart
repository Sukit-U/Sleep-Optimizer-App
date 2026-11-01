import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';

/// AppCard - A reusable card component following the design system specifications.
/// Used for containers that need card styling with proper spacing and shadows.
class AppCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.md,
    this.borderRadius,
    this.elevation = AppSpacing.elevationSm,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: elevation,
      margin: EdgeInsets.all(padding),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: colors.outline, width: 1),
        ),
        child: child,
      ),
    );
  }
}