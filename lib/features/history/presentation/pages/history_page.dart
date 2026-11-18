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
import 'package:snoozemate/features/history/presentation/widgets/delete_sleep_plan_dialog.dart';
import 'package:snoozemate/features/history/presentation/widgets/delete_sqi_record_dialog.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.firestoreService});

  /// Injected by tests; production falls back to the real service.
  final FirestoreService? firestoreService;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();
  String _selectedTab = 'sqi';

  SQIRecordReadBatch? _sqiBatch;
  SleepPlanReadBatch? _planBatch;
  bool _isLoading = true;
  String? _error;

  // Recommendation cache: recordId -> valid recommendations only.
  final Map<String, List<Recommendation>> _recsCache = {};
  final Map<String, int> _recsUnavailableCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
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
      final planBatch = await _firestoreService.getSleepPlans(userId);
      final sqiBatch = await _firestoreService.getSQIRecords(userId);
      if (!mounted) return;
      setState(() {
        _planBatch = planBatch;
        _sqiBatch = sqiBatch;
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

  List<SQIRecord> _validSqiRecords() {
    return _sqiBatch?.results
            .whereType<SQIRecordValid>()
            .map((r) => r.record)
            .toList() ??
        <SQIRecord>[];
  }

  List<SleepPlan> _validSleepPlans() {
    return _planBatch?.results
            .whereType<SleepPlanValid>()
            .map((r) => r.plan)
            .toList() ??
        <SleepPlan>[];
  }

  Future<void> _deleteSQIRecord(String recordId) async {
    final confirmed = await confirmDeleteSqiRecord(context);
    if (!confirmed || !mounted) return;

    final userId = context.read<AuthService>().uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not sign in. Check your connection and try again.',
          ),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _firestoreService.deleteSqiRecordWithRecommendations(
        recordId: recordId,
        userId: userId,
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text(sqiDeleteUnconfirmedMessage),
          action: SnackBarAction(label: 'Refresh', onPressed: _loadHistory),
        ),
      );
      return;
    }

    if (!mounted) return;
    _recsCache.remove(recordId);
    _recsUnavailableCounts.remove(recordId);
    await _loadHistory();
  }

  Future<void> _deleteSleepPlan(String planId) async {
    final confirmed = await confirmDeleteSleepPlan(context);
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _firestoreService.deleteSleepPlan(planId);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text(sleepPlanDeleteUnconfirmedMessage),
          action: SnackBarAction(label: 'Refresh', onPressed: _loadHistory),
        ),
      );
      return;
    }

    if (!mounted) return;
    await _loadHistory();
  }

  Future<void> _openRecommendations(String recordId, String userId) async {
    if (_recsCache.containsKey(recordId)) {
      if (!mounted) return;
      showRecommendationSheet(
        context,
        recs: _recsCache[recordId]!,
        unavailableCount: _recsUnavailableCounts[recordId] ?? 0,
      );
      return;
    }

    if (!mounted) return;

    try {
      final batch = await _firestoreService.getRecommendations(
        recordId,
        userId,
      );
      final valid = batch.results
          .whereType<RecommendationValid>()
          .map((r) => r.record)
          .toList();
      _recsCache[recordId] = valid;
      _recsUnavailableCounts[recordId] = batch.legacyCount + batch.invalidCount;
      if (!mounted) return;
      showRecommendationSheet(
        context,
        recs: valid,
        unavailableCount: batch.legacyCount + batch.invalidCount,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load recommendations.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
          style: AppTypography.h1.copyWith(color: colors.onSurface),
        ),
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
                  color: _selectedTab == 'sqi'
                      ? colors.primary
                      : Colors.transparent,
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
                  color: _selectedTab == 'plans'
                      ? colors.primary
                      : Colors.transparent,
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
    final batch = _sqiBatch;
    final validRecords = _validSqiRecords();
    final legacyCount = batch?.legacyCount ?? 0;
    final invalidCount = batch?.invalidCount ?? 0;
    final total = batch?.results.length ?? 0;

    if (total == 0) {
      return EmptyStateCard(
        label: 'No assessments yet.',
        ctaLabel: 'Take assessment',
        onCtaPressed: () => Navigator.of(context).pushNamed('/sleep-quality'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invalidCount > 0)
          _unreadableBanner(
            '$invalidCount record(s) could not be read and are hidden.',
          ),
        Expanded(
          child: ListView.separated(
            itemCount: validRecords.length + legacyCount,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index < validRecords.length) {
                final record = validRecords[index];
                return SQIRecordCard(
                  record: record,
                  onTap: () =>
                      _openRecommendations(record.recordId, record.userId),
                  onDelete: () => _deleteSQIRecord(record.recordId),
                );
              }
              final legacyIndex = index - validRecords.length;
              final legacy = batch!.results
                  .whereType<SQIRecordLegacy>()
                  .elementAt(legacyIndex);
              return _legacySQIRow(legacy);
            },
          ),
        ),
      ],
    );
  }

  Widget _legacySQIRow(SQIRecordLegacy legacy) {
    final partial = legacy.partial;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [
          BoxShadow(
            blurRadius: AppSpacing.cardShadow,
            color: colors.shadow.withValues(alpha: 0.45),
            offset: Offset(0, AppSpacing.defaultSpacing - 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${partial.sqiScore ?? '?'}',
                style: AppTypography.h2.copyWith(color: colors.onSurface),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '· ${partial.sleepQualityLevel ?? 'quality level unavailable'}',
                style: AppTypography.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Text(
                  'legacy record',
                  style: AppTypography.small.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
          if (partial.createdAt != null) ...[
            const SizedBox(height: AppSpacing.spacingXs),
            Text(
              _formatDate(partial.createdAt!),
              style: AppTypography.caption.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (!partial.questionnaireComplete)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacingXs),
              child: Text(
                'Questionnaire details unavailable for this record.',
                style: AppTypography.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    final batch = _planBatch;
    final validPlans = _validSleepPlans();
    final legacyCount = batch?.legacyCount ?? 0;
    final invalidCount = batch?.invalidCount ?? 0;
    final total = batch?.results.length ?? 0;

    if (total == 0) {
      return EmptyStateCard(
        label: 'No plans saved yet.',
        ctaLabel: 'Open planner',
        onCtaPressed: () => Navigator.of(context).pushNamed('/sleep-planner'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invalidCount > 0)
          _unreadableBanner(
            '$invalidCount plan(s) could not be read and are hidden.',
          ),
        Expanded(
          child: ListView.separated(
            itemCount: validPlans.length + legacyCount,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index < validPlans.length) {
                final plan = validPlans[index];
                return HistorySleepPlanCard(
                  plan: plan,
                  onDelete: () => _deleteSleepPlan(plan.planId),
                );
              }
              final legacyIndex = index - validPlans.length;
              final legacy = batch!.results
                  .whereType<SleepPlanLegacy>()
                  .elementAt(legacyIndex);
              return _legacyPlanRow(legacy);
            },
          ),
        ),
      ],
    );
  }

  Widget _legacyPlanRow(SleepPlanLegacy legacy) {
    final partial = legacy.partial;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
        boxShadow: [
          BoxShadow(
            blurRadius: AppSpacing.cardShadow,
            color: colors.shadow.withValues(alpha: 0.45),
            offset: Offset(0, AppSpacing.defaultSpacing - 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                partial.verifiedBedtimeEntries.isNotEmpty
                    ? partial.verifiedBedtimeEntries.first
                    : 'bedtime unavailable',
                style: AppTypography.h3.copyWith(color: colors.onSurface),
              ),
              if (partial.wakeUpTime != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '→ ${_formatTime(partial.wakeUpTime!)}',
                  style: AppTypography.h3.copyWith(color: colors.onSurface),
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.roundedFull),
                ),
                child: Text(
                  'legacy record',
                  style: AppTypography.small.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
          if (partial.createdAt != null || partial.sleepCycles != null) ...[
            const SizedBox(height: AppSpacing.spacingXs),
            Text(
              '${partial.sleepCycles ?? '?'} cycles · ${partial.createdAt != null ? _formatDate(partial.createdAt!) : 'date unavailable'}',
              style: AppTypography.caption.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _unreadableBanner(String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.roundedLg),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colors.error,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: colors.onErrorContainer,
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
    if (difference.inDays == 0) return 'Today, ${_formatTime(dateTime)}';
    if (difference.inDays == 1) return 'Yesterday, ${_formatTime(dateTime)}';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
