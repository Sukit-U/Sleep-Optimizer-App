import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_quality/domain/entities/sqi_result.dart';
import 'package:snoozemate/features/sleep_quality/domain/usecases/calculate_sqi.dart';

void main() {
  test('calculates weighted SQI score and low factor list', () {
    final result = CalculateSqi().call(
      responses: {
        'Sleep duration': 2,
        'Sleep regularity': 1,
        'Screen time': 3,
        'Exercise': 4,
        'Stress': 2,
        'Caffeine': 1,
      },
    );

    expect(result.score, 42);
    expect(result.level, SleepQualityLevel.fair);
    expect(result.weakFactors, ['Caffeine', 'Sleep regularity']);
  });
}
