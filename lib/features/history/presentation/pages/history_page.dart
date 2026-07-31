import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/services/firestore_service.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';
import 'package:snoozemate/models/recommendation_model.dart';

class HistoryPage extends StatefulWidget {
  final String userId;

  const HistoryPage({super.key, this.userId = 'default_user'});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedTab = 'sqi';
  List<SQIRecord> _sqiRecords = [];
  List<SleepPlan> _sleepPlans = [];
  bool _isLoading = true;
  String? _error;

  // Recommendation cache: recordId -> list of recommendations
  final Map<String, List<Recommendation>> _recsCache = {};
  final Set<String> _recsLoading = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sleepPlans = await _firestoreService.getSleepPlans(widget.userId);
      final sqiRecords = await _firestoreService.getSQIRecords(widget.userId);
      // Results are already sorted by FirestoreService (orderBy createdAt desc)
      setState(() {
        _sleepPlans = sleepPlans;
        _sqiRecords = sqiRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteSQIRecord(String recordId) async {
    try {
      await _firestoreService.deleteSQIRecord(recordId);
      _recsCache.remove(recordId);
      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete record: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteSleepPlan(String planId) async {
    try {
      await _firestoreService.deleteSleepPlan(planId);
      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete plan: ${e.toString()}')),
      );
    }
  }

  Future<void> _openRecommendations(SQIRecord record) async {
    final recordId = record.recordId;
    // Use cache if available
    if (_recsCache.containsKey(recordId)) {
      if (!mounted) return;
      _showRecsSheet(_recsCache[recordId]!);
      return;
    }

    // Mark loading and show a loading bottom sheet
    if (!mounted) return;
    _recsLoading.add(recordId);

    try {
      final recs = await _firestoreService.getRecommendations(recordId);
      _recsCache[recordId] = recs;
      _recsLoading.remove(recordId);
      if (!mounted) return;
      _showRecsSheet(recs);
    } catch (e) {
      _recsLoading.remove(recordId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load recommendations.')),
      );
    }
  }

  void _showRecsSheet(List<Recommendation> recs) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (ctx, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.px),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radius2xl)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: AppSpacing.iconMd, color: colors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Recommendations',
                    style: AppTypography.h2.copyWith(color: colors.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (recs.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No recommendations recorded for this assessment.',
                      style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: recs.map(_buildRecItem).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecItem(Recommendation rec) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: AppSpacing.cardShadow,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Text(
                  rec.priority,
                  style: AppTypography.small.copyWith(color: colors.primary),
                ),
              ),
              Text(
                rec.factor,
                style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            rec.title,
            style: AppTypography.h3.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            rec.description,
            style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Action: ${rec.action}',
            style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: AppTypography.h1.copyWith(color: colors.onSurface)),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.px,
            vertical: AppSpacing.py,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              _buildSegmentedControl(),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState()
                        : _selectedTab == 'sqi'
                            ? _buildSQIList()
                            : _buildPlansList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingXs),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'sqi'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedTab == 'sqi' ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Center(
                  child: Text(
                    'SQI records',
                    style: AppTypography.tabLabel.copyWith(
                      color: _selectedTab == 'sqi'          ? colors.onPrimary
          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'plans'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedTab == 'plans' ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Center(
                  child: Text(
                    'Sleep plans',
                    style: AppTypography.tabLabel.copyWith(
                      color: _selectedTab == 'plans'          ? colors.onPrimary
          : colors.onSurfaceVariant,
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

  Widget _buildSQIList() {
    if (_sqiRecords.isEmpty) {
      return _buildEmptyState(
        label: 'No assessments yet.',
        cta: 'Take assessment',
      );
    }

    return ListView.separated(
      itemCount: _sqiRecords.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final record = _sqiRecords[index];
        return _buildSQIItem(record);
      },
    );
  }

  Widget _buildSQIItem(SQIRecord record) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openRecommendations(record),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [BoxShadow(blurRadius: AppSpacing.cardShadow, color: colors.shadow.withValues(alpha: 0.45), offset: Offset(0, AppSpacing.defaultSpacing - 6))],
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconXl,
            height: AppSpacing.iconXl,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: AppSpacing.iconMd,
              color: colors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${record.sqiScore}',
                      style: AppTypography.h2.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· ${record.sleepQualityLevel}',
                      style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingXs),
                Text(
                  _formatDate(record.createdAt),
                  style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteSQIRecord(record.recordId),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                size: AppSpacing.iconMd,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildPlansList() {
    if (_sleepPlans.isEmpty) {
      return _buildEmptyState(
        label: 'No plans saved yet.',
        cta: 'Open planner',
      );
    }

    return ListView.separated(
      itemCount: _sleepPlans.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final plan = _sleepPlans[index];
        return _buildPlanItem(plan);
      },
    );
  }

  Widget _buildPlanItem(SleepPlan plan) {
    final colors = Theme.of(context).colorScheme;
    final firstBedtime = plan.suggestedBedtimes.isNotEmpty ? plan.suggestedBedtimes.first : '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [BoxShadow(blurRadius: AppSpacing.cardShadow, color: colors.shadow.withValues(alpha: 0.45), offset: Offset(0, AppSpacing.defaultSpacing - 6))],
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconXl,
            height: AppSpacing.iconXl,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.roundedSm),
            ),
            child: Icon(
              Icons.nightlight_round,
              size: AppSpacing.iconMd,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstBedtime → ${_formatTime(plan.wakeUpTime)}',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppSpacing.spacingXs),
                Text(
                  '${plan.sleepCycles} cycles · ${_formatDate(plan.createdAt)}',
                  style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteSleepPlan(plan.planId),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                size: AppSpacing.iconMd,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String label, required String cta}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [BoxShadow(blurRadius: AppSpacing.cardShadow, color: colors.shadow.withValues(alpha: 0.45), offset: Offset(0, AppSpacing.defaultSpacing - 6))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                _selectedTab == 'sqi' ? '/sleep-quality' : '/sleep-planner',
              );
            },
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
                cta,
                style: AppTypography.button.copyWith(color: colors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load history',
            style: AppTypography.body.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error ?? '',
            style: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: _loadHistory,
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
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}