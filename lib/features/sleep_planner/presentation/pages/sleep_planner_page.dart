import 'package:flutter/material.dart';
import 'package:snoozemate/core/theme/app_colors.dart';
import 'package:snoozemate/core/theme/app_spacing.dart';
import 'package:snoozemate/core/theme/app_typography.dart';
import 'package:snoozemate/core/presentation/widgets/app_button.dart';

class BedtimeOption {
  final String bedtime;
  final int cycles;
  final int durationMinutes;

  BedtimeOption({
    required this.bedtime,
    required this.cycles,
    required this.durationMinutes,
  });
}

String formatDuration(int minutes) {
  int hours = minutes ~/ 60;
  int mins = minutes % 60;
  return '${hours}h ${mins}m';
}

/// Sleep Planner screen – UI only implementation.
/// Preserves any existing business logic/calculation functions (e.g. `calculateBedtime`);
/// this file focuses solely on the visual layout according to CompleteScreenSpecifications,
/// Design‑System.md and UI‑Guidelines.md.
class SleepPlannerPage extends StatefulWidget {
  const SleepPlannerPage({super.key});

  @override
  State<SleepPlannerPage> createState() => _SleepPlannerPageState();
}

class _SleepPlannerPageState extends State<SleepPlannerPage> {
  // Selected bedtime – UI only, assumes a calculation function exists elsewhere.
  TimeOfDay? _selectedTime;
  int _latencyMinutes = 15; // Default latency minutes
  final List<String> _constraints = []; // Constraints selection state
  static const List<String> constraintsList = [ // Available constraints
    "Homework",
    "Tutoring",
    "Project",
    "Late arrival",
    "Personal activity",
  ];
  List<BedtimeOption> bedtimeOptions = []; // Will be populated based on _selectedTime
  BedtimeOption? _chosenBedtime; // Currently selected bedtime option
  
  void _handleSavePlan() {
    // Here you would typically save the plan to your data store
    // For now, we'll just print the selected bedtime
    if (_chosenBedtime != null) {
      print('Saving plan: Bedtime at ${_chosenBedtime!.bedtime}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan saved: Bedtime at ${_chosenBedtime!.bedtime}')),
      );
    }
  }

// Placeholder for a calculation call; the actual implementation resides in the
// business‑logic layer and is not modified here.

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 22, minute: 0),
      builder: (context, child) {
        // Apply design‑system theming to the picker dialog.
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.card,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.card,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

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
          // Header with back navigation and title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  child: Icon(Icons.arrow_left, size: AppSpacing.iconMd),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Planner',
                    style: AppTypography.body.copyWith(color: AppColors.mutedForeground),
                  ),
                  Text(
                    'When should I sleep?',
                    style: AppTypography.h1.copyWith(color: AppColors.foreground),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Wake-up time input
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: AppSpacing.radiusLg,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wake-up time',
                  style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                ),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppSpacing.radius2xl,
                    ),
                    child: Text(
                      _selectedTime == null ? '--:--' : _selectedTime!.format(context),
                      style: AppTypography.displaySmall.copyWith(color: AppColors.foreground),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Latency slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time to fall asleep: ${_latencyMinutes} min',
                      style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                    ),
                    Slider(
                      value: _latencyMinutes.toDouble(),
                      min: 0,
                      max: 45,
                      divisions: 9,
                      label: '${_latencyMinutes} min',
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _latencyMinutes = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Constraints section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tonight I also have…',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: constraintsList.map((constraint) {
                  bool isSelected = _constraints.contains(constraint);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _constraints.remove(constraint);
                        } else {
                          _constraints.add(constraint);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.card,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        borderRadius: AppSpacing.radiusFull,
                      ),
                      child: Text(
                        constraint,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Suggested bedtimes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggested bedtimes',
                style: AppTypography.h2.copyWith(color: AppColors.foreground),
              ),
              Text(
                'Wake at ${_selectedTime?.format(context)}',
                style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Bedtime options
          Column(
            children: bedtimeOptions.map((option) {
              bool isSelected = _chosenBedtime?.bedtime == option.bedtime;
              bool isRecommended = option.cycles == 5; // Assuming 5 cycles is recommended
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _chosenBedtime = option;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppSpacing.radiusLg,
                    boxShadow: isSelected ? [AppSpacing.cardShadow] : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.nightlight_round, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.bedtime,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.foreground),
                          ),
                          Text(
                            '${option.cycles} cycles · ${formatDuration(option.durationMinutes)}',
                            style: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: AppSpacing.radiusSm,
                          ),
                          child: Text(
                            'Recommended',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                      if (isSelected)
                        Icon(Icons.check, color: AppColors.primary, size: AppSpacing.iconSm),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Save button
          AppButton(
            label: 'Save plan',
            onPressed: _handleSavePlan,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
          ),
        ],
      ),
    ),
  ),
);
  }
}