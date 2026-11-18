import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/models/read/firestore_read.dart';
import 'package:snoozemate/models/sqi_record_model.dart';

Map<String, dynamic> validSqiData() => {
  'userId': 'owner-1',
  'sqiScore': 42,
  'sleepQualityLevel': 'fair',
  'questionnaireResponses': {
    'Sleep duration': 2,
    'Sleep regularity': 4,
    'Screen time': 3,
    'Exercise': 3,
    'Stress': 2,
    'Caffeine': 1,
  },
  'createdAt': Timestamp.fromDate(DateTime(2026, 11, 13, 23, 0)),
};

void main() {
  group('SQIRecordReadResult.parse', () {
    test('valid current document parses as Valid', () {
      final result = SQIRecordReadResult.parse(validSqiData(), 'rec-1');
      expect(result.isValid, isTrue);
      expect(result.quality, ReadQuality.valid);
      expect(result is SQIRecordValid, isTrue);
      final record = (result as SQIRecordValid).record;
      expect(record.recordId, 'rec-1');
      expect(record.userId, 'owner-1');
      expect(record.sqiScore, 42);
      expect(record.sleepQualityLevel, 'fair');
      expect(record.questionnaireResponses, {
        'Sleep duration': 2,
        'Sleep regularity': 4,
        'Screen time': 3,
        'Exercise': 3,
        'Stress': 2,
        'Caffeine': 1,
      });
      expect(record.createdAt, DateTime(2026, 11, 13, 23, 0));
    });

    test('missing sqiScore is Invalid, not defaulted to 0', () {
      final data = validSqiData()..remove('sqiScore');
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
      expect(result.quality, ReadQuality.invalid);
      expect(result is SQIRecordInvalid, isTrue);
      expect(
        result.issues.any(
          (i) => i.field == 'sqiScore' && i.kind == FieldIssueKind.missing,
        ),
        isTrue,
      );
    });

    test('null sqiScore is Invalid', () {
      final data = validSqiData()..['sqiScore'] = null;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
      expect(
        result.issues.any(
          (i) => i.field == 'sqiScore' && i.kind == FieldIssueKind.nullValue,
        ),
        isTrue,
      );
    });

    test('wrong-type sqiScore is Invalid', () {
      final data = validSqiData()..['sqiScore'] = '42';
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
      expect(
        result.issues.any(
          (i) => i.field == 'sqiScore' && i.kind == FieldIssueKind.wrongType,
        ),
        isTrue,
      );
    });

    test('out-of-range sqiScore is Invalid', () {
      final data = validSqiData()..['sqiScore'] = 101;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
      expect(
        result.issues.any(
          (i) => i.field == 'sqiScore' && i.kind == FieldIssueKind.outOfRange,
        ),
        isTrue,
      );
    });

    test('negative sqiScore is Invalid', () {
      final data = validSqiData()..['sqiScore'] = -1;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
    });

    test('missing sleepQualityLevel with valid score+timestamp is Legacy', () {
      final data = validSqiData()..remove('sleepQualityLevel');
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isLegacy, isTrue);
      final legacy = result as SQIRecordLegacy;
      expect(legacy.partial.canDisplayScore, isTrue);
      expect(legacy.partial.sleepQualityLevel, isNull);
    });

    test('null sleepQualityLevel is not defaulted to Fair', () {
      final data = validSqiData()..['sleepQualityLevel'] = null;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result is! SQIRecordValid, isTrue);
      final legacy = result as SQIRecordLegacy;
      expect(legacy.partial.sleepQualityLevel, isNull);
    });

    test(
      'unknown sleepQualityLevel string with valid score+timestamp is Legacy',
      () {
        final data = validSqiData()..['sleepQualityLevel'] = 'Excellent';
        final result = SQIRecordReadResult.parse(data, 'rec-1');
        expect(result.isLegacy, isTrue);
        expect((result as SQIRecordLegacy).partial.sleepQualityLevel, isNull);
      },
    );

    test('wrong-type sleepQualityLevel is an issue', () {
      final data = validSqiData()..['sleepQualityLevel'] = 42;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(
        result.issues.any(
          (i) =>
              i.field == 'sleepQualityLevel' &&
              i.kind == FieldIssueKind.wrongType,
        ),
        isTrue,
      );
    });

    test('missing createdAt is Invalid, never replaced with now', () {
      final data = validSqiData()..remove('createdAt');
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
      expect((result as SQIRecordInvalid).partial.createdAt, isNull);
    });

    test('null createdAt is Invalid', () {
      final data = validSqiData()..['createdAt'] = null;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
    });

    test('wrong-type createdAt is Invalid', () {
      final data = validSqiData()..['createdAt'] = '2026-11-13';
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
      expect(
        result.issues.any(
          (i) => i.field == 'createdAt' && i.kind == FieldIssueKind.wrongType,
        ),
        isTrue,
      );
    });

    test(
      'missing questionnaireResponses with valid score+timestamp is Legacy',
      () {
        final data = validSqiData()..remove('questionnaireResponses');
        final result = SQIRecordReadResult.parse(data, 'rec-1');
        expect(result.isLegacy, isTrue);
        final legacy = result as SQIRecordLegacy;
        expect(legacy.partial.canDisplayScore, isTrue);
        expect(legacy.partial.canDisplayQuestionnaire, isFalse);
        expect(legacy.partial.verifiedQuestionnaireResponses, isEmpty);
      },
    );

    test('null questionnaireResponses is not fabricated', () {
      final data = validSqiData()..['questionnaireResponses'] = null;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result is! SQIRecordValid, isTrue);
      expect(
        (result as SQIRecordLegacy).partial.canDisplayQuestionnaire,
        isFalse,
      );
    });

    test('questionnaire with wrong-type answers keeps valid entries only', () {
      final data = validSqiData();
      data['questionnaireResponses'] = {
        'Sleep duration': 2,
        'Sleep regularity': 'four',
        'Screen time': 3,
        'Exercise': 3,
        'Stress': 2,
        'Caffeine': 1,
      };
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isLegacy, isTrue);
      final legacy = result as SQIRecordLegacy;
      expect(legacy.partial.canDisplayScore, isTrue);
      expect(legacy.partial.canDisplayQuestionnaire, isFalse);
      expect(
        legacy.partial.verifiedQuestionnaireResponses['Sleep duration'],
        2,
      );
      expect(
        legacy.partial.verifiedQuestionnaireResponses.containsKey(
          'Sleep regularity',
        ),
        isFalse,
      );
    });

    test(
      'questionnaire with out-of-range answer is Legacy for questionnaire',
      () {
        final data = validSqiData();
        data['questionnaireResponses'] = {
          'Sleep duration': 0,
          'Sleep regularity': 4,
          'Screen time': 3,
          'Exercise': 3,
          'Stress': 2,
          'Caffeine': 1,
        };
        final result = SQIRecordReadResult.parse(data, 'rec-1');
        expect(result.isLegacy, isTrue);
        expect(
          (result as SQIRecordLegacy).partial.canDisplayQuestionnaire,
          isFalse,
        );
      },
    );

    test('questionnaire missing a key is Legacy for questionnaire', () {
      final data = validSqiData();
      final responses = Map<String, dynamic>.from(
        data['questionnaireResponses'],
      );
      responses.remove('Caffeine');
      data['questionnaireResponses'] = responses;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isLegacy, isTrue);
      expect(
        (result as SQIRecordLegacy).partial.canDisplayQuestionnaire,
        isFalse,
      );
    });

    test('missing userId is Invalid', () {
      final data = validSqiData()..remove('userId');
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
    });

    test('empty userId is Invalid', () {
      final data = validSqiData()..['userId'] = '';
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isInvalid, isTrue);
    });

    test(
      'valid score and timestamp but bad questionnaire is Legacy for score only',
      () {
        final data = validSqiData();
        data['questionnaireResponses'] = {};
        final result = SQIRecordReadResult.parse(data, 'rec-1');
        expect(result.isLegacy, isTrue);
        final legacy = result as SQIRecordLegacy;
        expect(legacy.partial.canDisplayScore, isTrue);
        expect(legacy.partial.sqiScore, 42);
        expect(legacy.partial.createdAt, DateTime(2026, 11, 13, 23, 0));
        expect(legacy.partial.canDisplayQuestionnaire, isFalse);
      },
    );
    test('extra questionnaire key prevents Valid', () {
      final data = validSqiData();
      data['questionnaireResponses']['Extra'] = 3;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isValid, isFalse);
      expect(
        result.issues.any(
          (i) =>
              i.field == 'questionnaireResponses.Extra' &&
              i.kind == FieldIssueKind.extraOrMissingKey,
        ),
        isTrue,
      );
      expect(result.isLegacy, isTrue);
    });

    test('extra questionnaire key with null value prevents Valid', () {
      final data = validSqiData();
      final responses = Map<String, dynamic>.from(
        data['questionnaireResponses'],
      );
      responses['Extra'] = null;
      data['questionnaireResponses'] = responses;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isValid, isFalse);
      expect(
        result.issues.any(
          (i) =>
              i.field == 'questionnaireResponses.Extra' &&
              i.kind == FieldIssueKind.extraOrMissingKey,
        ),
        isTrue,
      );
    });

    test('extra questionnaire key with wrong type prevents Valid', () {
      final data = validSqiData();
      final responses2 = Map<String, dynamic>.from(
        data['questionnaireResponses'],
      );
      responses2['Extra'] = 'bad';
      data['questionnaireResponses'] = responses2;
      final result = SQIRecordReadResult.parse(data, 'rec-1');
      expect(result.isValid, isFalse);
      expect(
        result.issues.any(
          (i) =>
              i.field == 'questionnaireResponses.Extra' &&
              i.kind == FieldIssueKind.extraOrMissingKey,
        ),
        isTrue,
      );
    });
  });

  group('SQIRecordReadBatch', () {
    test('mixed batch keeps valid and invalid independently', () {
      final valid = SQIRecordReadResult.parse(validSqiData(), 'rec-1');
      final bad = SQIRecordReadResult.parse(
        validSqiData()..remove('sqiScore'),
        'rec-2',
      );
      final batch = SQIRecordReadBatch([valid, bad]);
      expect(batch.validCount, 1);
      expect(batch.invalidCount, 1);
      expect(batch.legacyCount, 0);
      expect(batch.displayable.length, 1);
    });
  });
}
