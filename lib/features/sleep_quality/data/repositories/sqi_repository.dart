import '../../../../core/services/firebase_service.dart';

abstract class SqiRepository {
  Future<void> saveRecord(Map<String, dynamic> payload);
}

class FirestoreSqiRepository implements SqiRepository {
  FirestoreSqiRepository({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  @override
  Future<void> saveRecord(Map<String, dynamic> payload) {
    return _firebaseService.saveSqiRecord(payload);
  }
}
