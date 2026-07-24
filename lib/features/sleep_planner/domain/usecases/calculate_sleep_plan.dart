import 'package:flutter/material.dart';

import '../entities/sleep_plan.dart';

class CalculateSleepPlan {
  SleepPlanEntity call({required TimeOfDay wakeUpTime}) {
    const cycleDurationMinutes = 90;
    const sleepLatencyMinutes = 15;
    const cycleCount = 6;

    final wakeUpTotalMinutes = wakeUpTime.hour * 60 + wakeUpTime.minute;
    final totalSleepMinutes = (cycleCount * cycleDurationMinutes) - sleepLatencyMinutes;

    final bedtimeOptions = <String>[
      _formatMinutes(wakeUpTotalMinutes - (cycleCount * cycleDurationMinutes)),
      _formatMinutes(wakeUpTotalMinutes - (cycleCount - 1) * cycleDurationMinutes),
      _formatMinutes(wakeUpTotalMinutes - (cycleCount - 2) * cycleDurationMinutes),
    ];

    return SleepPlanEntity(
      wakeUpTime: wakeUpTime,
      suggestedBedtimes: bedtimeOptions,
      sleepCycles: cycleCount,
      sleepDuration: _formatDuration(totalSleepMinutes),
    );
  }

  String _formatMinutes(int totalMinutes) {
    final normalized = ((totalMinutes % 1440) + 1440) % 1440;
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$normalizedHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
