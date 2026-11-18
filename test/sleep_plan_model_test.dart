import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/models/read/firestore_read.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';

Map<String, dynamic> validPlanData() => {
  'userId': 'owner-1',
  'wakeUpTime': Timestamp.fromDate(DateTime(2026, 11, 14, 7, 0)),
  'createdAt': Timestamp.fromDate(DateTime(2026, 11, 13, 23, 0)),
  'sleepCycles': 5,
  'suggestedBedtimes': ['11:15 PM', '12:45 AM', '2:15 AM'],
};

void main() {
  group('SleepPlanReadResult.parse', () {
    test('valid current document parses as Valid', () {
      final result = SleepPlanReadResult.parse(validPlanData(), 'plan-1');
      expect(result.isValid, isTrue);
      expect(result.quality, ReadQuality.valid);
      expect(result is SleepPlanValid, isTrue);
      final plan = (result as SleepPlanValid).plan;
      expect(plan.planId, 'plan-1');
      expect(plan.userId, 'owner-1');
      expect(plan.wakeUpTime, DateTime(2026, 11, 14, 7, 0));
      expect(plan.createdAt, DateTime(2026, 11, 13, 23, 0));
      expect(plan.sleepCycles, 5);
      expect(plan.suggestedBedtimes, ['11:15 PM', '12:45 AM', '2:15 AM']);
    });

    test('missing wakeUpTime is Invalid, never replaced with now', () {
      final data = validPlanData()..remove('wakeUpTime');
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
      expect((result as SleepPlanInvalid).partial.wakeUpTime, isNull);
    });

    test('null wakeUpTime is Invalid', () {
      final data = validPlanData()..['wakeUpTime'] = null;
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
    });

    test('wrong-type wakeUpTime is Invalid', () {
      final data = validPlanData()..['wakeUpTime'] = '07:00';
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
      expect(
        result.issues.any((i) => i.field == 'wakeUpTime' && i.kind == FieldIssueKind.wrongType),
        isTrue,
      );
    });

    test('missing createdAt is Invalid', () {
      final data = validPlanData()..remove('createdAt');
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
    });

    test('out-of-range sleepCycles is an issue but plan stays displayable', () {
      final data = validPlanData()..['sleepCycles'] = 99;
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isLegacy, isTrue);
      final legacy = result as SleepPlanLegacy;
      expect(legacy.partial.canDisplayPlan, isTrue);
      expect(legacy.partial.sleepCycles, isNull);
      expect(
        legacy.issues.any((i) => i.field == 'sleepCycles' && i.kind == FieldIssueKind.outOfRange),
        isTrue,
      );
    });

    test('wrong-type sleepCycles is an issue', () {
      final data = validPlanData()..['sleepCycles'] = 'five';
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isLegacy, isTrue);
      expect(
        result.issues.any((i) => i.field == 'sleepCycles' && i.kind == FieldIssueKind.wrongType),
        isTrue,
      );
    });

    test('bedtime list with a null element keeps valid entries', () {
      final data = validPlanData();
      data['suggestedBedtimes'] = ['11:15 PM', null, '2:15 AM'];
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isLegacy, isTrue);
      final legacy = result as SleepPlanLegacy;
      expect(legacy.partial.verifiedBedtimeEntries, ['11:15 PM', '2:15 AM']);
      expect(legacy.partial.bedtimeListComplete, isFalse);
      expect(
        legacy.issues.any((i) => i.field == 'suggestedBedtimes[1]'),
        isTrue,
      );
    });

    test('empty bedtime list is an issue', () {
      final data = validPlanData()..['suggestedBedtimes'] = <String>[];
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
    });

    test('wrong-type bedtime list is an issue', () {
      final data = validPlanData()..['suggestedBedtimes'] = 'not a list';
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
      expect(
        result.issues.any((i) => i.field == 'suggestedBedtimes' && i.kind == FieldIssueKind.wrongType),
        isTrue,
      );
    });

    test('missing userId is Invalid', () {
      final data = validPlanData()..remove('userId');
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
    });

    test('valid plan with missing cycle count is Legacy', () {
      final data = validPlanData()..remove('sleepCycles');
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isLegacy, isTrue);
      final legacy = result as SleepPlanLegacy;
      expect(legacy.partial.canDisplayPlan, isTrue);
      expect(legacy.partial.sleepCycles, isNull);
    });

    test('missing all bedtimes but valid times is Invalid', () {
      final data = validPlanData()..['suggestedBedtimes'] = <String>[];
      final result = SleepPlanReadResult.parse(data, 'plan-1');
      expect(result.isInvalid, isTrue);
    });
  });

  group('SleepPlanReadBatch', () {
    test('one bad document does not crash the batch read', () {
      final valid = SleepPlanReadResult.parse(validPlanData(), 'plan-1');
      final bad = SleepPlanReadResult.parse(validPlanData()..remove('wakeUpTime'), 'plan-2');
      final batch = SleepPlanReadBatch([valid, bad]);
      expect(batch.validCount, 1);
      expect(batch.invalidCount, 1);
      expect(batch.displayable.length, 1);
    });
  });
}
