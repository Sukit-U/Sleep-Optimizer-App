import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snoozemate/features/sleep_planner/domain/usecases/calculate_sleep_plan.dart';

void main() {
  test('calculates suggested bedtimes based on wake-up time and sleep cycles', () {
    final result = CalculateSleepPlan().call(
      wakeUpTime: const TimeOfDay(hour: 7, minute: 0),
    );

    expect(result.suggestedBedtimes, hasLength(3));
    expect(result.sleepCycles, 6);
    expect(result.sleepDuration, '8h 45m');
  });
}
