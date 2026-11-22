import '../entities/bedtime_feasibility_result.dart';
import '../entities/bedtime_option.dart';

/// Evaluates whether each [BedtimeOption] is feasible given the user's
/// ready-to-sleep time.
///
/// A suggested bedtime is feasible only when it is at or after the
/// ready-to-sleep time (equality is feasible). When no ready-to-sleep time is
/// provided, every option is feasible and the existing planner behavior is
/// preserved.
///
/// The sleep cycle algorithm (6/5/4 cycles, 90 minutes per cycle, sleep
/// latency) is never changed by this evaluation.
class EvaluateBedtimeFeasibility {
  const EvaluateBedtimeFeasibility();

  List<BedtimeFeasibilityResult> call({
    required List<BedtimeOption> options,
    required DateTime? readyToSleepTime,
  }) {
    if (readyToSleepTime == null) {
      return options
          .map(
            (o) => BedtimeFeasibilityResult(
              option: o,
              isFeasible: true,
              reason: '',
            ),
          )
          .toList();
    }

    return options.map((o) {
      final isFeasible = !o.bedtimeDateTime.isBefore(readyToSleepTime);
      final reason = isFeasible
          ? ''
          : 'เข้านอนเวลา ${o.bedtimeString} ก่อนเวลาที่พร้อมนอน '
              '${_formatTime(readyToSleepTime)} จึงทำแผนนี้ไม่ได้';
      return BedtimeFeasibilityResult(
        option: o,
        isFeasible: isFeasible,
        reason: reason,
      );
    }).toList();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr';
  }
}
