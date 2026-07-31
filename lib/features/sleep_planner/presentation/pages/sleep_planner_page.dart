import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../services/firestore_service.dart';
import '../../../../models/sleep_plan_model.dart';

class SleepPlannerPage extends StatefulWidget {
  const SleepPlannerPage({super.key});

  @override
  State<SleepPlannerPage> createState() => _SleepPlannerPageState();
}

class _SleepPlannerPageState extends State<SleepPlannerPage> {
  final FirestoreService _firestoreService = FirestoreService();

  // State from Lovable implementation
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: colors.primary,
            ),
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
        // Reset chosen cycle if time changes
        _chosenCycles = null;
      });
    }
  }

  // Calculate suggested bedtimes
  List<_BedtimeOption> _getOptions() {
    final List<_BedtimeOption> options = [];

    // We show exactly 3 options: 6 cycles (9h), 5 cycles (7.5h - recommended), 4 cycles (6h)
    for (int cycles in [6, 5, 4]) {
      final totalMinutes = (cycles * 90) + _latency.round();
      final bedtime = _wakeUpTime.subtract(Duration(minutes: totalMinutes));

      options.add(
        _BedtimeOption(
          cycles: cycles,
          bedtimeString: DateFormat('hh:mm a').format(bedtime),
          bedtimeDate: bedtime,
          durationMinutes: (cycles * 90),
        ),
      );
    }

    return options;
  }

  Future<void> _handleSave() async {
    final colors = Theme.of(context).colorScheme;
    if (!_hasSelectedWakeUpTime) {
      setState(() {
        _showWakeUpTimeError = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wake-up time first.')),
      );
      return;
    }

    final options = _getOptions();
    final chosenOption = options.firstWhere(
      (o) => o.cycles == (_chosenCycles ?? 5),
      orElse: () => options[1],
    );

    final sleepPlan = SleepPlan(
      planId: '',
      userId:
          'default_user', // Using default since we don't have auth state passed in here yet
      wakeUpTime: _wakeUpTime,
      createdAt: DateTime.now(),
      sleepCycles: chosenOption.cycles,
      suggestedBedtimes: options.map((o) => o.bedtimeString).toList(),
    );

    // Save to Firestore
    try {
      await _firestoreService.addSleepPlan(sleepPlan);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save plan. Check your connection and try again.'),
          action: SnackBarAction(
            label: 'Retry',
            textColor: colors.primary,
            onPressed: _handleSave,
          ),
        ),
      );
      return;
    }

    setState(() {
      _saved = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _saved = false;
        });
      }
    });
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0h';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
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
            content: const Text('You have unsaved planner changes. Do you want to discard them?'),
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
          style: GoogleFonts.inter(
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
                        'Sleep Planner',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'When should I sleep?',
                        style: GoogleFonts.sora(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wake-up time',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectWakeUpTime(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // rounded-2xl
                          border: Border.all(
                            color: _showWakeUpTimeError
                                ? colors.error
                                : colors.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          DateFormat('hh:mm a').format(_wakeUpTime),
                          style: GoogleFonts.sora(
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
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${_latency.toInt()} min',
                          style: GoogleFonts.inter(
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
                        onChanged: (val) {
                          setState(() {
                            _latency = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Constraints ──
              Text(
                'Tonight I also have…',
                style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isOn ? FontWeight.w500 : FontWeight.w400,
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
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    'Wake at ${DateFormat('HH:mm').format(_wakeUpTime)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Column(
                children: options.map((o) {
                  final isChosen = _chosenCycles == o.cycles;
                  final recommended = o.cycles == 5;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _chosenCycles = o.cycles;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isChosen
                              ? colors.primary
                              : colors.outline.withValues(alpha: 0.8),
                          width: isChosen ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.nightlight_round,
                            color: colors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.bedtimeString,
                                  style: GoogleFonts.sora(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${o.cycles} cycles • ${_formatDuration(o.durationMinutes)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (recommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: colors.secondary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Recommended',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              if (isChosen)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Icon(
                                    Icons.check,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _handleSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(                        color: colors.primary,
                        borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.60),
                          blurRadius: 30,
                          spreadRadius: -12,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_saved)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: colors.onPrimary,
                          )
                        else
                          Icon(
                            Icons.bookmark,
                            size: 18,
                            color: colors.onPrimary,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _saved ? 'Saved to history' : 'Save plan',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _BedtimeOption {
  final int cycles;
  final String bedtimeString;
  final DateTime bedtimeDate;
  final int durationMinutes;

  _BedtimeOption({
    required this.cycles,
    required this.bedtimeString,
    required this.bedtimeDate,
    required this.durationMinutes,
  });
}
