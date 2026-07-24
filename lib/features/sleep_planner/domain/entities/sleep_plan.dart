import 'package:flutter/material.dart';

class SleepPlanEntity {
  const SleepPlanEntity({
    required this.wakeUpTime,
    required this.suggestedBedtimes,
    required this.sleepCycles,
    required this.sleepDuration,
  });

  final TimeOfDay wakeUpTime;
  final List<String> suggestedBedtimes;
  final int sleepCycles;
  final String sleepDuration;
}
