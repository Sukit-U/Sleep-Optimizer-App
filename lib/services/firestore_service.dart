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

  /// Allocates a document ID without writing anything, so a submission that is
  /// retried can reuse the same record instead of creating a second one.
  String newSqiRecordId() => _firestore.collection('sqiRecords').doc().id;

  /// Creates or overwrites the record with its already-allocated ID.
  ///
  /// `set()` on a fixed ID makes the write idempotent. Retrying with the same
  /// payload (same `createdAt`) is accepted by the rules as an update, because
  /// none of the immutable fields change.
  Future<void> saveSqiRecord(SQIRecord record) async {
    if (record.recordId.isEmpty) {
      throw ArgumentError('SQIRecord.recordId is required');
    }
    await _firestore
        .collection('sqiRecords')
        .doc(record.recordId)
        .set(record.toFirestore());
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

  /// Writes every recommendation of one assessment in a single batch, keyed by
  /// their own document IDs.
  ///
  /// Fixed IDs are what make a retry safe: re-sending the same list overwrites
  /// the same documents instead of appending duplicates. The parent record must
  /// already exist (the rules check `exists()` on create), which is why this is
  /// a separate step from [saveSqiRecord] rather than one combined batch.
  Future<void> saveRecommendations(List<Recommendation> recommendations) async {
    if (recommendations.isEmpty) return;

    final batch = _firestore.batch();
    for (final recommendation in recommendations) {
      if (recommendation.recommendationId.isEmpty) {
        throw ArgumentError('Recommendation.recommendationId is required');
      }
      if (recommendation.userId.isEmpty) {
        throw ArgumentError('Recommendation.userId is required');
      }
      batch.set(
        _firestore
            .collection('recommendations')
            .doc(recommendation.recommendationId),
        recommendation.toFirestore(),
      );
    }
    await batch.commit();
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
