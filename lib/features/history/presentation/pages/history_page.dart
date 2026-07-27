import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';

/// History screen – UI implementation matching Lovable design.
/// Shows both SQI records and Sleep plans with tabbed navigation.
class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Tab state: 'sqi' or 'plans'
  String _selectedTab = 'sqi';

  // Placeholder data for SQI records
  final List<Map<String, dynamic>> _sqiRecords = [
    {'id': '1', 'score': 85, 'quality': 'Excellent', 'date': DateTime.now().subtract(const Duration(days: 1))},
    {'id': '2', 'score': 72, 'quality': 'Good', 'date': DateTime.now().subtract(const Duration(days: 3))},
    {'id': '3', 'score': 68, 'quality': 'Fair', 'date': DateTime.now().subtract(const Duration(days: 5))},
  ];

  // Placeholder data for Sleep plans
  final List<Map<String, dynamic>> _sleepPlans = [
    {'id': '1', 'bedtime': '10:30 PM', 'wakeUp': '6:00 AM', 'cycles': 5, 'date': DateTime.now().subtract(const Duration(days: 2))},
    {'id': '2', 'bedtime': '11:00 PM', 'wakeUp': '7:00 AM', 'cycles': 6, 'date': DateTime.now().subtract(const Duration(days: 4))},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.px,
            vertical: AppSpacing.py,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: AppSpacing.iconButtonSize,
                      height: AppSpacing.iconButtonSize,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: AppSpacing.iconMd,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Screen title
                  Text(
                    'History',
                    style: AppTypography.h1.copyWith(color: AppColors.foreground),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Segmented control (SQI records / Sleep plans)
              _buildSegmentedControl(),
              const SizedBox(height: AppSpacing.lg),

              // Content based on selected tab
              Expanded(
                child: _selectedTab == 'sqi' ? _buildSQIList() : _buildPlansList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Segmented control with rounded-full pill style matching Lovable
  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingXs),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // SQI records tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'sqi'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedTab == 'sqi' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Center(
                  child: Text(
                    'SQI records',
                    style: AppTypography.tabLabel.copyWith(
                      color: _selectedTab == 'sqi'
                          ? AppColors.primaryForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sleep plans tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'plans'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedTab == 'plans' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Center(
                  child: Text(
                    'Sleep plans',
                    style: AppTypography.tabLabel.copyWith(
                      color: _selectedTab == 'plans'
                          ? AppColors.primaryForeground
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SQI Records list with ClipboardList icon
  Widget _buildSQIList() {
    if (_sqiRecords.isEmpty) {
      return _buildEmptyState(
        label: 'No assessments yet.',
        cta: 'Take assessment',
      );
    }

    return ListView.separated(
      itemCount: _sqiRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final record = _sqiRecords[index];
        return _buildSQIItem(record);
      },
    );
  }

  /// Single SQI record item
  Widget _buildSQIItem(Map<String, dynamic> record) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [BoxShadow(blurRadius: AppSpacing.cardShadow, color: AppColors.shadow.withOpacity(0.45), offset: Offset(0, AppSpacing.defaultSpacing - 6))],
      ),
      child: Row(
        children: [
          // ClipboardList icon
          Container(
            width: AppSpacing.iconXl,
            height: AppSpacing.iconXl,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: AppSpacing.iconMd,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${record['score']}',
                      style: AppTypography.h2.copyWith(color: AppColors.foreground),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· ${record['quality']}',
                      style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingXs),
                Text(
                  _formatDate(record['date'] as DateTime),
                  style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () {
              // Delete logic here
              setState(() {
                _sqiRecords.removeWhere((r) => r['id'] == record['id']);
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                size: AppSpacing.iconMd,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sleep plans list with Moon icon
  Widget _buildPlansList() {
    if (_sleepPlans.isEmpty) {
      return _buildEmptyState(
        label: 'No plans saved yet.',
        cta: 'Open planner',
      );
    }

    return ListView.separated(
      itemCount: _sleepPlans.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final plan = _sleepPlans[index];
        return _buildPlanItem(plan);
      },
    );
  }

  /// Single sleep plan item
  Widget _buildPlanItem(Map<String, dynamic> plan) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [BoxShadow(blurRadius: AppSpacing.cardShadow, color: AppColors.shadow.withOpacity(0.45), offset: Offset(0, AppSpacing.defaultSpacing - 6))],
      ),
      child: Row(
        children: [
          // Moon icon
          Container(
            width: AppSpacing.iconXl,
            height: AppSpacing.iconXl,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
            ),
            child: const Icon(
              Icons.nightlight_round,
              size: AppSpacing.iconMd,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan['bedtime']} → ${plan['wakeUp']}',
                  style: AppTypography.h3.copyWith(color: AppColors.foreground),
                ),
                const SizedBox(height: AppSpacing.spacingXs),
                Text(
                  '${plan['cycles']} cycles · ${_formatDate(plan['date'] as DateTime)}',
                  style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () {
              // Delete logic here
              setState(() {
                _sleepPlans.removeWhere((p) => p['id'] == plan['id']);
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                size: AppSpacing.iconMd,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state component
  Widget _buildEmptyState({required String label, required String cta}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [BoxShadow(blurRadius: AppSpacing.cardShadow, color: AppColors.shadow.withOpacity(0.45), offset: Offset(0, AppSpacing.defaultSpacing - 6))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () {
              // Navigation to respective page
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
              ),
              child: Text(
                cta,
                style: AppTypography.button.copyWith(color: AppColors.primaryForeground),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format time for display
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}