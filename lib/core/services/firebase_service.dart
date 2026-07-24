import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
      await Firebase.initializeApp();
      _initialized = true;
    } on Exception {
      _initialized = false;
    }
  }

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

    await _firestore.collection('settings').add(payload);
  }
}
