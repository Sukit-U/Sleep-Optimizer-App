import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_quality/domain/entities/sqi_result.dart';
import 'package:snoozemate/features/sleep_quality/domain/usecases/submit_sqi_assessment.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

/// Stands in for Firestore: records every attempt and lets a test fail or stall
/// one of the two write steps.
class _FakeWriter {
  final recordWrites = <SQIRecord>[];
  final recommendationAttempts = <List<String>>[];
  final recommendationWrites = <List<Recommendation>>[];
  int _idCounter = 0;

  bool failRecord = false;
  bool failRecommendations = false;
  Completer<void>? blockRecord;

  String newRecordId() => 'rec-${++_idCounter}';

  Future<void> writeRecord(SQIRecord record) async {
    if (blockRecord != null) await blockRecord!.future;
    if (failRecord) throw Exception('record write failed');
    recordWrites.add(record);
  }

  Future<void> writeRecommendations(List<Recommendation> recommendations) async {
    // Record the attempt even when it throws, so a test can prove a retry
    // targets the same document IDs instead of minting new ones.
    recommendationAttempts.add(
      recommendations.map((r) => r.recommendationId).toList(),
    );
    if (failRecommendations) throw Exception('recommendation batch failed');
    recommendationWrites.add(recommendations);
  }

  List<String> get attemptedRecommendationIds =>
      recommendationAttempts.expand((ids) => ids).toList();
}

SqiResult _fairResult() => const SqiResult(
      score: 42,
      level: SleepQualityLevel.fair,
      weakFactors: ['Caffeine', 'Sleep regularity'],
      factorScores: {'Caffeine': 3, 'Sleep regularity': 4},
      responses: {'Sleep duration': 2, 'Stress': 2, 'Caffeine': 1},
    );

SubmitSqiAssessment _submitWith(_FakeWriter writer) => SubmitSqiAssessment(
      newRecordId: writer.newRecordId,
      writeRecord: writer.writeRecord,
      writeRecommendations: writer.writeRecommendations,
    );

void main() {
  group('in-flight guard', () {
    test('a second submit while one is running writes nothing extra', () async {
      final writer = _FakeWriter()..blockRecord = Completer<void>();
      final submit = _submitWith(writer);

      final first = submit(userId: 'owner', result: _fairResult());
      final second = await submit(userId: 'owner', result: _fairResult());

      expect(second, SubmitSqiOutcome.busy);
      expect(writer.recordWrites, isEmpty);

      writer.blockRecord!.complete();
      expect(await first, SubmitSqiOutcome.saved);

      expect(writer.recordWrites, hasLength(1),
          reason: 'a duplicate tap must not create a second record');
      expect(writer.recommendationWrites, hasLength(1));
    });
  });

  group('retry after the record was saved', () {
    test('reuses the record and its recommendation IDs', () async {
      final writer = _FakeWriter()..failRecommendations = true;
      final submit = _submitWith(writer);

      expect(
        await submit(userId: 'owner', result: _fairResult()),
        SubmitSqiOutcome.recordSavedRecommendationsNotConfirmed,
      );
      final recordId = writer.recordWrites.single.recordId;
      final firstAttempt = writer.recommendationAttempts.single;

      writer.failRecommendations = false;
      expect(
        await submit(userId: 'owner', result: _fairResult()),
        SubmitSqiOutcome.saved,
      );

      expect(writer.recordWrites, hasLength(1),
          reason: 'the record must not be written again');
      expect(writer.recordWrites.single.recordId, recordId);
      expect(writer.recommendationAttempts, hasLength(2));
      expect(writer.recommendationAttempts[1], firstAttempt,
          reason: 'a retry must reuse the same recommendation documents');
      expect(writer.attemptedRecommendationIds.toSet(), hasLength(2),
          reason: 'recommendation IDs must be derived from the record ID');
      expect(writer.attemptedRecommendationIds.first, '$recordId-r0');
      expect(writer.recommendationWrites.single, hasLength(2));
    });
  });

  group('retry after the record write failed', () {
    test('reports an unconfirmed save and then reuses the same record ID',
        () async {
      final writer = _FakeWriter()..failRecord = true;
      final submit = _submitWith(writer);

      expect(
        await submit(userId: 'owner', result: _fairResult()),
        SubmitSqiOutcome.unconfirmed,
      );
      expect(writer.recordWrites, isEmpty);
      expect(writer.recommendationAttempts, isEmpty,
          reason: 'no recommendation may be written before its parent exists');

      final pendingId = submit.recordId;
      writer.failRecord = false;
      expect(
        await submit(userId: 'owner', result: _fairResult()),
        SubmitSqiOutcome.saved,
      );

      expect(writer.recordWrites, hasLength(1));
      expect(writer.recordWrites.single.recordId, pendingId,
          reason: 'the retry must target the record ID allocated first');
    });
  });

  group('attempt lifecycle', () {
    test('only a confirmed save allows a new record', () async {
      final writer = _FakeWriter();
      final submit = _submitWith(writer);

      await submit(userId: 'owner', result: _fairResult());
      final firstId = writer.recordWrites.single.recordId;

      // Still the same attempt: a retry keeps the record.
      await submit(userId: 'owner', result: _fairResult());
      expect(writer.recordWrites, hasLength(1));

      submit.reset();
      await submit(userId: 'owner', result: _fairResult());
      expect(writer.recordWrites, hasLength(2));
      expect(writer.recordWrites.last.recordId, isNot(firstId),
          reason: 'a new assessment needs a new record');
    });

    test('a partial failure keeps its record until it is retried to success',
        () async {
      final writer = _FakeWriter()..failRecommendations = true;
      final submit = _submitWith(writer);

      await submit(userId: 'owner', result: _fairResult());
      expect(submit.recordSaved, isTrue);
      expect(submit.recordId, writer.recordWrites.single.recordId);

      writer.failRecommendations = false;
      expect(
        await submit(userId: 'owner', result: _fairResult()),
        SubmitSqiOutcome.saved,
      );
      expect(writer.recordWrites, hasLength(1));
    });
  });
}
