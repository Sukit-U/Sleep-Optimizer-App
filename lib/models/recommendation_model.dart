import 'package:cloud_firestore/cloud_firestore.dart';

import 'read/firestore_read.dart';

/// Priority levels for generated recommendations.
enum RecommendationPriority { critical, high, medium, low }

/// Current-contract, fully valid recommendation (safe for writes and full display).
class Recommendation {
  final String recommendationId;

  /// Owner of the parent SQIRecord (Firebase Auth uid). Empty means the object
  /// has not been persisted yet; Firestore rules require a matching owner.
  final String userId;
  final String recordId; // Foreign key to SQIRecord
  final String factor;
  final String title;
  final String description;
  final String action;
  final String priority;
  final DateTime createdAt;

  Recommendation({
    required this.recommendationId,
    this.userId = '',
    required this.recordId,
    required this.factor,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'recordId': recordId,
      'factor': factor,
      'title': title,
      'description': description,
      'action': action,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copies this recommendation, keeping every field that is not passed.
  ///
  /// [createdAt] defaults to the existing value and must never fall back to
  /// `DateTime.now()`: `createdAt` is immutable in the Firestore rules, so a
  /// copy built for a retry has to carry the original timestamp or the retried
  /// write is rejected as an update of an immutable field.
  Recommendation copyWith({
    String? recommendationId,
    String? userId,
    String? recordId,
    String? factor,
    String? title,
    String? description,
    String? action,
    String? priority,
    DateTime? createdAt,
  }) {
    return Recommendation(
      recommendationId: recommendationId ?? this.recommendationId,
      userId: userId ?? this.userId,
      recordId: recordId ?? this.recordId,
      factor: factor ?? this.factor,
      title: title ?? this.title,
      description: description ?? this.description,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

const _recommendationPriorities = <String>{'critical', 'high', 'medium', 'low'};

/// Verified, safely displayable subset of a recommendation. Fields are null
/// only when that specific value could not be validated; no values are invented.
class RecommendationPartial {
  final String recommendationId;
  final String? userId;
  final String? recordId;
  final String? factor;
  final String? title;
  final String? description;
  final String? action;
  final String? priority;
  final DateTime? createdAt;

  const RecommendationPartial({
    required this.recommendationId,
    this.userId,
    this.recordId,
    this.factor,
    this.title,
    this.description,
    this.action,
    this.priority,
    this.createdAt,
  });

  bool get canDisplayRecommendation =>
      userId != null &&
      recordId != null &&
      createdAt != null &&
      title != null &&
      title!.trim().isNotEmpty;
}

sealed class RecommendationReadResult implements DocumentReadResult {
  const RecommendationReadResult();

  static RecommendationReadResult parse(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final issues = FieldIssues();

    // recommendationId (document id) is always preserved; validate it is non-empty.
    String? recommendationId;
    if (documentId.isEmpty) {
      issues.add(
        'recommendationId',
        FieldIssueKind.missing,
        expected: 'non-empty String',
      );
    } else {
      recommendationId = documentId;
    }

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
          issues.add(
            'userId',
            FieldIssueKind.outOfRange,
            expected: 'non-empty String',
            actual: raw,
          );
          userId = null;
        }
      } else {
        issues.add(
          'userId',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: raw,
        );
      }
    }

    // recordId
    String? recordId;
    if (!data.containsKey('recordId')) {
      issues.add('recordId', FieldIssueKind.missing, expected: 'String');
    } else {
      final raw = data['recordId'];
      if (raw == null) {
        issues.add('recordId', FieldIssueKind.nullValue, expected: 'String');
      } else if (raw is String) {
        recordId = raw;
        if (raw.isEmpty) {
          issues.add(
            'recordId',
            FieldIssueKind.outOfRange,
            expected: 'non-empty String',
            actual: raw,
          );
          recordId = null;
        }
      } else {
        issues.add(
          'recordId',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: raw,
        );
      }
    }

    // factor
    String? factor;
    if (!data.containsKey('factor')) {
      issues.add('factor', FieldIssueKind.missing, expected: 'String');
    } else {
      final raw = data['factor'];
      if (raw == null) {
        issues.add('factor', FieldIssueKind.nullValue, expected: 'String');
      } else if (raw is String) {
        factor = raw.trim().isEmpty ? null : raw;
        if (factor == null) {
          issues.add(
            'factor',
            FieldIssueKind.outOfRange,
            expected: 'non-empty String',
            actual: raw,
          );
        }
      } else {
        issues.add(
          'factor',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: raw,
        );
      }
    }

    // title
    String? title;
    if (!data.containsKey('title')) {
      issues.add('title', FieldIssueKind.missing, expected: 'String');
    } else {
      final raw = data['title'];
      if (raw == null) {
        issues.add('title', FieldIssueKind.nullValue, expected: 'String');
      } else if (raw is String) {
        title = raw.trim().isEmpty ? null : raw;
        if (title == null) {
          issues.add(
            'title',
            FieldIssueKind.outOfRange,
            expected: 'non-empty String',
            actual: raw,
          );
        }
      } else {
        issues.add(
          'title',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: raw,
        );
      }
    }

    // description
    String? description;
    if (!data.containsKey('description')) {
      issues.add('description', FieldIssueKind.missing, expected: 'String');
    } else {
      final raw = data['description'];
      if (raw == null) {
        issues.add('description', FieldIssueKind.nullValue, expected: 'String');
      } else if (raw is String) {
        description = raw.trim().isEmpty ? null : raw;
      } else {
        issues.add(
          'description',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: raw,
        );
      }
    }

    // action
    String? action;
    if (!data.containsKey('action')) {
      issues.add('action', FieldIssueKind.missing, expected: 'String');
    } else {
      final raw = data['action'];
      if (raw == null) {
        issues.add('action', FieldIssueKind.nullValue, expected: 'String');
      } else if (raw is String) {
        action = raw.trim().isEmpty ? null : raw;
      } else {
        issues.add(
          'action',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: raw,
        );
      }
    }

    // priority
    String? priority;
    if (!data.containsKey('priority')) {
      issues.add(
        'priority',
        FieldIssueKind.missing,
        expected: 'one of critical/high/medium/low',
      );
    } else {
      final raw = data['priority'];
      if (raw == null) {
        issues.add(
          'priority',
          FieldIssueKind.nullValue,
          expected: 'one of critical/high/medium/low',
        );
      } else if (raw is String) {
        if (_recommendationPriorities.contains(raw)) {
          priority = raw;
        } else {
          issues.add(
            'priority',
            FieldIssueKind.unknownValue,
            expected: 'one of critical/high/medium/low',
            actual: raw,
          );
        }
      } else {
        issues.add(
          'priority',
          FieldIssueKind.wrongType,
          expected: 'String',
          actual: raw,
        );
      }
    }

    // createdAt (never fabricate)
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

    final partial = RecommendationPartial(
      recommendationId: recommendationId ?? documentId,
      userId: userId,
      recordId: recordId,
      factor: factor,
      title: title,
      description: description,
      action: action,
      priority: priority,
      createdAt: createdAt,
    );

    if (!issues.hasIssues &&
        userId != null &&
        recordId != null &&
        factor != null &&
        title != null &&
        description != null &&
        action != null &&
        priority != null &&
        createdAt != null) {
      return RecommendationValid(
        documentId: documentId,
        record: Recommendation(
          recommendationId: documentId,
          userId: userId,
          recordId: recordId,
          factor: factor,
          title: title,
          description: description,
          action: action,
          priority: priority,
          createdAt: createdAt,
        ),
      );
    }

    if (partial.canDisplayRecommendation) {
      return RecommendationLegacy(
        documentId: documentId,
        partial: partial,
        issues: issues.items,
      );
    }

    return RecommendationInvalid(
      documentId: documentId,
      partial: partial,
      issues: issues.items.isEmpty
          ? [
              const FieldIssue(
                field: 'document',
                kind: FieldIssueKind.missing,
                expected: 'displayable recommendation fields',
              ),
            ]
          : issues.items,
    );
  }
}

class RecommendationValid extends RecommendationReadResult {
  @override
  final String documentId;
  final Recommendation record;
  const RecommendationValid({required this.documentId, required this.record});
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

class RecommendationLegacy extends RecommendationReadResult {
  @override
  final String documentId;
  final RecommendationPartial partial;
  @override
  final List<FieldIssue> issues;
  const RecommendationLegacy({
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

class RecommendationInvalid extends RecommendationReadResult {
  @override
  final String documentId;
  final RecommendationPartial partial;
  @override
  final List<FieldIssue> issues;
  const RecommendationInvalid({
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

class RecommendationReadBatch {
  final List<RecommendationReadResult> results;
  const RecommendationReadBatch(this.results);

  int get validCount => results.where((r) => r.isValid).length;
  int get legacyCount => results.where((r) => r.isLegacy).length;
  int get invalidCount => results.where((r) => r.isInvalid).length;

  List<RecommendationReadResult> get displayable =>
      results.where((r) => r.isValid || r.isLegacy).toList();
}
