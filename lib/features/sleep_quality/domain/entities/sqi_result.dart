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
    required this.factorScores,
    required this.responses,
  });

  final int score;
  final SleepQualityLevel level;
  final List<String> weakFactors;

  /// Per-factor weighted scores (e.g. {'Sleep duration': 16, 'Screen time': 12})
  final Map<String, int> factorScores;

  final Map<String, int> responses;
}
