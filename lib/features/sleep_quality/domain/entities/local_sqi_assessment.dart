/// Synchronization state of a locally stored SQI assessment.
enum LocalSqiSyncStatus { pending, synced, failed }

/// A durable, local-first record of one SQI assessment and its calculated
/// result. Stored independently of Firebase so it survives restarts and cloud
/// failures.
class LocalSqiAssessment {
  const LocalSqiAssessment({
    required this.assessmentId,
    this.schemaVersion = 1,
    required this.createdAt,
    this.userId,
    required this.responses,
    required this.score,
    required this.level,
    required this.factorScores,
    required this.weakFactors,
    this.syncStatus = LocalSqiSyncStatus.pending,
    this.cloudRecordId,
    this.lastSyncAttempt,
    this.lastSyncError,
  });

  final String assessmentId;
  final int schemaVersion;
  final DateTime createdAt;
  final String? userId;
  final Map<String, int> responses;
  final int score;
  final String level;
  final Map<String, int> factorScores;
  final List<String> weakFactors;
  final LocalSqiSyncStatus syncStatus;
  final String? cloudRecordId;
  final DateTime? lastSyncAttempt;
  final String? lastSyncError;

  LocalSqiAssessment copyWith({
    String? assessmentId,
    int? schemaVersion,
    DateTime? createdAt,
    String? userId,
    bool clearUserId = false,
    Map<String, int>? responses,
    int? score,
    String? level,
    Map<String, int>? factorScores,
    List<String>? weakFactors,
    LocalSqiSyncStatus? syncStatus,
    String? cloudRecordId,
    bool clearCloudRecordId = false,
    DateTime? lastSyncAttempt,
    bool clearLastSyncAttempt = false,
    String? lastSyncError,
    bool clearLastSyncError = false,
  }) {
    return LocalSqiAssessment(
      assessmentId: assessmentId ?? this.assessmentId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      userId: clearUserId ? null : (userId ?? this.userId),
      responses: responses ?? this.responses,
      score: score ?? this.score,
      level: level ?? this.level,
      factorScores: factorScores ?? this.factorScores,
      weakFactors: weakFactors ?? this.weakFactors,
      syncStatus: syncStatus ?? this.syncStatus,
      cloudRecordId: clearCloudRecordId
          ? null
          : (cloudRecordId ?? this.cloudRecordId),
      lastSyncAttempt: clearLastSyncAttempt
          ? null
          : (lastSyncAttempt ?? this.lastSyncAttempt),
      lastSyncError: clearLastSyncError
          ? null
          : (lastSyncError ?? this.lastSyncError),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'assessmentId': assessmentId,
      'schemaVersion': schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'responses': responses,
      'score': score,
      'level': level,
      'factorScores': factorScores,
      'weakFactors': weakFactors,
      'syncStatus': syncStatus.name,
      'cloudRecordId': cloudRecordId,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'lastSyncError': lastSyncError,
    };
  }

  static LocalSqiAssessment? tryParse(Map<String, dynamic> json) {
    try {
      final assessmentId = json['assessmentId'];
      if (assessmentId is! String || assessmentId.isEmpty) return null;

      final createdAtRaw = json['createdAt'];
      if (createdAtRaw is! String) return null;
      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) return null;

      final responsesRaw = json['responses'];
      if (responsesRaw is! Map) return null;
      final responses = <String, int>{};
      for (final e in responsesRaw.entries) {
        if (e.key is! String) return null;
        if (e.value is! int) return null;
        responses[e.key as String] = e.value as int;
      }

      final score = json['score'];
      if (score is! int) return null;

      final level = json['level'];
      if (level is! String || level.isEmpty) return null;

      final factorScoresRaw = json['factorScores'];
      if (factorScoresRaw is! Map) return null;
      final factorScores = <String, int>{};
      for (final e in factorScoresRaw.entries) {
        if (e.key is! String) return null;
        if (e.value is! int) return null;
        factorScores[e.key as String] = e.value as int;
      }

      final weakFactorsRaw = json['weakFactors'];
      if (weakFactorsRaw is! List) return null;
      final weakFactors = <String>[];
      for (final v in weakFactorsRaw) {
        if (v is! String) return null;
        weakFactors.add(v);
      }

      final syncStatusRaw = json['syncStatus'];
      final syncStatus = LocalSqiSyncStatus.values.firstWhere(
        (s) => s.name == syncStatusRaw,
        orElse: () => LocalSqiSyncStatus.pending,
      );

      final lastSyncAttemptRaw = json['lastSyncAttempt'];
      DateTime? lastSyncAttempt;
      if (lastSyncAttemptRaw is String) {
        lastSyncAttempt = DateTime.tryParse(lastSyncAttemptRaw);
      }

      final schemaVersion = json['schemaVersion'];
      final cloudRecordId = json['cloudRecordId'];
      final lastSyncError = json['lastSyncError'];
      final userId = json['userId'];

      return LocalSqiAssessment(
        assessmentId: assessmentId,
        schemaVersion: schemaVersion is int ? schemaVersion : 1,
        createdAt: createdAt,
        userId: userId is String ? userId : null,
        responses: responses,
        score: score,
        level: level,
        factorScores: factorScores,
        weakFactors: weakFactors,
        syncStatus: syncStatus,
        cloudRecordId: cloudRecordId is String ? cloudRecordId : null,
        lastSyncAttempt: lastSyncAttempt,
        lastSyncError: lastSyncError is String ? lastSyncError : null,
      );
    } catch (_) {
      return null;
    }
  }

  static LocalSqiAssessment? fromJson(Map<String, dynamic> json) =>
      tryParse(json);
}
