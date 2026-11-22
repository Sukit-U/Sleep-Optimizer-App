import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_planner/domain/entities/bedtime_option.dart';
import 'package:snoozemate/features/sleep_planner/domain/usecases/evaluate_bedtime_feasibility.dart';

void main() {
  const usecase = EvaluateBedtimeFeasibility();

  List<BedtimeOption> buildOptions() {
    return [
      BedtimeOption(
        cycles: 6,
        bedtimeString: '9:45 PM',
        bedtimeDateTime: DateTime(2024, 1, 14, 21, 45),
        durationMinutes: 540,
      ),
      BedtimeOption(
        cycles: 5,
        bedtimeString: '11:15 PM',
        bedtimeDateTime: DateTime(2024, 1, 14, 23, 15),
        durationMinutes: 450,
      ),
      BedtimeOption(
        cycles: 4,
        bedtimeString: '12:45 AM',
        bedtimeDateTime: DateTime(2024, 1, 15, 0, 45),
        durationMinutes: 360,
      ),
    ];
  }

  test(
    'no ready-to-sleep time: all options feasible (existing behavior preserved)',
    () {
      final results = usecase.call(
        options: buildOptions(),
        readyToSleepTime: null,
      );

      expect(results, hasLength(3));
      for (final r in results) {
        expect(r.isFeasible, isTrue);
        expect(r.reason, isEmpty);
      }
    },
  );

  test('ready-to-sleep before all bedtimes: all feasible', () {
    final ready = DateTime(2024, 1, 14, 20, 0); // 8:00 PM
    final results = usecase.call(
      options: buildOptions(),
      readyToSleepTime: ready,
    );

    for (final r in results) {
      expect(r.isFeasible, isTrue);
      expect(r.reason, isEmpty);
    }
  });

  test('ready-to-sleep between bedtimes: earlier options infeasible', () {
    final ready = DateTime(2024, 1, 14, 22, 0); // 10:00 PM
    final results = usecase.call(
      options: buildOptions(),
      readyToSleepTime: ready,
    );

    expect(results[0].isFeasible, isFalse); // 9:45 PM before 10:00 PM
    expect(results[1].isFeasible, isTrue); // 11:15 PM after
    expect(results[2].isFeasible, isTrue); // 12:45 AM after
    expect(results[0].reason, isNotEmpty);
    expect(results[1].reason, isEmpty);
    expect(results[2].reason, isEmpty);
  });

  test(
    'ready-to-sleep exactly equal to a bedtime: feasible (equality allowed)',
    () {
      final ready = DateTime(2024, 1, 14, 23, 15); // 11:15 PM
      final results = usecase.call(
        options: buildOptions(),
        readyToSleepTime: ready,
      );

      expect(results[0].isFeasible, isFalse); // 9:45 PM
      expect(results[1].isFeasible, isTrue); // equality
      expect(results[1].reason, isEmpty);
      expect(results[2].isFeasible, isTrue);
    },
  );

  test('ready-to-sleep after all bedtimes: none feasible', () {
    final ready = DateTime(2024, 1, 15, 1, 0); // 1:00 AM
    final results = usecase.call(
      options: buildOptions(),
      readyToSleepTime: ready,
    );

    for (final r in results) {
      expect(r.isFeasible, isFalse);
      expect(r.reason, isNotEmpty);
    }
  });

  test(
    'overnight rollover: ready-to-sleep after midnight boundary handled',
    () {
      final ready = DateTime(2024, 1, 15, 0, 30); // 12:30 AM
      final results = usecase.call(
        options: buildOptions(),
        readyToSleepTime: ready,
      );

      expect(results[0].isFeasible, isFalse); // 9:45 PM prev day
      expect(results[1].isFeasible, isFalse); // 11:15 PM prev day
      expect(results[2].isFeasible, isTrue); // 12:45 AM after 12:30 AM
    },
  );

  test(
    'activity constraints are contextual labels only; feasibility uses ready-to-sleep time',
    () {
      final ready = DateTime(2024, 1, 14, 22, 0);
      final results = usecase.call(
        options: buildOptions(),
        readyToSleepTime: ready,
      );

      // Selecting different activity types does not independently change calculation.
      // Only ready-to-sleep time drives feasibility.
      final feasibleCount = results.where((r) => r.isFeasible).length;
      expect(feasibleCount, 2);
    },
  );

  test('reason explains why a plan is infeasible', () {
    final ready = DateTime(2024, 1, 14, 22, 0);
    final results = usecase.call(
      options: buildOptions(),
      readyToSleepTime: ready,
    );

    expect(results[0].reason, contains('9:45 PM'));
    expect(results[0].reason, contains('10:00'));
  });
}
