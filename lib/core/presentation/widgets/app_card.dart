import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';

/// AppCard - A reusable card component following the design system specifications.
/// Used for containers that need card styling with proper spacing and shadows.
class AppCard extends StatelessWidget {
  final Widget child;
  final double padding;
  BorderRadius? borderRadius;
  Color backgroundColor;
  double elevation;

  AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.md,
    this.borderRadius,
    this.elevation = AppSpacing.elevationSm,
    this.backgroundColor = AppColors.card,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      margin: EdgeInsets.all(padding),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? AppSpacing.radiusXl,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}