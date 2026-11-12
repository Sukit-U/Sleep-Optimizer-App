import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_quality/data/repositories/sqi_repository.dart';
import 'package:snoozemate/features/sleep_quality/presentation/pages/sleep_quality_page.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

/// Keeps both write steps pending until the test releases them, and counts every
/// attempt so a duplicate submission would be visible.
class _FakeSqiRepository implements SqiRepository {
  final recordAttempts = <SQIRecord>[];
  final recordWrites = <SQIRecord>[];
  final recommendationWrites = <List<Recommendation>>[];
  final _recordGate = Completer<void>();

  void releaseRecordWrite() {
    if (!_recordGate.isCompleted) _recordGate.complete();
  }

  @override
  String newRecordId() => 'rec-fixed';

  @override
  Future<void> saveRecord(SQIRecord record) async {
    recordAttempts.add(record);
    await _recordGate.future;
    recordWrites.add(record);
  }

  @override
  Future<void> saveRecommendations(List<Recommendation> recommendations) async {
    recommendationWrites.add(recommendations);
  }
}

void main() {
  testWidgets(
      'a rapid second tap while the first save is pending is ignored',
      (tester) async {
    // Tall enough that every question card and the button are laid out.
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _FakeSqiRepository();

    // The sign-in itself is held open: that is the window in which the button
    // used to stay enabled and a second tap started a duplicate submission.
    final signInGate = Completer<String?>();

    await tester.pumpWidget(
      MaterialApp(
        home: SleepQualityPage(
          repository: repository,
          ensureSignedIn: () => signInGate.future,
        ),
      ),
    );

    // Answer all six questions (each card offers chips 1-5).
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('3').at(i));
      await tester.pump();
    }

    await tester.tap(find.text('Calculate SQI'));
    await tester.pump();

    // Still signing in, and the button must already be disabled.
    expect(find.text('Saving…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
      reason: 'the button must be disabled before the first await returns',
    );

    // The second tap of a fast double tap, inside the pre-await window.
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    signInGate.complete('owner');
    await tester.pump();
    await tester.pump();

    expect(repository.recordAttempts, hasLength(1),
        reason: 'a duplicate tap must not start a second submission');

    // The record write is in flight (the fake holds it open), so the button
    // must still be disabled, not just during the sign-in step.
    expect(find.text('Saving…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
      reason: 'the button must stay disabled while the record write is pending',
    );

    repository.releaseRecordWrite();
    await tester.pumpAndSettle();

    expect(repository.recordWrites, hasLength(1));
    expect(repository.recordWrites.single.recordId, 'rec-fixed');
    expect(repository.recommendationWrites, hasLength(1));
  });
}
