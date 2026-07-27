/// Model for SQI records
class SQIRecord {
  final String recordId;
  final String userId;
  final int sqiScore;
  final String sleepQualityLevel;
  final Map<String, dynamic> questionnaireResponses;
  final DateTime createdAt;

  const SQIRecord({
    required this.recordId,
    required this.userId,
    required this.sqiScore,
    required this.sleepQualityLevel,
    required this.questionnaireResponses,
    required this.createdAt,
  });

  SQIRecord copyWith({
    String? recordId,
    String? userId,
    int? sqiScore,
    String? sleepQualityLevel,
    Map<String, dynamic>? questionnaireResponses,
    DateTime? createdAt,
  }) {
    return SQIRecord(
      recordId: recordId ?? this.recordId,
      userId: userId ?? this.userId,
      sqiScore: sqiScore ?? this.sqiScore,
      sleepQualityLevel: sleepQualityLevel ?? this.sleepQualityLevel,
      questionnaireResponses: questionnaireResponses ?? this.questionnaireResponses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Model for recommendations
class Recommendation {
  final String recommendationId;
  final String recordId;
  final String factor;
  final String title;
  final String description;
  final String action;
  final String priority;

  const Recommendation({
    required this.recommendationId,
    required this.recordId,
    required this.factor,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
  });

  Recommendation copyWith({
    String? recommendationId,
    String? recordId,
    String? factor,
    String? title,
    String? description,
    String? action,
    String? priority,
  }) {
    return Recommendation(
      recommendationId: recommendationId ?? this.recommendationId,
      recordId: recordId ?? this.recordId,
      factor: factor ?? this.factor,
      title: title ?? this.title,
      description: description ?? this.description,
      action: action ?? this.action,
      priority: priority ?? this.priority,
    );
  }
}