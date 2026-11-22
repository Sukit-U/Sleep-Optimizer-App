import '../entities/planned_bedtime_evaluation.dart';

/// Evaluates the user's manually entered Planned Bedtime against their
/// wake-up time, sleep latency, and target sleep duration.
///
/// The date interpretation rule:
/// - If Planned Bedtime clock time <= Wake-up clock time: same calendar date.
/// - If Planned Bedtime clock time > Wake-up clock time: previous calendar date.
///
/// Returns structured status/reason codes. No localized messages are
/// hardcoded here; the Presentation Layer resolves messages.
class EvaluatePlannedBedtime {
  const EvaluatePlannedBedtime();

  PlannedBedtimeEvaluation call({
    required int? plannedBedtimeMinutesFromMidnight,
    required DateTime wakeUpTime,
    required int sleepLatencyMinutes,
    required int targetMinutes,
    required int? readyToSleepMinutesFromMidnight,
  }) {
    if (plannedBedtimeMinutesFromMidnight == null) {
      return const PlannedBedtimeEvaluation(
        status: PlannedBedtimeStatus.notSet,
        timeInBedMinutes: 0,
        estimatedSleepMinutes: 0,
        targetMinutes: 0,
        hasConflictWithReadyToSleep: false,
        reasonCodes: <String>[],
      );
    }

    final wakeMinutesFromMidnight = wakeUpTime.hour * 60 + wakeUpTime.minute;
    final plannedHour = plannedBedtimeMinutesFromMidnight ~/ 60;
    final plannedMinute = plannedBedtimeMinutesFromMidnight % 60;

    // Date interpretation rule: compare clock times (not formatted strings).
    DateTime plannedDateTime;
    if (plannedBedtimeMinutesFromMidnight <= wakeMinutesFromMidnight) {
      plannedDateTime = DateTime(
        wakeUpTime.year,
        wakeUpTime.month,
        wakeUpTime.day,
        plannedHour,
        plannedMinute,
      );
    } else {
      final previousDay = wakeUpTime.subtract(const Duration(days: 1));
      plannedDateTime = DateTime(
        previousDay.year,
        previousDay.month,
        previousDay.day,
        plannedHour,
        plannedMinute,
      );
    }

    final timeInBedMinutes = wakeUpTime.difference(plannedDateTime).inMinutes;
    final rawEstimatedMinutes = timeInBedMinutes - sleepLatencyMinutes;
    final estimatedSleepMinutes = rawEstimatedMinutes < 0
        ? 0
        : rawEstimatedMinutes;

    final reasonCodes = <String>[];
    late final PlannedBedtimeStatus status;

    if (estimatedSleepMinutes >= targetMinutes) {
      status = PlannedBedtimeStatus.sufficient;
      reasonCodes.add('atOrAboveTarget');
    } else {
      status = PlannedBedtimeStatus.insufficient;
      reasonCodes.add('belowTarget');
    }

    bool hasConflict = false;
    if (readyToSleepMinutesFromMidnight != null) {
      final readyHour = readyToSleepMinutesFromMidnight ~/ 60;
      final readyMinute = readyToSleepMinutesFromMidnight % 60;
      // Ready-to-sleep is the evening before wake-up time.
      final readyToSleepDateTime = DateTime(
        wakeUpTime.year,
        wakeUpTime.month,
        wakeUpTime.day,
        readyHour,
        readyMinute,
      ).subtract(const Duration(days: 1));
      if (plannedDateTime.isBefore(readyToSleepDateTime)) {
        hasConflict = true;
        reasonCodes.add('conflictWithReadyToSleep');
      }
    }

    return PlannedBedtimeEvaluation(
      status: status,
      timeInBedMinutes: timeInBedMinutes,
      estimatedSleepMinutes: estimatedSleepMinutes,
      targetMinutes: targetMinutes,
      hasConflictWithReadyToSleep: hasConflict,
      reasonCodes: reasonCodes,
    );
  }
}
