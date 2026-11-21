import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/app.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../models/sleep_plan_model.dart';
import '../../../../shared/widgets/bedtime_option_card.dart';
import '../../../../shared/widgets/planner_save_button.dart';
import '../../data/repositories/sleep_plan_repository.dart';
import '../../domain/usecases/calculate_planner_bedtimes.dart';
import '../../domain/entities/bedtime_option.dart';

class SleepPlannerPage extends StatefulWidget {
  const SleepPlannerPage({super.key, this.firestoreService});

  /// Injected by tests; the app passes nothing and gets the real service.
  final FirestoreService? firestoreService;

  @override
  State<SleepPlannerPage> createState() => _SleepPlannerPageState();
}

class _SleepPlannerPageState extends State<SleepPlannerPage> {
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService();
  late final LocalSleepPlanRepository _localRepo = LocalSleepPlanRepositoryImpl(
    appStorage!,
  );

  DateTime _wakeUpTime = DateTime.now().add(const Duration(hours: 8));
  double _latency = 15; // default 15 mins

  final List<String> _allConstraints = [
    'Homework',
    'Tutoring',
    'Project',
    'Late arrival',
    'Personal activity',
  ];
  final Set<String> _selectedConstraints = {};

  bool _hasSelectedWakeUpTime = false;
  bool _showWakeUpTimeError = false;
  int? _chosenCycles;
  bool _saved = false;
  bool _isSaving = false;

  /// The pending/failed local plan being retried, if any.
  /// Retained across retries so the same plan is synced instead of creating a new one.
  Map<String, dynamic>? _pendingLocalPlan;

  bool get _isDirty => _hasSelectedWakeUpTime || _chosenCycles != null;

  void _toggleConstraint(String c) {
    setState(() {
      if (_selectedConstraints.contains(c)) {
        _selectedConstraints.remove(c);
      } else {
        _selectedConstraints.add(c);
      }
    });
  }

