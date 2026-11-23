class BedtimeOption {
  const BedtimeOption({
    required this.cycles,
    required this.bedtimeString,
    required this.bedtimeDateTime,
    required this.durationMinutes,
  });

  final int cycles;
  final String bedtimeString;
  final DateTime bedtimeDateTime;
  final int durationMinutes;
}
