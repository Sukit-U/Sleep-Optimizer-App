class PlannedBedtimeEvaluation {
  const PlannedBedtimeEvaluation({
    required this.status,
    required this.timeInBedMinutes,
    required this.estimatedSleepMinutes,
    required this.targetMinutes,
    required this.hasConflictWithReadyToSleep,
    required this.reasonCodes,
  });

  final PlannedBedtimeStatus status;
  final int timeInBedMinutes;
  final int estimatedSleepMinutes;
  final int targetMinutes;
  final bool hasConflictWithReadyToSleep;
  final List<String> reasonCodes;

  bool get isSufficient => status == PlannedBedtimeStatus.sufficient;
  bool get isInsufficient => status == PlannedBedtimeStatus.insufficient;
  bool get isNotSet => status == PlannedBedtimeStatus.notSet;
}

enum PlannedBedtimeStatus { sufficient, insufficient, notSet }
