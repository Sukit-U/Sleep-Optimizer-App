import '../entities/sqi_result.dart';

class CalculateSqi {
  const CalculateSqi();

  SqiResult call({required Map<String, int> responses}) {
    final factors = <String, int>{
      'Sleep duration': 20,
      'Sleep regularity': 20,
      'Screen time': 15,
      'Exercise': 15,
      'Stress': 15,
      'Caffeine': 15,
    };

    final factorScores = <String, int>{};

    for (final entry in factors.entries) {
      final value = responses[entry.key] ?? 0;
      final weightedValue = ((value / 5) * entry.value).round();
      factorScores[entry.key] = weightedValue;
    }

    final sortedByScore = factorScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final weakFactors = sortedByScore
        .take(2)
        .map((entry) => entry.key)
        .toList();

    final score = factorScores.values.reduce((a, b) => a + b);
    final level = _mapLevel(score);

    return SqiResult(
      score: score,
      level: level,
      weakFactors: weakFactors,
      factorScores: factorScores,
      responses: responses,
    );
  }

  SleepQualityLevel _mapLevel(int score) {
    if (score >= 80) {
      return SleepQualityLevel.excellent;
    }
    if (score >= 60) {
      return SleepQualityLevel.good;
    }
    if (score >= 40) {
      return SleepQualityLevel.fair;
    }
    return SleepQualityLevel.poor;
  }
}
