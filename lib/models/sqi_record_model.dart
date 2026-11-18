import 'package:cloud_firestore/cloud_firestore.dart';

import 'read/firestore_read.dart';

/// Current-contract, fully valid SQI record (safe for writes and full display).
class SQIRecord {
  final String recordId;
  final String userId;
  final int sqiScore;
  final String sleepQualityLevel;
  final Map<String, dynamic> questionnaireResponses;
  final DateTime createdAt;

  SQIRecord({
    required this.recordId,
    required this.userId,
    required this.sqiScore,
    required this.sleepQualityLevel,
    required this.questionnaireResponses,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sqiScore': sqiScore,
      'sleepQualityLevel': sleepQualityLevel,
      'questionnaireResponses': questionnaireResponses,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Verified, safely displayable subset of an SQI record. Fields are null only
/// when that specific value could not be validated; no values are invented.
class SQIRecordPartial {
  final String recordId;
  final String? userId;
  final int? sqiScore;
  final String? sleepQualityLevel;
  final Map<String, dynamic> verifiedQuestionnaireResponses;
  final bool questionnaireComplete;
  final DateTime? createdAt;

  const SQIRecordPartial({
    required this.recordId,
    this.userId,
    this.sqiScore,
    this.sleepQualityLevel,
    this.verifiedQuestionnaireResponses = const <String, int>{},
    this.questionnaireComplete = false,
    this.createdAt,
  });

  bool get canDisplayScore => userId != null && sqiScore != null && createdAt != null;

  bool get canDisplayQuestionnaire =>
      questionnaireComplete && createdAt != null;
}

const _sqiLevels = <String>{'poor', 'fair', 'good', 'excellent'};
const _questionnaireKeys = <String>{
  'Sleep duration',
  'Sleep regularity',
  'Screen time',
  'Exercise',
  'Stress',
  'Caffeine',
};

sealed class SQIRecordReadResult implements DocumentReadResult {
  const SQIRecordReadResult();

  static SQIRecordReadResult parse(Map<String, dynamic> data, String documentId) {
    final issues = FieldIssues();

    // userId
    String? userId;
    if (!data.containsKey('userId')) {
      issues.add('userId', FieldIssueKind.missing, expected: 'String');
    } else {
      final raw = data['userId'];
      if (raw == null) {
        issues.add('userId', FieldIssueKind.nullValue, expected: 'String');
      } else if (raw is String) {
        userId = raw;
        if (raw.isEmpty) {
          issues.add('userId', FieldIssueKind.outOfRange,
              expected: 'non-empty String', actual: raw);
          userId = null;
        }
      } else {
        issues.add('userId', FieldIssueKind.wrongType,
            expected: 'String', actual: raw);
      }
    }

    // sqiScore
    int? sqiScore;
    if (!data.containsKey('sqiScore')) {
      issues.add('sqiScore', FieldIssueKind.missing, expected: 'int 0-100');
    } else {
      final raw = data['sqiScore'];
      if (raw == null) {
        issues.add('sqiScore', FieldIssueKind.nullValue, expected: 'int 0-100');
      } else if (raw is int) {
        if (raw >= 0 && raw <= 100) {
          sqiScore = raw;
        } else {
          issues.add('sqiScore', FieldIssueKind.outOfRange,
              expected: 'int 0-100', actual: raw);
        }
      } else {
        issues.add('sqiScore', FieldIssueKind.wrongType,
            expected: 'int 0-100', actual: raw);
      }
    }

    // sleepQualityLevel
    String? sleepQualityLevel;
    if (!data.containsKey('sleepQualityLevel')) {
      issues.add('sleepQualityLevel', FieldIssueKind.missing,
          expected: 'one of poor/fair/good/excellent');
    } else {
      final raw = data['sleepQualityLevel'];
      if (raw == null) {
        issues.add('sleepQualityLevel', FieldIssueKind.nullValue,
            expected: 'one of poor/fair/good/excellent');
      } else if (raw is String) {
        if (_sqiLevels.contains(raw)) {
          sleepQualityLevel = raw;
        } else {
          issues.add('sleepQualityLevel', FieldIssueKind.unknownValue,
              expected: 'one of poor/fair/good/excellent', actual: raw);
        }
      } else {
        issues.add('sleepQualityLevel', FieldIssueKind.wrongType,
            expected: 'String', actual: raw);
      }
    }

    // questionnaireResponses
    final verifiedResponses = <String, int>{};
    bool questionnaireComplete = false;
    if (!data.containsKey('questionnaireResponses')) {
      issues.add('questionnaireResponses', FieldIssueKind.missing,
          expected: 'Map<String,int> with 6 keys');
    } else {
      final raw = data['questionnaireResponses'];
      if (raw == null) {
        issues.add('questionnaireResponses', FieldIssueKind.nullValue,
            expected: 'Map<String,int>');
      } else if (raw is Map) {
        var allKeysPresent = true;
        var allValuesValid = true;
        for (final key in _questionnaireKeys) {
          if (!raw.containsKey(key)) {
            issues.add('questionnaireResponses.$key',
                FieldIssueKind.missing, expected: 'int 1-5');
            allKeysPresent = false;
            continue;
          }
          final val = raw[key];
          if (val is int && val >= 1 && val <= 5) {
            verifiedResponses[key] = val;
          } else if (val == null) {
            issues.add('questionnaireResponses.$key',
                FieldIssueKind.nullValue, expected: 'int 1-5');
            allValuesValid = false;
          } else {
            issues.add('questionnaireResponses.$key',
                FieldIssueKind.outOfRange, expected: 'int 1-5', actual: val);
            allValuesValid = false;
          }
        }
        questionnaireComplete = allKeysPresent && allValuesValid;
        for (final extraKey in raw.keys) {
          if (!_questionnaireKeys.contains(extraKey)) {
            issues.add(
              'questionnaireResponses.$extraKey',
              FieldIssueKind.extraOrMissingKey,
              expected: 'not part of the six-key schema',
              actual: raw[extraKey],
            );
          }
        }
      } else {
        issues.add('questionnaireResponses', FieldIssueKind.wrongType,
            expected: 'Map<String,int>', actual: raw);
      }
    }

    // createdAt
    DateTime? createdAt;
    if (!data.containsKey('createdAt')) {
      issues.add('createdAt', FieldIssueKind.missing, expected: 'Timestamp');
    } else {
      final raw = data['createdAt'];
      if (raw == null) {
        issues.add('createdAt', FieldIssueKind.nullValue, expected: 'Timestamp');
      } else if (raw is Timestamp) {
        createdAt = raw.toDate();
      } else {
        issues.add('createdAt', FieldIssueKind.wrongType,
            expected: 'Timestamp', actual: raw);
      }
    }

    final partial = SQIRecordPartial(
      recordId: documentId,
      userId: userId,
      sqiScore: sqiScore,
      sleepQualityLevel: sleepQualityLevel,
      verifiedQuestionnaireResponses: Map.unmodifiable(verifiedResponses),
      questionnaireComplete: questionnaireComplete,
      createdAt: createdAt,
    );

    if (!issues.hasIssues &&
        userId != null &&
        sqiScore != null &&
        sleepQualityLevel != null &&
        questionnaireComplete &&
        createdAt != null) {
      return SQIRecordValid(
        documentId: documentId,
        record: SQIRecord(
          recordId: documentId,
          userId: userId,
          sqiScore: sqiScore,
          sleepQualityLevel: sleepQualityLevel,
          questionnaireResponses: Map.unmodifiable(verifiedResponses),
          createdAt: createdAt,
        ),
      );
    }

    if (partial.canDisplayScore) {
      return SQIRecordLegacy(
        documentId: documentId,
        partial: partial,
        issues: issues.items,
      );
    }

    return SQIRecordInvalid(
      documentId: documentId,
      partial: partial,
      issues: issues.items.isEmpty
          ? [
              const FieldIssue(
                  field: 'document',
                  kind: FieldIssueKind.missing,
                  expected: 'displayable SQI score and timestamp')
            ]
          : issues.items,
    );
  }
}

class SQIRecordValid extends SQIRecordReadResult {
  @override
  final String documentId;
  final SQIRecord record;
  const SQIRecordValid({required this.documentId, required this.record});
  @override
  ReadQuality get quality => ReadQuality.valid;
  @override
  bool get isValid => true;
  @override
  bool get isLegacy => false;
  @override
  bool get isInvalid => false;
  @override
  List<FieldIssue> get issues => const [];
}

class SQIRecordLegacy extends SQIRecordReadResult {
  @override
  final String documentId;
  final SQIRecordPartial partial;
  @override
  final List<FieldIssue> issues;
  const SQIRecordLegacy(
      {required this.documentId, required this.partial, required this.issues});
  @override
  ReadQuality get quality => ReadQuality.legacy;
  @override
  bool get isValid => false;
  @override
  bool get isLegacy => true;
  @override
  bool get isInvalid => false;
}

class SQIRecordInvalid extends SQIRecordReadResult {
  @override
  final String documentId;
  final SQIRecordPartial partial;
  @override
  final List<FieldIssue> issues;
  const SQIRecordInvalid(
      {required this.documentId, required this.partial, required this.issues});
  @override
  ReadQuality get quality => ReadQuality.invalid;
  @override
  bool get isValid => false;
  @override
  bool get isLegacy => false;
  @override
  bool get isInvalid => true;
}

class SQIRecordReadBatch {
  final List<SQIRecordReadResult> results;
  const SQIRecordReadBatch(this.results);

  int get validCount => results.where((r) => r.isValid).length;
  int get legacyCount => results.where((r) => r.isLegacy).length;
  int get invalidCount => results.where((r) => r.isInvalid).length;

  List<SQIRecordReadResult> get displayable =>
      results.where((r) => r.isValid || r.isLegacy).toList();
}
