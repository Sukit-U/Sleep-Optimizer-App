import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/recommendation/domain/usecases/generate_recommendations.dart';
import 'package:snoozemate/features/sleep_quality/domain/entities/sqi_result.dart';
import 'package:snoozemate/features/sleep_quality/domain/usecases/calculate_sqi.dart';
import 'package:snoozemate/models/recommendation_model.dart';

void main() {
  const usecase = GenerateRecommendations();

  /// Documented limit from the Recommendation Logic spec: max 3 recommendations.
  const maxRecommendations = 3;

  /// Asserts every returned recommendation preserves [recordId] and that no
  /// factor appears more than once.
  void expectRecordIdAndUniqueFactors(
    List<Recommendation> recommendations,
    String recordId,
  ) {
    for (final rec in recommendations) {
      expect(rec.recordId, recordId,
          reason: 'every recommendation must carry the recordId');
    }
    final factors = recommendations.map((rec) => rec.factor).toList();
    expect(factors.toSet().length, factors.length,
        reason: 'recommendation factors must not be duplicated');
  }

  group('GenerateRecommendations — per SQI level', () {
    test('excellent: single low-priority positive reinforcement', () {
      final recommendations = usecase.call(
        weakFactors: ['Caffeine', 'Sleep regularity'],
        level: 'excellent',
        recordId: 'rec-excellent',
      );

      expect(recommendations, hasLength(1));
      final rec = recommendations.first;
      expect(rec.factor, 'General');
      expect(rec.priority, 'low');
      expect(rec.priority, RecommendationPriority.low.name);
      expectRecordIdAndUniqueFactors(recommendations, 'rec-excellent');
      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
    });

    test('good: only the single lowest-scoring factor is recommended', () {
      final recommendations = usecase.call(
        weakFactors: ['Sleep regularity', 'Caffeine'],
        level: 'good',
        recordId: 'rec-good',
      );

      expect(recommendations, hasLength(1));
      final rec = recommendations.first;
      expect(rec.factor, 'Sleep regularity');
      expect(rec.priority, 'critical');
      expect(rec.priority, RecommendationPriority.critical.name);
      expectRecordIdAndUniqueFactors(recommendations, 'rec-good');
      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
    });

    test('good with no weak factors returns nothing', () {
      final recommendations = usecase.call(
        weakFactors: [],
        level: 'good',
        recordId: 'rec-good-empty',
      );

      expect(recommendations, isEmpty);
    });

    test('good with an unknown weakest factor returns nothing', () {
      final recommendations = usecase.call(
        weakFactors: ['Unknown factor'],
        level: 'good',
        recordId: 'rec-good-unknown',
      );

      expect(recommendations, isEmpty);
    });

    test('fair: up to 3 recommendations, one per weak factor', () {
      final recommendations = usecase.call(
        weakFactors: ['Caffeine', 'Exercise', 'Screen time'],
        level: 'fair',
        recordId: 'rec-fair',
      );

      expect(recommendations, hasLength(3));
      expect(recommendations[0].factor, 'Caffeine');
      expect(recommendations[0].priority, 'high');
      expect(recommendations[1].factor, 'Exercise');
      expect(recommendations[1].priority, 'medium');
      expect(recommendations[2].factor, 'Screen time');
      expect(recommendations[2].priority, 'high');
      expectRecordIdAndUniqueFactors(recommendations, 'rec-fair');
      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
    });

    test('poor: capped at 3 even with more than three weak factors', () {
      final recommendations = usecase.call(
        weakFactors: [
          'Sleep regularity',
          'Stress',
          'Sleep duration',
          'Caffeine',
        ],
        level: 'poor',
        recordId: 'rec-poor-capped',
      );

      expect(recommendations, hasLength(3));
      expect(recommendations[0].factor, 'Sleep regularity');
      expect(recommendations[0].priority, 'critical');
      expect(recommendations[1].factor, 'Stress');
      expect(recommendations[1].priority, 'critical');
      expect(recommendations[2].factor, 'Sleep duration');
      expect(recommendations[2].priority, 'high');
      expectRecordIdAndUniqueFactors(recommendations, 'rec-poor-capped');
      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
    });

    test('poor with all six factors still capped at the documented limit', () {
      final recommendations = usecase.call(
        weakFactors: [
          'Sleep duration',
          'Sleep regularity',
          'Screen time',
          'Exercise',
          'Stress',
          'Caffeine',
        ],
        level: 'poor',
        recordId: 'rec-poor-all',
      );

      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
      expectRecordIdAndUniqueFactors(recommendations, 'rec-poor-all');
    });

    test('unknown factor names are skipped, known ones still returned', () {
      final recommendations = usecase.call(
        weakFactors: ['Unknown factor', 'Caffeine'],
        level: 'poor',
        recordId: 'rec-unknown',
      );

      expect(recommendations, hasLength(1));
      expect(recommendations.first.factor, 'Caffeine');
      expectRecordIdAndUniqueFactors(recommendations, 'rec-unknown');
    });

    test('fair with no weak factors returns nothing', () {
      final recommendations = usecase.call(
        weakFactors: [],
        level: 'fair',
        recordId: 'rec-fair-empty',
      );

      expect(recommendations, isEmpty);
    });

    test('poor with no weak factors returns nothing', () {
      final recommendations = usecase.call(
        weakFactors: [],
        level: 'poor',
        recordId: 'rec-poor-empty',
      );

      expect(recommendations, isEmpty);
    });
  });

  group('GenerateRecommendations — SQI boundary scores', () {
    // Weighted scoring: Sleep duration/regularity are 4x response, the rest 3x.
    // Maps are chosen so the two lowest factor scores are strictly distinct,
    // making weakFactors deterministic (List.sort is not stable).
    const boundaryCases = <String, Map<String, int>>{
      // Score exactly 80 → excellent.
      'excellent@80': {
        'Sleep duration': 4,
        'Sleep regularity': 4,
        'Screen time': 5,
        'Exercise': 5,
        'Stress': 4,
        'Caffeine': 2,
      },
      // Score exactly 60 → good.
      'good@60': {
        'Sleep duration': 3,
        'Sleep regularity': 3,
        'Screen time': 5,
        'Exercise': 4,
        'Stress': 2,
        'Caffeine': 1,
      },
      // Score exactly 40 → fair.
      'fair@40': {
        'Sleep duration': 1,
        'Sleep regularity': 3,
        'Screen time': 3,
        'Exercise': 2,
        'Stress': 2,
        'Caffeine': 1,
      },
      // Score 39 (just below fair) → poor.
      'poor@39': {
        'Sleep duration': 1,
        'Sleep regularity': 2,
        'Screen time': 3,
        'Exercise': 3,
        'Stress': 2,
        'Caffeine': 1,
      },
    };

    test('scores map to the expected level at each boundary', () {
      final expectedLevels = <String, SleepQualityLevel>{
        'excellent@80': SleepQualityLevel.excellent,
        'good@60': SleepQualityLevel.good,
        'fair@40': SleepQualityLevel.fair,
        'poor@39': SleepQualityLevel.poor,
      };
      final expectedScores = <String, int>{
        'excellent@80': 80,
        'good@60': 60,
        'fair@40': 40,
        'poor@39': 39,
      };

      boundaryCases.forEach((key, responses) {
        final result = CalculateSqi().call(responses: responses);
        expect(result.score, expectedScores[key],
            reason: '$key must produce exactly ${expectedScores[key]}');
        expect(result.level, expectedLevels[key],
            reason: '$key must map to ${expectedLevels[key]}');
      });
    });

    test('excellent boundary: level name drives GenerateRecommendations', () {
      final result = CalculateSqi().call(
        responses: boundaryCases['excellent@80']!,
      );

      // Deterministic weakest factors: Caffeine (6) and Stress (12).
      expect(result.weakFactors, ['Caffeine', 'Stress']);

      final recommendations = usecase.call(
        weakFactors: result.weakFactors,
        level: result.level.name,
        recordId: 'rec-boundary-80',
      );

      expect(recommendations, hasLength(1));
      expect(recommendations.first.factor, 'General');
      expect(recommendations.first.priority, 'low');
      expectRecordIdAndUniqueFactors(recommendations, 'rec-boundary-80');
      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
    });

    test('good boundary: only the weakest factor is recommended', () {
      final result = CalculateSqi().call(
        responses: boundaryCases['good@60']!,
      );

      // Deterministic weakest factors: Caffeine (3) and Stress (6).
      expect(result.weakFactors, ['Caffeine', 'Stress']);

      final recommendations = usecase.call(
        weakFactors: result.weakFactors,
        level: result.level.name,
        recordId: 'rec-boundary-60',
      );

      expect(recommendations, hasLength(1));
      expect(recommendations.first.factor, 'Caffeine');
      expect(recommendations.first.priority, 'high');
      expectRecordIdAndUniqueFactors(recommendations, 'rec-boundary-60');
    });

    test('fair boundary: recommendations for the weak factors', () {
      final result = CalculateSqi().call(
        responses: boundaryCases['fair@40']!,
      );

      // Deterministic weakest factors: Caffeine (3) and Sleep duration (4).
      expect(result.weakFactors, ['Caffeine', 'Sleep duration']);

      final recommendations = usecase.call(
        weakFactors: result.weakFactors,
        level: result.level.name,
        recordId: 'rec-boundary-40',
      );

      expect(recommendations, hasLength(2));
      expect(recommendations[0].factor, 'Caffeine');
      expect(recommendations[0].priority, 'high');
      expect(recommendations[1].factor, 'Sleep duration');
      expect(recommendations[1].priority, 'high');
      expectRecordIdAndUniqueFactors(recommendations, 'rec-boundary-40');
      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
    });

    test('poor boundary: recommendations for the weak factors', () {
      final result = CalculateSqi().call(
        responses: boundaryCases['poor@39']!,
      );

      // Deterministic weakest factors: Caffeine (3) and Sleep duration (4).
      expect(result.weakFactors, ['Caffeine', 'Sleep duration']);

      final recommendations = usecase.call(
        weakFactors: result.weakFactors,
        level: result.level.name,
        recordId: 'rec-boundary-39',
      );

      expect(recommendations, hasLength(2));
      expect(recommendations[0].factor, 'Caffeine');
      expect(recommendations[0].priority, 'high');
      expect(recommendations[1].factor, 'Sleep duration');
      expect(recommendations[1].priority, 'high');
      expectRecordIdAndUniqueFactors(recommendations, 'rec-boundary-39');
      expect(recommendations.length, lessThanOrEqualTo(maxRecommendations));
    });
  });
}
