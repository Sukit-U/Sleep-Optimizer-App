import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/app/app.dart';
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
import 'package:snoozemate/features/sleep_planner/data/repositories/sleep_plan_repository.dart';

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
  late final LocalSleepPlanRepository _localRepo = LocalSleepPlanRepositoryImpl(
    appStorage!,
  );
  String _selectedTab = 'sqi';

  SQIRecordReadBatch? _sqiBatch;
  SleepPlanReadBatch? _planBatch;
  List<SleepPlan> _localPlans = [];
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
    final auth = context.read<AuthService>();
    final userId = await auth.ensureSignedIn();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Load local plans first (works offline)
    try {
      if (userId != null) {
        _localPlans = await _localRepo.getSleepPlans(userId);
      } else {
        // Even without auth, show local-only plans (userId == 'local')
        _localPlans = await _localRepo.getSleepPlans('local');
      }
    } catch (e) {
      // Local load failed, continue with cloud load if possible
      debugPrint('Failed to load local plans: $e');
    }

    // If no auth, we can't load cloud plans - show local only
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _planBatch = null;
        _sqiBatch = null;
        _isLoading = false;
        _error = 'Could not sign in. Showing local plans only.';
      });
      return;
    }

    // Load cloud plans
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

  /// Combines local and cloud plans, deduplicating by planId.
  /// Local plans with syncStatus 'synced' are hidden if the cloud version exists.
  List<SleepPlan> _mergedSleepPlans() {
    final cloudPlans =
        _planBatch?.results
            .whereType<SleepPlanValid>()
            .map((r) => r.plan)
            .toList() ??
        <SleepPlan>[];

    final cloudPlanIds = cloudPlans.map((p) => p.planId).toSet();

    // Filter local plans: exclude synced ones that have a cloud counterpart
    final localToShow = _localPlans.where((local) {
      // Exclude local plans that are marked as synced and have a matching cloud plan
      if (local.syncStatus == LocalSleepPlanSyncStatus.synced &&
          cloudPlanIds.contains(local.planId)) {
        return false;
      }
      // Exclude local plans that have the same planId as a cloud plan (any status)
      if (cloudPlanIds.contains(local.planId)) {
        return false;
      }
      return true;
    }).toList();

    // Merge: cloud plans first (most recent), then local-only plans
    final merged = <SleepPlan>[];
    merged.addAll(cloudPlans);
    merged.addAll(localToShow);

    // Sort by createdAt descending
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  List<SleepPlan> _validSleepPlans() {
    // Use merged list for display
    return _mergedSleepPlans();
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

    // Check if it's a local-only plan (not in cloud)
    final isLocalOnly =
        _localPlans.any((p) => p.planId == planId) &&
        !(_planBatch?.results.whereType<SleepPlanValid>().any(
              (r) => r.plan.planId == planId,
            ) ??
            false);

    if (isLocalOnly) {
      // Delete from local storage only
      try {
        await _localRepo.deleteLocalPlan(planId);
        if (!mounted) return;
        await _loadHistory();
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Could not delete local plan: $e')),
        );
      }
      return;
    }

    // Cloud plan - delete from cloud first (source of truth).
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

    // Cloud deletion succeeded; remove the local copy too so it cannot
    // resurrect on the next load. If local deletion fails, tombstone the id
    // so the stale local copy is filtered out.
    try {
      await _localRepo.deleteLocalPlan(planId);
    } catch (e) {
      // Cloud is gone; tombstone locally so the stale copy does not reappear.
      try {
        await appStorage?.markSleepPlanDeleted(planId);
      } catch (_) {
        // Best effort; loadLocalSleepPlans filters tombstoned ids.
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Plan deleted from cloud. Local cleanup failed: $e'),
        ),
      );
      await _loadHistory();
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
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
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
        border: Border.all(color: colors.outline),
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

    if (validPlans.isEmpty && legacyCount == 0) {
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
        border: Border.all(color: colors.outline),
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
