enum SleepQualityLevel {
  excellent,
  good,
  fair,
  poor,
}

class SqiResult {
  const SqiResult({
    required this.score,
    required this.level,
    required this.weakFactors,
    required this.responses,
  });

  final int score;
  final SleepQualityLevel level;
  final List<String> weakFactors;
  final Map<String, int> responses;
}
