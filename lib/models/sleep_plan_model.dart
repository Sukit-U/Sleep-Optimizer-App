import 'package:cloud_firestore/cloud_firestore.dart';

import 'read/firestore_read.dart';

/// Sync status for a local sleep plan.
enum LocalSleepPlanSyncStatus { pending, synced, failed }

/// Current-contract, fully valid sleep plan (safe for writes and full display).
class SleepPlan {
  final String planId;
  final String userId;
  final DateTime wakeUpTime;
  final DateTime createdAt;
  final int sleepCycles;
  final List<String> suggestedBedtimes;
  final LocalSleepPlanSyncStatus? syncStatus;
  final String? cloudPlanId;

  SleepPlan({
    required this.planId,
    required this.userId,
    required this.wakeUpTime,
    required this.createdAt,
    required this.sleepCycles,
    required this.suggestedBedtimes,
    this.syncStatus,
    this.cloudPlanId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'wakeUpTime': Timestamp.fromDate(wakeUpTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'sleepCycles': sleepCycles,
      'suggestedBedtimes': suggestedBedtimes,
    };
  }
}

/// Verified, safely displayable subset of a sleep plan. Fields are null/empty
/// only when that specific value could not be validated; no values are invented.
class SleepPlanPartial {
  final String planId;
  final String? userId;
  final DateTime? wakeUpTime;
  final DateTime? createdAt;
  final int? sleepCycles;
  final List<String> verifiedBedtimeEntries;
  final bool bedtimeListComplete;

  const SleepPlanPartial({
    required this.planId,
    this.userId,
    this.wakeUpTime,
    this.createdAt,
    this.sleepCycles,
    this.verifiedBedtimeEntries = const <String>[],
    this.bedtimeListComplete = false,
  });

  bool get canDisplayPlan =>
      userId != null &&
      wakeUpTime != null &&
      createdAt != null &&
      verifiedBedtimeEntries.isNotEmpty;
}

sealed class SleepPlanReadResult implements DocumentReadResult {
  const SleepPlanReadResult();

