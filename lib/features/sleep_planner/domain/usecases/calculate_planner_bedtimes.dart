import '../entities/bedtime_option.dart';

/// Calculates suggested bedtimes based on wake-up time and sleep latency.
///
/// The calculation follows the 90-minute sleep cycle heuristic:
/// - Each cycle is 90 minutes
/// - Supported cycle counts: 6, 5, 4 (in that order)
/// - Latency is added to the total sleep time
/// - Bedtimes are calculated by subtracting total minutes from wake-up time
class CalculatePlannerBedtimes {
  const CalculatePlannerBedtimes();

  static const _supportedCycles = [6, 5, 4];
  static const _cycleDurationMinutes = 90;
  static const _maxLatencyMinutes = 45;

  List<BedtimeOption> call({
    required DateTime wakeUpTime,
    required int latencyMinutes,
  }) {
    if (latencyMinutes < 0) {
      throw ArgumentError('Latency must be non-negative');
    }
    if (latencyMinutes > _maxLatencyMinutes) {
      throw ArgumentError(
        'Latency exceeds maximum of $_maxLatencyMinutes minutes',
      );
    }

    final options = <BedtimeOption>[];
    for (final cycles in _supportedCycles) {
      final totalMinutes = (cycles * _cycleDurationMinutes) + latencyMinutes;
      final bedtime = wakeUpTime.subtract(Duration(minutes: totalMinutes));

      options.add(
        BedtimeOption(
          cycles: cycles,
          bedtimeString: _formatTime(bedtime),
          bedtimeDateTime: bedtime,
          durationMinutes: cycles * _cycleDurationMinutes,
        ),
      );
    }
    return options;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
