import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snoozemate/firebase_options.dart';

/// Firebase service façade for the Firestore-backed data model.
///
/// The current app still uses a lightweight local persistence layer so the
/// feature flow can remain testable without requiring Firebase configuration.
class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
    } on Exception {
      _initialized = false;
    }
  }

  // Read methods
  Future<Map<String, dynamic>?> getUser(String userId) async {
    await initialize();
    if (!_initialized) {
      return null;
    }
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<Map<String, dynamic>>> getSleepPlans(String userId) async {
    await initialize();
    if (!_initialized) {
      return [];
    }
    final snapshot = await _firestore.collection('sleepPlans').where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getSqiRecords(String userId) async {
    await initialize();
    if (!_initialized) {
      return [];
    }
    final snapshot = await _firestore.collection('sqiRecords').where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getRecommendations(String recordId) async {
    await initialize();
    if (!_initialized) {
      return [];
    }
    final snapshot = await _firestore.collection('recommendations').where('recordId', isEqualTo: recordId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, dynamic>?> getSettings(String userId) async {
    await initialize();
    if (!_initialized) {
      return null;
    }
    final doc = await _firestore.collection('settings').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  // Save methods
  Future<void> saveSleepPlan(Map<String, dynamic> payload) async {
    await initialize();
    if (!_initialized) {
      return;
    }

    await _firestore.collection('sleepPlans').add(payload);
  }

  Future<void> saveSqiRecord(Map<String, dynamic> payload) async {
    await initialize();
    if (!_initialized) {
      return;
    }

    await _firestore.collection('sqiRecords').add(payload);
  }

  Future<void> saveSettings(Map<String, dynamic> payload) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    String userId = payload['userId'];
    await _firestore.collection('settings').doc(userId).set(payload);
  }

  Future<void> saveUser(Map<String, dynamic> payload) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    String userId = payload['userId'];
    await _firestore.collection('users').doc(userId).set(payload);
  }

  Future<void> saveRecommendation(Map<String, dynamic> payload) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await _firestore.collection('recommendations').add(payload);
  }
}
