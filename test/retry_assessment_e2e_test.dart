import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/sleep_quality/domain/entities/sqi_result.dart';
import 'package:snoozemate/features/sleep_quality/domain/usecases/calculate_sqi.dart';
import 'package:snoozemate/features/sleep_quality/domain/usecases/submit_sqi_assessment.dart';
import 'package:snoozemate/models/recommendation_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

/// Thrown by the double when a write would be rejected by `firestore.rules`.
class RulesRejection implements Exception {
  RulesRejection(this.message);
  final String message;

  @override
  String toString() => 'RulesRejection: $message';
}

/// In-memory stand-in for the two Firestore collections the assessment writes.
///
/// It enforces the contract `firestore.rules` enforces, which is the part the
/// retry depends on:
///
/// * a write to a fixed document ID overwrites that document, never appends;
/// * `userId`, `recordId` and `createdAt` cannot change on an existing document;
/// * a recommendation cannot be created without its parent SQI record;
/// * the recommendation batch is atomic, so a failure writes nothing.
///
/// Payloads are stored in JSON-encodable form (timestamps as ISO strings) so a
/// test can compare two attempts byte for byte and so the same shape can be
/// handed to the Firestore emulator suite.
class _FirestoreDouble {
  final records = <String, Map<String, dynamic>>{};
  final recommendations = <String, Map<String, dynamic>>{};

  /// Every record payload that reached the "database", in order.
  final recordWrites = <Map<String, dynamic>>[];

  /// Every recommendation batch that reached the "database", successful or not.
  final recommendationAttempts = <List<Recommendation>>[];

  /// When true the next recommendation batch throws before writing anything,
  /// which is what a rejected write looks like to the use case.
  bool failRecommendations = false;

  int _allocated = 0;

  String newRecordId() => 'record-${++_allocated}';

  Future<void> saveRecord(SQIRecord record) async {
    final payload = _encode(record.toFirestore());
    final existing = records[record.recordId];
    if (existing != null) {
      _rejectImmutableChanges(existing, payload, const [
        'userId',
        'createdAt',
      ], 'sqiRecords/${record.recordId}');
    }
    records[record.recordId] = payload;
    recordWrites.add(payload);
  }

  Future<void> saveRecommendations(List<Recommendation> batch) async {
    recommendationAttempts.add(batch);
    if (failRecommendations) {
      throw Exception('recommendation batch failed');
    }

    // Validate the whole batch first: a rejected write leaves nothing behind.
    final pending = <String, Map<String, dynamic>>{};
    for (final recommendation in batch) {
      final parent = records[recommendation.recordId];
      if (parent == null) {
        throw RulesRejection(
          'missing parent sqiRecords/${recommendation.recordId}',
        );
      }
      if (parent['userId'] != recommendation.userId) {
        throw RulesRejection('recommendation owner does not match its parent');
      }

      final payload = _encode(recommendation.toFirestore());
      final existing = recommendations[recommendation.recommendationId];
      if (existing != null) {
        _rejectImmutableChanges(existing, payload, const [
          'userId',
          'recordId',
          'createdAt',
        ], 'recommendations/${recommendation.recommendationId}');
      }
      pending[recommendation.recommendationId] = payload;
    }

    recommendations.addAll(pending);
  }

  void _rejectImmutableChanges(
    Map<String, dynamic> existing,
    Map<String, dynamic> next,
    List<String> immutable,
    String path,
  ) {
    for (final field in immutable) {
      if (existing[field] != next[field]) {
        throw RulesRejection(
          '$path: $field is immutable '
          '(${existing[field]} -> ${next[field]})',
        );
      }
    }
  }
}

/// Timestamps become ISO strings so payloads compare as plain JSON.
dynamic _encodeValue(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key as String: _encodeValue(entry.value),
    };
  }
  return value;
}

Map<String, dynamic> _encode(Map<String, dynamic> payload) =>
    _encodeValue(payload) as Map<String, dynamic>;

