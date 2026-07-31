import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import '../models/user_model.dart';
import '../models/sleep_plan_model.dart';
import '../models/sqi_record_model.dart';
import '../models/recommendation_model.dart';
import '../models/settings_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> addUser(User user) async {
    await _firestore.collection('users').doc(user.userId).set(user.toFirestore());
  }

  Future<User> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromFirestore(doc.data()!);
    } else {
      throw Exception('User not found');
    }
  }

  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.userId).update(user.toFirestore());
  }

  // SleepPlan operations
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    final docRef = await _firestore.collection('sleepPlans').add(sleepPlan.toFirestore());
    return docRef.id;
  }

  Future<List<SleepPlan>> getSleepPlans(String userId) async {
    final snapshot = await _firestore
        .collection('sleepPlans')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['userId'] == userId)
        .map((doc) => SleepPlan.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // SQIRecord operations
  Future<String> addSQIRecord(SQIRecord sqiRecord) async {
    final docRef = await _firestore.collection('sqiRecords').add(sqiRecord.toFirestore());
    return docRef.id;
  }

  Future<List<SQIRecord>> getSQIRecords(String userId) async {
    final snapshot = await _firestore
        .collection('sqiRecords')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['userId'] == userId)
        .map((doc) => SQIRecord.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Recommendation operations
  Future<String> addRecommendation(Recommendation recommendation) async {
    final docRef = await _firestore.collection('recommendations').add(recommendation.toFirestore());
    return docRef.id;
  }

  Future<List<Recommendation>> getRecommendations(String recordId) async {
    final snapshot = await _firestore
        .collection('recommendations')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['recordId'] == recordId)
        .map((doc) => Recommendation.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> deleteSleepPlan(String planId) async {
    await _firestore.collection('sleepPlans').doc(planId).delete();
  }

  Future<void> deleteSQIRecord(String recordId) async {
    await _firestore.collection('sqiRecords').doc(recordId).delete();
  }

  // Settings operations
  Future<void> addSettings(Settings settings) async {
    await _firestore.collection('settings').doc(settings.userId).set(settings.toFirestore());
  }

  Future<Settings> getSettings(String userId) async {
    final doc = await _firestore.collection('settings').doc(userId).get();
    if (doc.exists) {
      return Settings.fromFirestore(doc.data()!);
    } else {
      throw Exception('Settings not found');
    }
  }

  Future<void> updateSettings(Settings settings) async {
    await _firestore.collection('settings').doc(settings.userId).update(settings.toFirestore());
  }
}