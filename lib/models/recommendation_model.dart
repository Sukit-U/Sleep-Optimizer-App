class Recommendation {
  final String recommendationId;
  final String recordId; // Foreign key to SQIRecord
  final String factor;
  final String title;
  final String description;
  final String action;
  final String priority;

  Recommendation({
    required this.recommendationId,
    required this.recordId,
    required this.factor,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
  });

  // Factory constructor for creating a Recommendation from Firestore data
  factory Recommendation.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Recommendation(
      recommendationId: documentId,
      recordId: data['recordId'] ?? '',
      factor: data['factor'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      action: data['action'] ?? '',
      priority: data['priority'] ?? 'Low',
    );
  }

  // Method to convert Recommendation to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'recordId': recordId,
      'factor': factor,
      'title': title,
      'description': description,
      'action': action,
      'priority': priority,
    };
  }

  // Copy with method to create a new instance with updated values
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
