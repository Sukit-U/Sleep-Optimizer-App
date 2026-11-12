import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sleep_plan_model.dart';
import '../models/sqi_record_model.dart';
import '../models/recommendation_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SleepPlan operations
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    final docRef = await _firestore
        .collection('sleepPlans')
        .add(sleepPlan.toFirestore());
    return docRef.id;
  }

  Future<List<SleepPlan>> getSleepPlans(String userId) async {
    final snapshot = await _firestore
        .collection('sleepPlans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SleepPlan.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // SQIRecord operations
  Future<String> addSQIRecord(SQIRecord sqiRecord) async {
    final docRef = await _firestore
        .collection('sqiRecords')
        .add(sqiRecord.toFirestore());
    return docRef.id;
  }

  Future<List<SQIRecord>> getSQIRecords(String userId) async {
    final snapshot = await _firestore
        .collection('sqiRecords')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SQIRecord.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Recommendation operations
  Future<String> addRecommendation(Recommendation recommendation) async {
    // Recommendations inherit the owner of their parent SQI record. Writing
    // without it would be rejected by the rules after the SQI record has
    // already been saved, so fail fast here instead.
    if (recommendation.userId.isEmpty) {
      throw ArgumentError('Recommendation.userId is required');
    }
    final docRef = await _firestore
        .collection('recommendations')
        .add(recommendation.toFirestore());
    return docRef.id;
  }

  // Firestore rules do not filter query results: the query itself must be
  // scoped to the owner, or the whole request is rejected.
  Future<List<Recommendation>> getRecommendations(
    String recordId,
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('recommendations')
        .where('userId', isEqualTo: userId)
        .where('recordId', isEqualTo: recordId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Recommendation.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> deleteSleepPlan(String planId) async {
    await _firestore.collection('sleepPlans').doc(planId).delete();
  }

  /// Deletes an SQI record together with every recommendation that belongs to
  /// it, in a single atomic batch.
  ///
  /// The rules allow a recommendation delete only while its parent SQI record
  /// still exists (`firestore.rules`, recommendations delete). Deleting the
  /// parent on its own therefore orphans its recommendations permanently: the
  /// client can no longer delete them, because the delete rule's parent
  /// ownership lookup fails, and nothing in the app ever revisits them again.
  /// Children and parent
  /// must travel together, and the batch keeps them consistent — if it fails,
  /// nothing is removed.
  ///
  /// The query is owner- and record-scoped on purpose: rules are not filters,
  /// so an unfiltered recommendation query is rejected outright.
  Future<void> deleteSqiRecordWithRecommendations({
    required String recordId,
    required String userId,
  }) async {
    final recommendations = await _firestore
        .collection('recommendations')
        .where('userId', isEqualTo: userId)
        .where('recordId', isEqualTo: recordId)
        .get();

    final batch = _firestore.batch();
    for (final doc in recommendations.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('sqiRecords').doc(recordId));
    await batch.commit();
  }

  // Settings operations
  Future<void> saveSettings(Map<String, dynamic> payload) async {
    await _firestore
        .collection('settings')
        .doc(payload['userId'] as String)
        .set(payload);
  }

  Future<Map<String, dynamic>?> getSettings(String userId) async {
    final doc = await _firestore.collection('settings').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }
}
