import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/recommendation/domain/usecases/generate_recommendations.dart';
import 'package:snoozemate/features/sleep_planner/domain/usecases/calculate_planner_bedtimes.dart';
import 'package:snoozemate/features/sleep_quality/domain/usecases/calculate_sqi.dart';

final _goldenData = (() {
  final file = File('test/fixtures/calculation_golden_cases.json');
  final jsonString = file.readAsStringSync();
  return jsonDecode(jsonString) as Map<String, dynamic>;
})();

void main() {
  group('Golden Reference — SQI Calculation', () {
    final sqiCases = _goldenData['sqiCases'] as List<dynamic>;
    final usecase = CalculateSqi();

    for (final caseData in sqiCases) {
      final id = caseData['id'] as String;
      final description = caseData['description'] as String;
      final input = Map<String, int>.from(caseData['input'] as Map);
      final expected = caseData['expectedOutput'] as Map<String, dynamic>;

      test('$id: $description', () {
        final result = usecase.call(responses: input);

        expect(result.score, expected['score'], reason: '$id score mismatch');

        expect(
          result.level.name,
          expected['level'],
          reason: '$id level mismatch',
        );

        // For tied weak factors, order is undefined - only check set equality
        final expectedWeak = (expected['weakFactors'] as List).cast<String>();
        if (expected.containsKey('note') &&
            (expected['note'] as String).contains('tied')) {
          expect(
            result.weakFactors.toSet(),
            expectedWeak.toSet(),
            reason: '$id weakFactors (tied) mismatch',
          );
        } else {
          expect(
            result.weakFactors,
            expectedWeak,
            reason: '$id weakFactors mismatch',
          );
        }

        final expectedFactorScores = Map<String, int>.from(
          expected['factorScores'] as Map,
        );
        expect(
          result.factorScores,
          expectedFactorScores,
          reason: '$id factorScores mismatch',
        );
      });
    }
  });

  group('Golden Reference — Recommendation Engine', () {
    final recCases = _goldenData['recommendationCases'] as List<dynamic>;
    final usecase = GenerateRecommendations();

    for (final caseData in recCases) {
      final id = caseData['id'] as String;
      final description = caseData['description'] as String;
      final input = caseData['input'] as Map<String, dynamic>;
      final expected = caseData['expectedOutput'] as List<dynamic>;

      test('$id: $description', () {
        final recommendations = usecase.call(
          weakFactors: (input['weakFactors'] as List).cast<String>(),
          level: input['level'] as String,
          recordId: input['recordId'] as String? ?? '',
          userId: input['userId'] as String? ?? '',
        );

        expect(
          recommendations.length,
          expected.length,
          reason: '$id recommendation count mismatch',
        );

        for (int i = 0; i < expected.length; i++) {
          final exp = expected[i] as Map<String, dynamic>;
          final rec = recommendations[i];

          expect(rec.factor, exp['factor'], reason: '$id[$i] factor mismatch');
          expect(rec.title, exp['title'], reason: '$id[$i] title mismatch');
          expect(
            rec.description,
            exp['description'],
            reason: '$id[$i] description mismatch',
          );
          expect(rec.action, exp['action'], reason: '$id[$i] action mismatch');
          expect(
            rec.priority,
            exp['priority'],
            reason: '$id[$i] priority mismatch',
          );
        }
      });
    }
  });

  group('Golden Reference — Sleep Planner', () {
    final plannerCases = _goldenData['plannerCases'] as List<dynamic>;
    final usecase = CalculatePlannerBedtimes();

    for (final caseData in plannerCases) {
      final id = caseData['id'] as String;
      final description = caseData['description'] as String;
      final input = caseData['input'] as Map<String, dynamic>;
      final expected = caseData['expectedOutput'];

      test('$id: $description', () {
        final wakeUpTime = DateTime.parse(input['wakeUpTime'] as String);
        final latencyMinutes = input['latencyMinutes'] as int;

        final options = usecase.call(
          wakeUpTime: wakeUpTime,
          latencyMinutes: latencyMinutes,
        );

        if (expected is List) {
          // Full list comparison
          expect(
            options.length,
            expected.length,
            reason: '$id option count mismatch',
          );

          for (int i = 0; i < expected.length; i++) {
            final exp = expected[i] as Map<String, dynamic>;
            final opt = options[i];

            expect(
              opt.cycles,
              exp['cycles'],
              reason: '$id[$i] cycles mismatch',
            );
            expect(
              opt.bedtimeString,
              exp['bedtimeString'],
              reason: '$id[$i] bedtimeString mismatch',
            );
            expect(
              opt.durationMinutes,
              exp['durationMinutes'],
              reason: '$id[$i] durationMinutes mismatch',
            );
          }
        } else if (expected is Map) {
          // Partial checks (e.g., ordering only)
          if (expected.containsKey('cyclesOrder')) {
            final cycles = options.map((o) => o.cycles).toList();
            expect(
              cycles,
              expected['cyclesOrder'],
              reason: '$id cyclesOrder mismatch',
            );
          }
        }
      });
    }
  });
}
