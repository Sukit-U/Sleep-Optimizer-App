import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_planner/domain/entities/planned_bedtime_evaluation.dart';
import 'package:snoozemate/features/sleep_planner/domain/usecases/evaluate_planned_bedtime.dart';

void main() {
  const usecase = EvaluatePlannedBedtime();

  // ---- Date interpretation rule ----

  test('planned 03:00, wake 07:00 -> same date, 4 hours in bed', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 3 * 60, // 03:00
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.timeInBedMinutes, 4 * 60);
    expect(result.status, PlannedBedtimeStatus.sufficient);
  });

  test('planned 23:00, wake 07:00 -> previous date, 8 hours in bed', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 23 * 60, // 23:00
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.timeInBedMinutes, 8 * 60);
    expect(result.status, PlannedBedtimeStatus.sufficient);
  });

  test('planned 00:30, wake 07:00 -> same date, 6.5 hours in bed', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 0 * 60 + 30, // 00:30
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.timeInBedMinutes, 6 * 60 + 30);
    expect(result.status, PlannedBedtimeStatus.sufficient);
  });

  test('planned 23:00, wake 01:00 -> previous date, 2 hours in bed', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 23 * 60, // 23:00
      wakeUpTime: DateTime(2024, 1, 15, 1, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.timeInBedMinutes, 2 * 60);
    expect(result.status, PlannedBedtimeStatus.sufficient);
  });

  test(
    'cross-year rollover: planned 23:00, wake 01:00 Jan 1 -> Dec 31 prev year',
    () {
      final result = usecase.call(
        plannedBedtimeMinutesFromMidnight: 23 * 60,
        wakeUpTime: DateTime(2024, 1, 1, 1, 0),
        sleepLatencyMinutes: 0,
        targetMinutes: 0,
        readyToSleepMinutesFromMidnight: null,
      );

      expect(result.timeInBedMinutes, 2 * 60);
      expect(result.status, PlannedBedtimeStatus.sufficient);
    },
  );

  test(
    'cross-month rollover: planned 23:00, wake 01:00 Mar 1 -> Feb last day',
    () {
      final result = usecase.call(
        plannedBedtimeMinutesFromMidnight: 23 * 60,
        wakeUpTime: DateTime(2024, 3, 1, 1, 0),
        sleepLatencyMinutes: 0,
        targetMinutes: 0,
        readyToSleepMinutesFromMidnight: null,
      );

      expect(result.timeInBedMinutes, 2 * 60);
      expect(result.status, PlannedBedtimeStatus.sufficient);
    },
  );

  test('equal planned bedtime and wake-up clock times -> 0 hours in bed', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 7 * 60, // 07:00
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 1 * 60, // 1 hour target
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.timeInBedMinutes, 0);
    expect(result.status, PlannedBedtimeStatus.insufficient);
  });

  // ---- Duration formulas ----

  test('8 hours in bed, 15-minute latency = 7h45m estimated sleep', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 23 * 60, // 23:00
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 15,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.timeInBedMinutes, 8 * 60);
    expect(result.estimatedSleepMinutes, 7 * 60 + 45);
  });

  test('estimated below target -> insufficient', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 0 * 60, // 00:00
      wakeUpTime: DateTime(2024, 1, 15, 6, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 8 * 60, // 8 hours target
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.estimatedSleepMinutes, 6 * 60);
    expect(result.status, PlannedBedtimeStatus.insufficient);
    expect(result.reasonCodes, contains('belowTarget'));
  });

  test('estimated equal to target -> sufficient', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 22 * 60, // 22:00
      wakeUpTime: DateTime(2024, 1, 15, 6, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 8 * 60,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.estimatedSleepMinutes, 8 * 60);
    expect(result.status, PlannedBedtimeStatus.sufficient);
    expect(result.reasonCodes, contains('atOrAboveTarget'));
  });

  test('estimated above target -> sufficient', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 20 * 60, // 20:00
      wakeUpTime: DateTime(2024, 1, 15, 6, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 8 * 60,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.estimatedSleepMinutes, 10 * 60);
    expect(result.status, PlannedBedtimeStatus.sufficient);
  });

  test('null planned bedtime -> notSet, no warning', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: null,
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 15,
      targetMinutes: 8 * 60,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.status, PlannedBedtimeStatus.notSet);
    expect(result.isNotSet, isTrue);
    expect(result.hasConflictWithReadyToSleep, isFalse);
    expect(result.reasonCodes, isEmpty);
  });

  test('latency greater than time in bed -> estimated clamped to 0', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 6 * 60 + 30, // 06:30 (30 min in bed)
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 45,
      targetMinutes: 8 * 60,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.timeInBedMinutes, 30);
    expect(result.estimatedSleepMinutes, 0);
    expect(result.status, PlannedBedtimeStatus.insufficient);
  });

  // ---- Conflict handling ----

  test('planned bedtime earlier than ready-to-sleep -> conflict', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 22 * 60, // 22:00
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 8 * 60,
      readyToSleepMinutesFromMidnight: 23 * 60, // 23:00
    );

    expect(result.hasConflictWithReadyToSleep, isTrue);
    expect(result.reasonCodes, contains('conflictWithReadyToSleep'));
  });

  test('conflict does not change sufficiency status', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 22 * 60, // 22:00
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 6 * 60,
      readyToSleepMinutesFromMidnight: 23 * 60,
    );

    // 9 hours in bed - sufficient despite conflict
    expect(result.status, PlannedBedtimeStatus.sufficient);
    expect(result.hasConflictWithReadyToSleep, isTrue);
  });

  test('no conflict when planned bedtime equals ready-to-sleep time', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 23 * 60,
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: 23 * 60,
    );

    expect(result.hasConflictWithReadyToSleep, isFalse);
  });

  test('no conflict when planned bedtime later than ready-to-sleep time', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 0 * 60 + 30, // 00:30
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: 23 * 60,
    );

    expect(result.hasConflictWithReadyToSleep, isFalse);
  });

  test('no conflict when ready-to-sleep time is null', () {
    final result = usecase.call(
      plannedBedtimeMinutesFromMidnight: 22 * 60,
      wakeUpTime: DateTime(2024, 1, 15, 7, 0),
      sleepLatencyMinutes: 0,
      targetMinutes: 0,
      readyToSleepMinutesFromMidnight: null,
    );

    expect(result.hasConflictWithReadyToSleep, isFalse);
  });
}
