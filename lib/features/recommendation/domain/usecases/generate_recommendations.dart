import '../entities/recommendation.dart';

/// Builds per-factor recommendation data shared by the level-aware selection.
class _FactorConfig {
  const _FactorConfig({
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
  });

  final String title;
  final String description;
  final String action;
  final RecommendationPriority priority;
}

const _factorMap = <String, _FactorConfig>{
  'Sleep duration': _FactorConfig(
    title: 'Aim for a consistent bedtime',
    description: 'A stable sleep schedule helps your body recover more efficiently.',
    action: 'Set a fixed bedtime and wake-up time.',
    priority: RecommendationPriority.high,
  ),
  'Sleep regularity': _FactorConfig(
    title: 'Keep a steady rhythm',
    description: 'Regular sleep timing strengthens your sleep quality over time.',
    action: 'Stick to the same wake-up time each day.',
    priority: RecommendationPriority.critical,
  ),
  'Screen time': _FactorConfig(
    title: 'Reduce late screen exposure',
    description: 'Blue light can delay your sleep onset and reduce night-time rest.',
    action: 'Put your phone away 30 minutes before bed.',
    priority: RecommendationPriority.high,
  ),
  'Exercise': _FactorConfig(
    title: 'Add light activity earlier in the day',
    description: 'Physical activity can improve your sleep readiness and energy balance.',
    action: 'Take a short walk or stretch earlier in the day.',
    priority: RecommendationPriority.medium,
  ),
  'Stress': _FactorConfig(
    title: 'Create a simple wind-down routine',
    description: 'A calm routine can reduce stress and support better sleep.',
    action: 'Try breathing exercises or journaling before bed.',
    priority: RecommendationPriority.critical,
  ),
  'Caffeine': _FactorConfig(
    title: 'Cut back on late caffeine',
    description: 'Caffeine can stay in your system and disrupt sleep.',
    action: 'Avoid caffeine at least 6 hours before bed.',
    priority: RecommendationPriority.high,
  ),
};

/// Positive reinforcement shown when SQI is Excellent.
const _positiveReinforcement = _FactorConfig(
  title: 'Keep up the great habits!',
  description: 'Your sleep habits are excellent — maintaining them will help you stay rested and perform at your best.',
  action: 'Continue with your current sleep routine and share your good habits with friends.',
  priority: RecommendationPriority.low,
);

class GenerateRecommendations {
  const GenerateRecommendations();

  /// Generates recommendations based on weak factors and overall SQI level.
  ///
  /// [level] should be one of: 'excellent', 'good', 'fair', 'poor'.
  ///
  /// Rules per the Recommendation Logic document:
  /// - Excellent SQI → single positive reinforcement (low priority)
  /// - Good SQI → recommendation only for the single lowest-scoring factor
  /// - Fair/Poor SQI → up to 3 recommendations, prioritised by severity
  /// - Max 3 recommendations total
  List<RecommendationEntity> call({
    required List<String> weakFactors,
    required String level,
  }) {
    // Excellent → positive reinforcement only
    if (level == 'excellent') {
      return [
        RecommendationEntity(
          title: _positiveReinforcement.title,
          description: _positiveReinforcement.description,
          action: _positiveReinforcement.action,
          priority: _positiveReinforcement.priority,
          factor: 'General',
        ),
      ];
    }

    // Good → only the single lowest-scoring factor
    if (level == 'good' && weakFactors.isNotEmpty) {
      final factor = weakFactors.first;
      final config = _factorMap[factor];
      if (config == null) return [];
      return [
        RecommendationEntity(
          title: config.title,
          description: config.description,
          action: config.action,
          priority: config.priority,
          factor: factor,
        ),
      ];
    }

    // Fair / Poor → up to 3, prioritised
    final recommendations = <RecommendationEntity>[];
    final uniqueFactors = weakFactors.take(3);

    for (final factor in uniqueFactors) {
      final config = _factorMap[factor];
      if (config == null) continue;

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
