import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Factory constructor for creating an SQIRecord from Firestore data
  factory SQIRecord.fromFirestore(Map<String, dynamic> data, String documentId) {
    return SQIRecord(
      recordId: documentId,
      userId: data['userId'] ?? '',
      sqiScore: data['sqiScore'] ?? 0,
      sleepQualityLevel: data['sleepQualityLevel'] ?? 'Fair',
      questionnaireResponses: Map<String, dynamic>.from(data['questionnaireResponses'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Method to convert SQIRecord to a Map for Firestore
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