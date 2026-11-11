import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/services/firestore_service.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/shared/widgets/history_sqi_record_card.dart';
import 'package:snoozemate/shared/widgets/history_sleep_plan_card.dart';
import 'package:snoozemate/shared/widgets/empty_state_card.dart';
import 'package:snoozemate/shared/widgets/error_state_widget.dart';
import 'package:snoozemate/shared/widgets/recommendation_bottom_sheet.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    // Recover a failed boot sign-in instead of showing a dead end; the
    // error state's Retry button re-enters here.
    final userId = await context.read<AuthService>().ensureSignedIn();
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not sign in. Check your connection and retry.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sleepPlans = await _firestoreService.getSleepPlans(userId);
      final sqiRecords = await _firestoreService.getSQIRecords(userId);
      if (!mounted) return;
      setState(() {
        _sleepPlans = sleepPlans;
        _sqiRecords = sqiRecords;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    if (_recsCache.containsKey(recordId)) {
      if (!mounted) return;
      showRecommendationSheet(context, recs: _recsCache[recordId]!);
      return;
    }

    if (!mounted) return;

    try {
      final recs = await _firestoreService.getRecommendations(
        recordId,
        record.userId,
      );
      _recsCache[recordId] = recs;
      if (!mounted) return;
      showRecommendationSheet(context, recs: recs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load recommendations.')),
      );
    }
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
                        ? ErrorStateWidget(
                            message: 'Failed to load history',
                            detail: _error,
                            onRetry: _loadHistory,
                          )
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
                      color: _selectedTab == 'sqi'
                          ? colors.onPrimary
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
                      color: _selectedTab == 'plans'
                          ? colors.onPrimary
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
      return EmptyStateCard(
        label: 'No assessments yet.',
        ctaLabel: 'Take assessment',
        onCtaPressed: () => Navigator.of(context).pushNamed('/sleep-quality'),
      );
    }

    return ListView.separated(
      itemCount: _sqiRecords.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final record = _sqiRecords[index];
        return SQIRecordCard(
          record: record,
          onTap: () => _openRecommendations(record),
          onDelete: () => _deleteSQIRecord(record.recordId),
        );
      },
    );
  }

  Widget _buildPlansList() {
    if (_sleepPlans.isEmpty) {
      return EmptyStateCard(
        label: 'No plans saved yet.',
        ctaLabel: 'Open planner',
        onCtaPressed: () => Navigator.of(context).pushNamed('/sleep-planner'),
      );
    }

    return ListView.separated(
      itemCount: _sleepPlans.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final plan = _sleepPlans[index];
        return HistorySleepPlanCard(
          plan: plan,
          onDelete: () => _deleteSleepPlan(plan.planId),
        );
      },
    );
  }
}
