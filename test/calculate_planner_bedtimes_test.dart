import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_planner/domain/usecases/calculate_planner_bedtimes.dart';

void main() {
  group('CalculatePlannerBedtimes', () {
    const usecase = CalculatePlannerBedtimes();

    test('returns bedtime options for 6, 5, 4 cycles in order', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0); // 7:00 AM
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 0);

      expect(options, hasLength(3));
      expect(options[0].cycles, 6);
      expect(options[1].cycles, 5);
      expect(options[2].cycles, 4);
    });

    test('calculates correct bedtime for 6 cycles with zero latency', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0); // 7:00 AM
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 0);

      // 6 cycles * 90 min = 540 min = 9 hours
      // 7:00 AM - 9 hours = 10:00 PM previous day
      final option6 = options.firstWhere((o) => o.cycles == 6);
      expect(option6.bedtimeString, '22:00');
      expect(option6.durationMinutes, 540);
    });

    test('calculates correct bedtime for 5 cycles with zero latency', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 0);

      // 5 cycles * 90 min = 450 min = 7.5 hours
      // 7:00 AM - 7.5 hours = 11:30 PM previous day
      final option5 = options.firstWhere((o) => o.cycles == 5);
      expect(option5.bedtimeString, '23:30');
      expect(option5.durationMinutes, 450);
    });

    test('calculates correct bedtime for 4 cycles with zero latency', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 0);

      // 4 cycles * 90 min = 360 min = 6 hours
      // 7:00 AM - 6 hours = 1:00 AM same day
      final option4 = options.firstWhere((o) => o.cycles == 4);
      expect(option4.bedtimeString, '01:00');
      expect(option4.durationMinutes, 360);
    });

    test('adds latency to total sleep time', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 15);

      // 5 cycles * 90 + 15 = 465 min = 7h 45m
      // 7:00 AM - 7h 45m = 11:15 PM
      final option5 = options.firstWhere((o) => o.cycles == 5);
      expect(option5.bedtimeString, '23:15');
    });

    test('default latency of 15 minutes matches existing behavior', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 15);

      final option6 = options.firstWhere((o) => o.cycles == 6);
      final option5 = options.firstWhere((o) => o.cycles == 5);
      final option4 = options.firstWhere((o) => o.cycles == 4);

      expect(option6.bedtimeString, '21:45');
      expect(option5.bedtimeString, '23:15');
      expect(option4.bedtimeString, '00:45');
    });

    test('maximum latency of 45 minutes', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 45);

      final option5 = options.firstWhere((o) => o.cycles == 5);
      // 5*90 + 45 = 495 min = 8h 15m
      // 7:00 AM - 8h 15m = 10:45 PM
      expect(option5.bedtimeString, '22:45');
    });

    test('handles date rollover across midnight', () {
      final wakeUp = DateTime(2024, 1, 15, 1, 0); // 1:00 AM
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 0);

      final option6 = options.firstWhere((o) => o.cycles == 6);
      // 1:00 AM - 9h = 4:00 PM previous day
      expect(option6.bedtimeString, '16:00');

      final option4 = options.firstWhere((o) => o.cycles == 4);
      // 1:00 AM - 6h = 7:00 PM previous day
      expect(option4.bedtimeString, '19:00');
    });

    test('different wake-up times produce correct bedtimes', () {
      final wakeUp1 = DateTime(2024, 1, 15, 6, 0); // 6:00 AM
      final wakeUp2 = DateTime(2024, 1, 15, 8, 0); // 8:00 AM

      final options1 = usecase.call(wakeUpTime: wakeUp1, latencyMinutes: 0);
      final options2 = usecase.call(wakeUpTime: wakeUp2, latencyMinutes: 0);

      // 6 AM - 9h = 9 PM previous day
      // 8 AM - 9h = 11 PM previous day
      final opt1 = options1.firstWhere((o) => o.cycles == 6);
      final opt2 = options2.firstWhere((o) => o.cycles == 6);

      expect(opt1.bedtimeString, '21:00');
      expect(opt2.bedtimeString, '23:00');
    });

    test('ordering is always 6, 5, 4 cycles', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 0);

      final cycles = options.map((o) => o.cycles).toList();
      expect(cycles, [6, 5, 4]);
    });

    test('throws ArgumentError for negative latency', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);

      expect(
        () => usecase.call(wakeUpTime: wakeUp, latencyMinutes: -1),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for latency exceeding maximum', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);

      expect(
        () => usecase.call(wakeUpTime: wakeUp, latencyMinutes: 46),
        throwsArgumentError,
      );
    });

    test('latency at boundary (0) works', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 0);

      expect(options, hasLength(3));
    });

    test('latency at boundary (45) works', () {
      final wakeUp = DateTime(2024, 1, 15, 7, 0);
      final options = usecase.call(wakeUpTime: wakeUp, latencyMinutes: 45);

      expect(options, hasLength(3));
    });
  });
}
