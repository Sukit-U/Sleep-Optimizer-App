import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_quality/data/repositories/sqi_repository.dart';
import 'package:snoozemate/features/sleep_quality/presentation/pages/sleep_quality_page.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

/// Records writes so a test can prove the offline path never touches the cloud.
class _UnusedSqiRepository implements SqiRepository {
  int recordWrites = 0;
  int recommendationWrites = 0;

  @override
  String newRecordId() => 'rec-unused';

  @override
  Future<void> saveRecord(SQIRecord record) async {
    recordWrites++;
  }

  @override
  Future<void> saveRecommendations(List<Recommendation> recommendations) async {
    recommendationWrites++;
  }
}

void main() {
  testWidgets('calculates the SQI and shows the result with no sign-in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _UnusedSqiRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SleepQualityPage(
          repository: repository,
          ensureSignedIn: () async => null,
        ),
      ),
    );

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('3').at(i));
      await tester.pump();
    }

    await tester.tap(find.text('Calculate SQI'));
    await tester.pumpAndSettle();

    // The score is calculated locally and surfaced without any sign-in.
    expect(find.text('Calculated offline'), findsOneWidget);
    expect(find.textContaining('Your SQI is 60'), findsOneWidget);
    // No cloud write was attempted.
    expect(repository.recordWrites, 0);

    // The user can view the full local result.
    await tester.tap(find.text('View result'));
    await tester.pumpAndSettle();
    expect(find.text('60'), findsOneWidget);
    expect(find.text('good'), findsOneWidget);
  });
}