const _responses = <String, int>{
  'Sleep duration': 2,
  'Sleep regularity': 3,
  'Screen time': 3,
  'Exercise': 4,
  'Stress': 2,
  'Caffeine': 1,
};

/// The assessment one user submits in these tests, scored by the app itself so
/// the flow under test is the production flow.
SqiResult _result() => const CalculateSqi().call(responses: _responses);

SubmitSqiAssessment _submit(
  _FirestoreDouble store, {
  DateTime Function()? now,
  String Function()? newRecordId,
}) => SubmitSqiAssessment(
  newRecordId: newRecordId ?? store.newRecordId,
  writeRecord: store.saveRecord,
  writeRecommendations: store.saveRecommendations,
  now: now ?? DateTime.now,
);

String _json(Map<String, Object?> value) =>
    const JsonEncoder.withIndent('  ').convert(value);

void main() {
  group('retry after the recommendation write failed', () {
    test(
      'keeps the record, the IDs and every createdAt across the retry',
      () async {
        final store = _FirestoreDouble()..failRecommendations = true;
        final submit = _submit(store);

        expect(
          await submit(userId: 'owner-uid', result: _result()),
          SubmitSqiOutcome.recordSavedRecommendationsNotConfirmed,
        );

        // Attempt 1: the record landed, the recommendation batch did not.
        expect(store.recordWrites, hasLength(1));
        expect(store.recommendations, isEmpty);
        final recordId = store.records.keys.single;
        final firstAttempt = store.recommendationAttempts.single;
        final firstAttemptJson = [
          for (final rec in firstAttempt) _json(_encode(rec.toFirestore())),
        ];

        store.failRecommendations = false;
        expect(
          await submit(userId: 'owner-uid', result: _result()),
          SubmitSqiOutcome.saved,
        );

        // AC-04: the record is written once, at the ID allocated for the attempt.
        expect(store.recordWrites, hasLength(1), reason: 'no second record');
        expect(store.records.keys, [recordId]);

        // AC-01/AC-02/AC-05: the same object batch is resent, so the same
        // documents are overwritten and no duplicates exist.
        expect(store.recommendationAttempts, hasLength(2));
        expect(
          identical(
            store.recommendationAttempts[0],
            store.recommendationAttempts[1],
          ),
          isTrue,
          reason: 'the retry must reuse the cached batch, not rebuild it',
        );
        expect(store.recommendations, hasLength(firstAttempt.length));
        expect(
          store.recommendations.keys.toList(),
          firstAttempt.map((rec) => rec.recommendationId).toList(),
          reason: 'recommendation IDs must be unchanged by the retry',
        );
        for (var i = 0; i < firstAttempt.length; i++) {
          expect(
            firstAttempt[i].recommendationId,
            '$recordId-r$i',
            reason: 'recommendation IDs are derived from the record ID',
          );
        }

        // AC-03: the retried payload is byte for byte what the first attempt sent.
        expect(
          [
            for (final rec in store.recommendationAttempts[1])
              _json(_encode(rec.toFirestore())),
          ],
          firstAttemptJson,
          reason: 'a retry must not change the payload, createdAt included',
        );

        final recordCreatedAt = store.recordWrites.single['createdAt'];
        final firstAttemptTimestamps = firstAttempt
            .map((rec) => _encode(rec.toFirestore())['createdAt'])
            .toSet();
        for (final rec in store.recommendations.values) {
          expect(
            rec['createdAt'],
            isIn(firstAttemptTimestamps),
            reason: 'stored createdAt must be the one from the first attempt',
          );
        }
        expect(
          firstAttemptTimestamps,
          {recordCreatedAt},
          reason: 'recommendations share the immutable record timestamp',
        );

        // Duplicate prevention at the collection level, not just by ID.
        final keys = [
          for (final rec in store.recommendations.values)
            '${rec['userId']}|${rec['recordId']}|${rec['factor']}',
        ];
        expect(keys.toSet(), hasLength(keys.length), reason: 'no duplicates');
      },
    );

    test(
      'still-failing retries keep the payload they need to succeed',
      () async {
        final store = _FirestoreDouble()..failRecommendations = true;
        final submit = _submit(store);

        for (var attempt = 1; attempt <= 3; attempt++) {
          expect(
            await submit(userId: 'owner-uid', result: _result()),
            SubmitSqiOutcome.recordSavedRecommendationsNotConfirmed,
            reason: 'attempt $attempt must be reported as retryable',
          );
        }

        expect(store.recommendationAttempts, hasLength(3));
        expect(store.recordWrites, hasLength(1));
        final recordId = store.records.keys.single;
        final batchedIds = {
          for (final rec in store.recommendationAttempts.expand(
            (batch) => batch,
          ))
            rec.recommendationId,
        };

        store.failRecommendations = false;
        expect(
          await submit(userId: 'owner-uid', result: _result()),
          SubmitSqiOutcome.saved,
        );

        expect(store.records.keys, [recordId]);
        expect(store.recommendations.keys.toSet(), batchedIds);
        expect(
          store.recommendations.keys,
          hasLength(batchedIds.length),
          reason: 'repeated failures must not leak duplicate documents',
        );
      },
    );

    test('a moving clock never changes the retried createdAt', () async {
      // A real submission retries minutes later; the clock handed to the use
      // case moves forward on every read. The timestamp of the assessment must
      // still come from the first attempt — the bug this pins is a retry that
      // rebuilt the recommendations with a fresh DateTime.now().
      var ticks = 0;
      DateTime advancingClock() =>
          DateTime.utc(2026, 9, 25, 22).add(Duration(minutes: ticks++));

      final store = _FirestoreDouble()..failRecommendations = true;
      final submit = _submit(store, now: advancingClock);

      await submit(userId: 'owner-uid', result: _result());
      final firstAttempt = store.recommendationAttempts.single;
      final recordCreatedAt = store.recordWrites.single['createdAt'];

      store.failRecommendations = false;
      expect(
        await submit(userId: 'owner-uid', result: _result()),
        SubmitSqiOutcome.saved,
      );

      final retried = store.recommendationAttempts.last;
      for (var i = 0; i < firstAttempt.length; i++) {
        expect(
          _encode(retried[i].toFirestore())['createdAt'],
          _encode(firstAttempt[i].toFirestore())['createdAt'],
          reason: 'retry must resend the first attempt timestamp',
        );
        expect(
          _encode(retried[i].toFirestore())['createdAt'],
          recordCreatedAt,
          reason: 'recommendation createdAt must match its record',
        );
      }
      expect(store.recordWrites, hasLength(1));
    });

    test(
      'reset starts a new assessment instead of reusing the cache',
      () async {
        final store = _FirestoreDouble();
        final submit = _submit(store);

        expect(
          await submit(userId: 'owner-uid', result: _result()),
          SubmitSqiOutcome.saved,
        );
        final firstRecordId = store.records.keys.single;
        final firstRecommendationIds = store.recommendations.keys.toSet();

        submit.reset();
        expect(submit.recordId, isNull);
        expect(submit.recordSaved, isFalse);

        expect(
          await submit(userId: 'owner-uid', result: _result()),
          SubmitSqiOutcome.saved,
        );

        final secondRecordId = store.records.keys.last;
        expect(secondRecordId, isNot(firstRecordId));
        expect(store.records, hasLength(2));

        final secondRecommendationIds = store.recommendations.keys
            .where((id) => id.startsWith(secondRecordId))
            .toSet();
        expect(secondRecommendationIds, isNotEmpty);
        expect(
          secondRecommendationIds.intersection(firstRecommendationIds),
          isEmpty,
          reason: 'a new assessment must not overwrite the previous one',
        );
        expect(
          store.recommendations,
          hasLength(
            firstRecommendationIds.length + secondRecommendationIds.length,
          ),
        );
      },
    );
  });

  group('Recommendation.copyWith', () {
    test('keeps createdAt when only the document ID changes', () {
      final createdAt = DateTime.utc(2026, 9, 25, 22);
      final original = Recommendation(
        recommendationId: '',
        userId: 'owner-uid',
        recordId: 'record-1',
        factor: 'Caffeine',
        title: 'Cut back on late caffeine',
        description: 'Caffeine can stay in your system and disrupt sleep.',
        action: 'Avoid caffeine at least 6 hours before bed.',
        priority: 'high',
        createdAt: createdAt,
      );

      final copied = original.copyWith(recommendationId: 'record-1-r0');

      expect(copied.recommendationId, 'record-1-r0');
      expect(copied.createdAt, createdAt);
      expect(
        copied.toFirestore()['createdAt'],
        original.toFirestore()['createdAt'],
      );
    });

    test('an explicit createdAt overrides the original', () {
      final createdAt = DateTime.utc(2026, 9, 25, 22);
      final original = Recommendation(
        recommendationId: 'record-1-r0',
        userId: 'owner-uid',
        recordId: 'record-1',
        factor: 'Caffeine',
        title: 'Cut back on late caffeine',
        description: 'Caffeine can stay in your system and disrupt sleep.',
        action: 'Avoid caffeine at least 6 hours before bed.',
        priority: 'high',
        createdAt: createdAt,
      );

      final moved = createdAt.add(const Duration(hours: 1));
      expect(original.copyWith(createdAt: moved).createdAt, moved);
    });
  });

  // The Firestore emulator suite is Node.js and cannot call Dart, so it replays
  // this fixture instead. The fixture is the real payload of the flow above
  // (SubmitSqiAssessment -> FirestoreService), and this test fails as soon as
  // the app writes something different, so the emulator can never pass against
  // a payload the app would not produce.
  //
  // Regenerate after an intentional payload change:
  //   flutter test test/retry_assessment_e2e_test.dart --dart-define=UPDATE_FIXTURE=true
  group('Firestore emulator fixture', () {
    const fixturePath = 'firestore-rules-test/fixtures/retry-assessment.json';
    const userId = 'fixture-owner-uid';
    const recordId = 'fixture-record-id';
    final createdAt = DateTime.utc(2026, 9, 25, 22);

    test('matches the payload the app writes for one assessment', () async {
      final store = _FirestoreDouble()..failRecommendations = true;
      final submit = _submit(
        store,
        now: () => createdAt,
        newRecordId: () => recordId,
      );

      // Attempt 1 fails at the recommendations, the retry completes it.
      await submit(userId: userId, result: _result());
      store.failRecommendations = false;
      expect(
        await submit(userId: userId, result: _result()),
        SubmitSqiOutcome.saved,
      );

      final recommendationIds = store.recommendations.keys.toList()..sort();
      final fixture = <String, Object?>{
        'description':
            'Generated from SubmitSqiAssessment + FirestoreService payloads. '
            'Do not edit by hand; regenerate with --dart-define=UPDATE_FIXTURE=true.',
        'userId': userId,
        'recordId': recordId,
        'createdAt': createdAt.toIso8601String(),
        'record': store.records[recordId],
        'recommendations': [
          for (final id in recommendationIds)
            {'documentId': id, 'data': store.recommendations[id]},
        ],
      };

      final actual = '${_json(fixture)}\n';
      final file = File(fixturePath);

      if (const bool.fromEnvironment('UPDATE_FIXTURE')) {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(actual);
      }

      expect(
        file.existsSync(),
        isTrue,
        reason:
            'missing $fixturePath; generate it with '
            '--dart-define=UPDATE_FIXTURE=true',
      );
      expect(
        file.readAsStringSync().replaceAll('\r\n', '\n'),
        actual,
        reason:
            'the emulator fixture no longer matches the payload the app '
            'writes; regenerate it with --dart-define=UPDATE_FIXTURE=true '
            'and re-read firestore-rules-test/firestore.rules.test.mjs',
      );
    });
  });
}
