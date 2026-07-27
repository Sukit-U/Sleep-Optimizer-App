import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Custom button component based on CompleteScreenSpecifications design system
/// Supports multiple variants: primary, secondary, outlined, ghost, icon
enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  icon,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

/// AppButton - Custom styled button with multiple variants
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button label text
  final String label;

  /// Button variant style
  final AppButtonVariant variant;

  /// Button size
  final AppButtonSize size;

  /// Optional leading/trailing icon
  final IconData? icon;

  /// Icon position relative to label
  final IconPosition iconPosition;

  /// Show loading indicator
  final bool isLoading;

  /// Disable button interaction
  final bool isDisabled;

  /// Expand to full width
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36.0;
      case AppButtonSize.medium:
        return 44.0;
      case AppButtonSize.large:
        return 52.0;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppSpacing.iconSm;
      case AppButtonSize.medium:
        return AppSpacing.iconMd;
      case AppButtonSize.large:
        return AppSpacing.iconLg;
    }
  }

  TextStyle get _textStyle {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppTypography.labelSmall;
      case AppButtonSize.medium:
        return AppTypography.button;
      case AppButtonSize.large:
        return AppTypography.button.copyWith(fontSize: 16);
    }
  }

  Color get _backgroundColor {
    if (widget.isDisabled || widget.isLoading) {
      return AppColors.muted;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.outlined:
        return Colors.transparent;
      case AppButtonVariant.ghost:
        return AppColors.muted.withValues(alpha: 0.5);
      case AppButtonVariant.icon:
        return AppColors.card;
    }
  }

  Color get _foregroundColor {
    if (widget.isDisabled || widget.isLoading) {
      return AppColors.mutedForeground;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primaryForeground;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.outlined:
        return AppColors.foreground;
      case AppButtonVariant.ghost:
        return AppColors.foreground;
      case AppButtonVariant.icon:
        return AppColors.foreground;
    }
  }

  Border? get _border {
    if (widget.variant == AppButtonVariant.outlined) {
      return Border.all(
        color: widget.isDisabled ? AppColors.border : AppColors.border,
        width: 1,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == AppButtonVariant.icon) {
      return _buildIconButton();
    }
    return _buildStandardButton();
  }

  Widget _buildIconButton() {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: _height,
          height: _height,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (widget.isDisabled || widget.isLoading) ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _foregroundColor,
                        ),
                      )
                    : Icon(
                        widget.icon ?? Icons.arrow_back,
                        size: _iconSize,
                        color: _foregroundColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardButton() {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: _height,
          constraints: widget.fullWidth
              ? const BoxConstraints(minWidth: double.infinity)
              : null,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: _border,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (widget.isDisabled || widget.isLoading) ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Padding(
                padding: _padding,
                child: Row(
                  mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildChildren(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChildren() {
    final children = <Widget>[];
    
    if (widget.icon != null && widget.iconPosition == IconPosition.left) {
      children.add(
        Padding(
          padding: EdgeInsets.only(right: widget.size == AppButtonSize.small ? 4.0 : 8.0),
          child: widget.isLoading
              ? SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _foregroundColor,
                  ),
                )
              : Icon(widget.icon, size: _iconSize, color: _foregroundColor),
        ),
      );
    }
    
    children.add(
      Text(
        widget.label,
        style: _textStyle.copyWith(color: _foregroundColor),
      ),
    );
    
    if (widget.icon != null && widget.iconPosition == IconPosition.right) {
      children.add(
        Padding(
          padding: EdgeInsets.only(left: widget.size == AppButtonSize.small ? 4.0 : 8.0),
          child: widget.isLoading
              ? SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _foregroundColor,
                  ),
                )
              : Icon(widget.icon, size: _iconSize, color: _foregroundColor),
        ),
      );
    }
    
    return children;
  }
}

/// Icon position relative to button label
enum IconPosition {
  left,
  right,
}

/// Simple outlined button for secondary actions
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.fullWidth = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      constraints: fullWidth ? const BoxConstraints(minWidth: double.infinity) : null,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.buttonPadding),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Icon-only button for compact actions
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 40.0,
    this.backgroundColor,
    this.iconColor,
    this.isDisabled = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isDisabled;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isDisabled ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: widget.size * 0.5,
                  color: widget.iconColor ?? AppColors.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