  Future<void> _selectWakeUpTime(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_wakeUpTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: colors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _wakeUpTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _hasSelectedWakeUpTime = true;
        _showWakeUpTimeError = false;
        _chosenCycles = null;
        // New wake-up time means a new plan; clear any pending retry.
        _pendingLocalPlan = null;
      });
    }
  }

  List<BedtimeOption> _getOptions() {
    return CalculatePlannerBedtimes().call(
      wakeUpTime: _wakeUpTime,
      latencyMinutes: _latency.round(),
    );
  }

  Future<void> _handleSave() async {
    // A second tap while the write is in flight would create a second plan.
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _save();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    final colors = Theme.of(context).colorScheme;
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    // Validate the local inputs before touching the network: a plan needs a
    // wake-up time whether it is saved to the cloud or only on this device.
    if (!_hasSelectedWakeUpTime) {
      setState(() => _showWakeUpTimeError = true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a wake-up time first.')),
      );
      return;
    }

    final options = _getOptions();
    final chosenOption = options.firstWhere(
      (o) => o.cycles == (_chosenCycles ?? 5),
      orElse: () => options[1],
    );

    // If we have a pending local plan with the same wake-up time and cycles,
    // reuse it for retry. Otherwise create a new one.
    final reusePending =
        _pendingLocalPlan != null &&
        _pendingLocalPlan!['wakeUpTime'] == _wakeUpTime.toIso8601String() &&
        _pendingLocalPlan!['sleepCycles'] == chosenOption.cycles;

    String planId;
    DateTime createdAt;
    Map<String, dynamic> planData;

    if (reusePending) {
      // Retry: reuse the existing local plan's identity and original contents.
      planId = _pendingLocalPlan!['planId'] as String;
      createdAt = DateTime.parse(_pendingLocalPlan!['createdAt'] as String);
      planData = {
        ..._pendingLocalPlan!,
        'wakeUpTime': _wakeUpTime.toIso8601String(),
        'sleepCycles': chosenOption.cycles,
        'suggestedBedtimes': options.map((o) => o.bedtimeString).toList(),
      };
    } else {
      // New plan: generate a stable local ID and timestamp.
      planId = 'local-${DateTime.now().millisecondsSinceEpoch}';
      createdAt = DateTime.now();
      planData = {
        'planId': planId,
        'userId': 'local', // Will be updated after auth if successful
        'wakeUpTime': _wakeUpTime.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'sleepCycles': chosenOption.cycles,
        'suggestedBedtimes': options.map((o) => o.bedtimeString).toList(),
        'syncStatus': LocalSleepPlanSyncStatus.pending.name,
      };
    }

    // LOCAL-FIRST: Persist locally BEFORE any network/auth attempt.
    try {
      await _localRepo.addSleepPlan(
        SleepPlan(
          planId: planId,
          userId: planData['userId'] as String,
          wakeUpTime: _wakeUpTime,
          createdAt: createdAt,
          sleepCycles: chosenOption.cycles,
          suggestedBedtimes: options.map((o) => o.bedtimeString).toList(),
        ),
      );
      _pendingLocalPlan = planData;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save plan locally: $e')),
      );
      return;
    }

    // Now attempt authentication and cloud sync.
    final userId = await auth.ensureSignedIn();

    // If not signed in, the plan is already saved locally.
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Saved on this device only. It was not synced to the cloud — '
            'reconnect and save to sync.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: colors.primary,
            onPressed: _handleSave,
          ),
        ),
      );
      return;
    }

    // Update local plan with resolved userId.
    planData['userId'] = userId;
    await _localRepo.updateSyncStatus(planId, LocalSleepPlanSyncStatus.pending);
    _pendingLocalPlan = planData;

    // Try cloud sync with idempotent write (fixed planId).
    final sleepPlan = SleepPlan(
      planId: planId,
      userId: userId,
      wakeUpTime: _wakeUpTime,
      createdAt: createdAt,
      sleepCycles: chosenOption.cycles,
      suggestedBedtimes: options.map((o) => o.bedtimeString).toList(),
    );

    try {
      // Use the repository's idempotent save method.
      final firestoreRepo = FirestoreSleepPlanRepository(
        firestoreService: _firestoreService,
      );
      await firestoreRepo.saveSleepPlan(sleepPlan);

      if (!mounted) return;
      await _localRepo.updateSyncStatus(
        planId,
        LocalSleepPlanSyncStatus.synced,
        cloudPlanId: planId,
        attemptTime: DateTime.now(),
      );
      _pendingLocalPlan = null; // Clear pending on confirmed sync.
      _markSaved();
    } catch (e) {
      if (!mounted) return;
      // Cloud sync failed - keep local plan with failed status for retry.
      await _localRepo.updateSyncStatus(
        planId,
        LocalSleepPlanSyncStatus.failed,
        error: e.toString(),
        attemptTime: DateTime.now(),
      );
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Could not sync to cloud. Saved on this device — tap Retry to sync.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: colors.primary,
            onPressed: _handleSave,
          ),
        ),
      );
    }
  }

  void _markSaved() {
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = _getOptions();

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved planner changes. Do you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: colors.onSurface,
          elevation: 0,
          title: Text(
            'Sleep Planner',
            style: GoogleFonts.karla(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'When should I sleep?',
                          style: GoogleFonts.karla(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Inputs Card ──
                _buildInputsCard(),

                const SizedBox(height: 24),

                // ── Constraints ──
                Text(
                  'Tonight I also have…',
                  style: GoogleFonts.karla(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allConstraints.map((c) {
                    final isOn = _selectedConstraints.contains(c);
                    return GestureDetector(
                      onTap: () => _toggleConstraint(c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOn
                              ? colors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isOn ? colors.primary : colors.outline,
                          ),
                        ),
                        child: Text(
                          c,
                          style: GoogleFonts.karla(
                            fontSize: 12,
                            fontWeight: isOn
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: isOn
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // ── Suggested Bedtimes ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Suggested bedtimes',
                      style: GoogleFonts.karla(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Wake at ${DateFormat('HH:mm').format(_wakeUpTime)}',
                      style: GoogleFonts.karla(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Column(
                  children: options.map((o) {
                    return BedtimeOptionCard(
                      cycles: o.cycles,
                      bedtimeString: o.bedtimeString,
                      durationMinutes: o.durationMinutes,
                      isRecommended: o.cycles == 5,
                      isSelected: _chosenCycles == o.cycles,
                      onTap: () => setState(() => _chosenCycles = o.cycles),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Save Button ──
                PlannerSaveButton(
                  saved: _saved,
                  saving: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputsCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wake-up time',
            style: GoogleFonts.karla(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectWakeUpTime(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showWakeUpTimeError
                      ? colors.error
                      : colors.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                DateFormat('hh:mm a').format(_wakeUpTime),
                style: GoogleFonts.karla(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Time to fall asleep: ',
                style: GoogleFonts.karla(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${_latency.toInt()} min',
                style: GoogleFonts.karla(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.outline,
              thumbColor: colors.primary,
              overlayColor: colors.primary.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _latency,
              min: 0,
              max: 45,
              divisions: 9,
              onChanged: (val) => setState(() => _latency = val),
            ),
          ),
        ],
      ),
    );
  }
}
