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
    final snapshot = await _firestore.collection('sleepPlans').where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => SleepPlan.fromFirestore(doc.data(), doc.id)).toList();
  }

  // SQIRecord operations
  Future<String> addSQIRecord(SQIRecord sqiRecord) async {
    final docRef = await _firestore.collection('sqiRecords').add(sqiRecord.toFirestore());
    return docRef.id;
  }

  Future<List<SQIRecord>> getSQIRecords(String userId) async {
    final snapshot = await _firestore.collection('sqiRecords').where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => SQIRecord.fromFirestore(doc.data(), doc.id)).toList();
  }

  // Recommendation operations
  Future<String> addRecommendation(Recommendation recommendation) async {
    final docRef = await _firestore.collection('recommendations').add(recommendation.toFirestore());
    return docRef.id;
  }

  Future<List<Recommendation>> getRecommendations(String recordId) async {
    final snapshot = await _firestore.collection('recommendations').where('recordId', isEqualTo: recordId).get();
    return snapshot.docs.map((doc) => Recommendation.fromFirestore(doc.data(), doc.id)).toList();
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