import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_quality/data/repositories/sqi_repository.dart';
import 'package:snoozemate/features/sleep_quality/presentation/pages/sleep_quality_page.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

/// A signed-in user whose Firestore write fails (e.g. no connection).
class _FailingSqiRepository implements SqiRepository {
  int recordAttempts = 0;

  @override
  String newRecordId() => 'rec-fail';

  @override
  Future<void> saveRecord(SQIRecord record) async {
    recordAttempts++;
    throw Exception('firestore unavailable');
  }

  @override
  Future<void> saveRecommendations(
    List<Recommendation> recommendations,
  ) async {}
}

void main() {
  testWidgets('a failed cloud save is reported and the result is preserved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _FailingSqiRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SleepQualityPage(
          repository: repository,
          ensureSignedIn: () async => 'owner-uid',
        ),
      ),
    );

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('3').at(i));
      await tester.pump();
    }

    await tester.tap(find.text('Calculate SQI'));
    await tester.pumpAndSettle();

    expect(repository.recordAttempts, 1);
    // The failure is communicated and never reported as a success.
    expect(find.textContaining('Could not confirm the save'), findsOneWidget);
    expect(find.text('Saved to history'), findsNothing);
    // The page did not navigate away on a failed save.
    expect(find.byType(SleepQualityPage), findsOneWidget);
    // The calculated result is kept and reachable for a later retry/review.
    expect(find.text('View last result'), findsOneWidget);

    // Let the snackbar auto-dismiss timer finish.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
