import 'package:cloud_firestore/cloud_firestore.dart';

class SleepPlan {
  final String planId;
  final String userId;
  final DateTime wakeUpTime;
  final DateTime createdAt;
  final int sleepCycles;
  final List<String> suggestedBedtimes;

  SleepPlan({
    required this.planId,
    required this.userId,
    required this.wakeUpTime,
    required this.createdAt,
    required this.sleepCycles,
    required this.suggestedBedtimes,
  });

  // Factory constructor for creating a SleepPlan from Firestore data
  factory SleepPlan.fromFirestore(Map<String, dynamic> data, String documentId) {
    return SleepPlan(
      planId: documentId,
      userId: data['userId'] ?? '',
      wakeUpTime: (data['wakeUpTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      sleepCycles: data['sleepCycles'] ?? 0,
      suggestedBedtimes: List<String>.from(data['suggestedBedtimes'] ?? []),
    );
  }

  // Method to convert SleepPlan to a Map for Firestore
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