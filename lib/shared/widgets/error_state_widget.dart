import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

/// An error state widget with a retry button.
///
/// Displays an error icon, message, and optional retry action.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail!,
              style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Text(
                  'Retry',
                  style: AppTypography.button.copyWith(color: colors.onPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