  static SleepPlanReadResult parse(
    Map<String, dynamic> data,
    String documentId,
  ) {
    try {
      final issues = FieldIssues();

      // userId
      String? userId;
      final rawUser = data['userId'];
      if (!data.containsKey('userId')) {
        issues.add('userId', FieldIssueKind.missing, expected: 'String');
      } else if (rawUser == null) {
        issues.add('userId', FieldIssueKind.nullValue, expected: 'String');
      } else if (rawUser is String) {
        userId = rawUser;
        if (rawUser.isEmpty) {
          issues.add(
            'userId',
            FieldIssueKind.outOfRange,
            expected: 'non-empty String',
            actual: rawUser,
          );
          userId = null;
        }
      } else {
        issues.add(
          'userId',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: rawUser,
        );
      }

      // wakeUpTime
      DateTime? wakeUpTime;
      if (!data.containsKey('wakeUpTime')) {
        issues.add('wakeUpTime', FieldIssueKind.missing, expected: 'Timestamp');
      } else {
        final raw = data['wakeUpTime'];
        if (raw == null) {
          issues.add(
            'wakeUpTime',
            FieldIssueKind.nullValue,
            expected: 'Timestamp',
          );
        } else if (raw is Timestamp) {
          wakeUpTime = raw.toDate();
        } else {
          issues.add(
            'wakeUpTime',
            FieldIssueKind.wrongType,
            expected: 'Timestamp',
            actual: raw,
          );
        }
      }

      // createdAt
      DateTime? createdAt;
      if (!data.containsKey('createdAt')) {
        issues.add('createdAt', FieldIssueKind.missing, expected: 'Timestamp');
      } else {
        final raw = data['createdAt'];
        if (raw == null) {
          issues.add(
            'createdAt',
            FieldIssueKind.nullValue,
            expected: 'Timestamp',
          );
        } else if (raw is Timestamp) {
          createdAt = raw.toDate();
        } else {
          issues.add(
            'createdAt',
            FieldIssueKind.wrongType,
            expected: 'Timestamp',
            actual: raw,
          );
        }
      }

      // sleepCycles
      int? sleepCycles;
      if (!data.containsKey('sleepCycles')) {
        issues.add('sleepCycles', FieldIssueKind.missing, expected: 'int');
      } else {
        final raw = data['sleepCycles'];
        if (raw == null) {
          issues.add('sleepCycles', FieldIssueKind.nullValue, expected: 'int');
        } else if (raw is int) {
          if (raw >= 1 && raw <= 10) {
            sleepCycles = raw;
          } else {
            issues.add(
              'sleepCycles',
              FieldIssueKind.outOfRange,
              expected: 'int 1-10',
              actual: raw,
            );
          }
        } else {
          issues.add(
            'sleepCycles',
            FieldIssueKind.wrongType,
            expected: 'int',
            actual: raw,
          );
        }
      }

      // suggestedBedtimes
      final verifiedBedtimes = <String>[];
      bool bedtimeListComplete = false;
      bool bedtimeCurrentShape = false;
      if (!data.containsKey('suggestedBedtimes')) {
        issues.add(
          'suggestedBedtimes',
          FieldIssueKind.missing,
          expected: 'List<String> of 3 non-empty strings',
        );
      } else {
        final raw = data['suggestedBedtimes'];
        if (raw == null) {
          issues.add(
            'suggestedBedtimes',
            FieldIssueKind.nullValue,
            expected: 'List<String>',
          );
        } else if (raw is List) {
          var allValid = true;
          for (var i = 0; i < raw.length; i++) {
            final e = raw[i];
            if (e is String && e.trim().isNotEmpty) {
              verifiedBedtimes.add(e);
            } else if (e == null) {
              issues.add(
                'suggestedBedtimes[$i]',
                FieldIssueKind.nullValue,
                expected: 'non-empty String',
              );
              allValid = false;
            } else if (e is String) {
              issues.add(
                'suggestedBedtimes[$i]',
                FieldIssueKind.outOfRange,
                expected: 'non-empty String',
                actual: e,
              );
              allValid = false;
            } else {
              issues.add(
                'suggestedBedtimes[$i]',
                FieldIssueKind.malformedElement,
                expected: 'non-empty String',
                actual: e,
              );
              allValid = false;
            }
          }
          bedtimeListComplete = allValid && raw.isNotEmpty;
          bedtimeCurrentShape = allValid && raw.length == 3;
          if (raw.isEmpty) {
            issues.add(
              'suggestedBedtimes',
              FieldIssueKind.outOfRange,
              expected: 'non-empty list',
              actual: raw,
            );
          } else if (raw.length != 3) {
            issues.add(
              'suggestedBedtimes',
              FieldIssueKind.outOfRange,
              expected: '3 entries (current contract)',
              actual: raw,
            );
          }
        } else {
          issues.add(
            'suggestedBedtimes',
            FieldIssueKind.wrongType,
            expected: 'List<String>',
            actual: raw,
          );
        }
      }

      final partial = SleepPlanPartial(
        planId: documentId,
        userId: userId,
        wakeUpTime: wakeUpTime,
        createdAt: createdAt,
        sleepCycles: sleepCycles,
        verifiedBedtimeEntries: List.unmodifiable(verifiedBedtimes),
        bedtimeListComplete: bedtimeListComplete,
      );

      if (!issues.hasIssues &&
          userId != null &&
          wakeUpTime != null &&
          createdAt != null &&
          sleepCycles != null &&
          bedtimeCurrentShape) {
        return SleepPlanValid(
          documentId: documentId,
          plan: SleepPlan(
            planId: documentId,
            userId: userId,
            wakeUpTime: wakeUpTime,
            createdAt: createdAt,
            sleepCycles: sleepCycles,
            suggestedBedtimes: List.unmodifiable(verifiedBedtimes),
          ),
        );
      }

      if (partial.canDisplayPlan) {
        return SleepPlanLegacy(
          documentId: documentId,
          partial: partial,
          issues: issues.items,
        );
      }

      return SleepPlanInvalid(
        documentId: documentId,
        partial: partial,
        issues: issues.items.isEmpty
            ? [
                const FieldIssue(
                  field: 'document',
                  kind: FieldIssueKind.missing,
                  expected: 'displayable plan fields',
                ),
              ]
            : issues.items,
      );
    } catch (e) {
      return SleepPlanInvalid(
        documentId: documentId,
        partial: SleepPlanPartial(planId: documentId),
        issues: [
          FieldIssue(
            field: 'document',
            kind: FieldIssueKind.malformedElement,
            expected: 'parseable map',
            actualType: e.runtimeType.toString(),
          ),
        ],
      );
    }
  }
}

class SleepPlanValid extends SleepPlanReadResult {
  @override
  final String documentId;
  final SleepPlan plan;
  const SleepPlanValid({required this.documentId, required this.plan});
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

class SleepPlanLegacy extends SleepPlanReadResult {
  @override
  final String documentId;
  final SleepPlanPartial partial;
  @override
  final List<FieldIssue> issues;
  const SleepPlanLegacy({
    required this.documentId,
    required this.partial,
    required this.issues,
  });
  @override
  ReadQuality get quality => ReadQuality.legacy;
  @override
  bool get isValid => false;
  @override
  bool get isLegacy => true;
  @override
  bool get isInvalid => false;
}

class SleepPlanInvalid extends SleepPlanReadResult {
  @override
  final String documentId;
  final SleepPlanPartial partial;
  @override
  final List<FieldIssue> issues;
  const SleepPlanInvalid({
    required this.documentId,
    required this.partial,
    required this.issues,
  });
  @override
  ReadQuality get quality => ReadQuality.invalid;
  @override
  bool get isValid => false;
  @override
  bool get isLegacy => false;
  @override
  bool get isInvalid => true;
}

class SleepPlanReadBatch {
  final List<SleepPlanReadResult> results;
  const SleepPlanReadBatch(this.results);

  int get validCount => results.where((r) => r.isValid).length;
  int get legacyCount => results.where((r) => r.isLegacy).length;
  int get invalidCount => results.where((r) => r.isInvalid).length;

  /// Records that can be shown in history UI (valid and safely displayable legacy).
  List<SleepPlanReadResult> get displayable =>
      results.where((r) => r.isValid || r.isLegacy).toList();
}
