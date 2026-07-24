import '../entities/recommendation.dart';

class GenerateRecommendations {
  const GenerateRecommendations();

  List<RecommendationEntity> call({required List<String> weakFactors}) {
    final recommendations = <RecommendationEntity>[];

    final factorMap = {
      'Sleep duration': (
        title: 'Aim for a consistent bedtime',
        description: 'A stable sleep schedule helps your body recover more efficiently.',
        action: 'Set a fixed bedtime and wake-up time.',
        priority: RecommendationPriority.high,
      ),
      'Sleep regularity': (
        title: 'Keep a steady rhythm',
        description: 'Regular sleep timing strengthens your sleep quality over time.',
        action: 'Stick to the same wake-up time each day.',
        priority: RecommendationPriority.critical,
      ),
      'Screen time': (
        title: 'Reduce late screen exposure',
        description: 'Blue light can delay your sleep onset and reduce night-time rest.',
        action: 'Put your phone away 30 minutes before bed.',
        priority: RecommendationPriority.high,
      ),
      'Exercise': (
        title: 'Add light activity earlier in the day',
        description: 'Physical activity can improve your sleep readiness and energy balance.',
        action: 'Take a short walk or stretch earlier in the day.',
        priority: RecommendationPriority.medium,
      ),
      'Stress': (
        title: 'Create a simple wind-down routine',
        description: 'A calm routine can reduce stress and support better sleep.',
        action: 'Try breathing exercises or journaling before bed.',
        priority: RecommendationPriority.critical,
      ),
      'Caffeine': (
        title: 'Cut back on late caffeine',
        description: 'Caffeine can stay in your system and disrupt sleep.',
        action: 'Avoid caffeine at least 6 hours before bed.',
        priority: RecommendationPriority.high,
      ),
    };

    final uniqueFactors = weakFactors.take(3);

    for (final factor in uniqueFactors) {
      final config = factorMap[factor];
      if (config == null) {
        continue;
      }

      recommendations.add(
        RecommendationEntity(
          title: config.title,
          description: config.description,
          action: config.action,
          priority: config.priority,
          factor: factor,
        ),
      );
    }

    return recommendations;
  }
}
