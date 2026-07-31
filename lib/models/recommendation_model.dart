import 'package:cloud_firestore/cloud_firestore.dart';

class Recommendation {
  final String recommendationId;
  final String recordId; // Foreign key to SQIRecord
  final String factor;
  final String title;
  final String description;
  final String action;
  final String priority;
  final DateTime createdAt;

  Recommendation({
    required this.recommendationId,
    required this.recordId,
    required this.factor,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'createdAt': Timestamp.fromDate(createdAt),
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
