import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

/// Simple profile screen placeholder matching design specifications.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Name field placeholder
            Text('Name: Alex', style: AppTypography.h2),
            SizedBox(height: AppSpacing.sm),
            // Grade selector placeholder
            Text('Grade: Choose grade', style: AppTypography.body),
            SizedBox(height: AppSpacing.sm),
            // Preferences placeholder
            Text('Preferences', style: AppTypography.h2),
            SizedBox(height: AppSpacing.sm),
            // Bedtime reminder placeholder
            Text('Bedtime reminder', style: AppTypography.body),
            SizedBox(height: AppSpacing.sm),
            // Weekly assessment reminder placeholder
            Text('Weekly assessment reminder', style: AppTypography.body),
            SizedBox(height: AppSpacing.sm),
            // Default fall-asleep time placeholder
            Text('Default fall-asleep time: 15 min', style: AppTypography.body),
          ],
        ),
      ),
    );
  }
}