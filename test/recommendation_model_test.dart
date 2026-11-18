import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/models/read/firestore_read.dart';
import 'package:snoozemate/models/recommendation_model.dart';

Map<String, dynamic> validRecData() => {
  'userId': 'owner-1',
  'recordId': 'rec-1',
  'factor': 'Caffeine',
  'title': 'Cut evening caffeine',
  'description': 'Avoid coffee after 2 PM.',
  'action': 'Switch to herbal tea.',
  'priority': 'high',
  'createdAt': Timestamp.fromDate(DateTime(2026, 11, 13, 23, 0)),
};

void main() {
  group('RecommendationReadResult.parse', () {
    test('valid current document parses as Valid', () {
      final result = RecommendationReadResult.parse(validRecData(), 'rec-1-r0');
      expect(result.isValid, isTrue);
      expect(result.quality, ReadQuality.valid);
      expect(result is RecommendationValid, isTrue);
      final rec = (result as RecommendationValid).record;
      expect(rec.recommendationId, 'rec-1-r0');
      expect(rec.userId, 'owner-1');
      expect(rec.recordId, 'rec-1');
      expect(rec.factor, 'Caffeine');
      expect(rec.title, 'Cut evening caffeine');
      expect(rec.description, 'Avoid coffee after 2 PM.');
      expect(rec.action, 'Switch to herbal tea.');
      expect(rec.priority, 'high');
      expect(rec.createdAt, DateTime(2026, 11, 13, 23, 0));
    });

    test('missing title is not fabricated', () {
      final data = validRecData()..remove('title');
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result is! RecommendationValid, isTrue);
      final partial = (result as dynamic).partial;
      expect(partial.title, isNull);
    });

    test('null title is Invalid', () {
      final data = validRecData()..['title'] = null;
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isInvalid, isTrue);
    });

    test('empty title is Invalid', () {
      final data = validRecData()..['title'] = '';
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isInvalid, isTrue);
    });

    test('missing createdAt is Invalid, never replaced with now', () {
      final data = validRecData()..remove('createdAt');
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isInvalid, isTrue);
      expect((result as RecommendationInvalid).partial.createdAt, isNull);
    });

    test('null createdAt is Invalid', () {
      final data = validRecData()..['createdAt'] = null;
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isInvalid, isTrue);
    });

    test('wrong-type createdAt is Invalid', () {
      final data = validRecData()..['createdAt'] = '2026-11-13';
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isInvalid, isTrue);
    });

    test('missing recordId is Invalid', () {
      final data = validRecData()..remove('recordId');
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isInvalid, isTrue);
    });

    test('unknown priority is an issue but record may still display', () {
      final data = validRecData()..['priority'] = 'urgent';
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result is! RecommendationValid, isTrue);
      final legacy = result as RecommendationLegacy;
      expect(legacy.partial.canDisplayRecommendation, isTrue);
      expect(legacy.partial.priority, isNull);
    });

    test('wrong-type priority is an issue', () {
      final data = validRecData()..['priority'] = 42;
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(
        result.issues.any(
          (i) => i.field == 'priority' && i.kind == FieldIssueKind.wrongType,
        ),
        isTrue,
      );
    });

    test('missing userId is Invalid', () {
      final data = validRecData()..remove('userId');
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isInvalid, isTrue);
    });

    test('partial recommendation with title+createdAt is Legacy', () {
      final data = validRecData()..remove('description');
      final result = RecommendationReadResult.parse(data, 'rec-1-r0');
      expect(result.isLegacy, isTrue);
      final legacy = result as RecommendationLegacy;
      expect(legacy.partial.canDisplayRecommendation, isTrue);
      expect(legacy.partial.title, 'Cut evening caffeine');
      expect(legacy.partial.description, isNull);
    });
  });

  group('RecommendationReadBatch', () {
    test('mixed batch keeps valid and invalid independently', () {
      final valid = RecommendationReadResult.parse(validRecData(), 'rec-1-r0');
      final bad = RecommendationReadResult.parse(
        validRecData()..remove('title'),
        'rec-1-r1',
      );
      final batch = RecommendationReadBatch([valid, bad]);
      expect(batch.validCount, 1);
      expect(batch.invalidCount, 1);
      expect(batch.displayable.length, 1);
    });
  });
}
