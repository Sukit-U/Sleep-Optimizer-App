import '../../../../core/services/firebase_service.dart';

abstract class SettingsRepository {
  Future<void> saveSettings(Map<String, dynamic> payload);
}

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  @override
  Future<void> saveSettings(Map<String, dynamic> payload) {
    return _firebaseService.saveSettings(payload);
  }
}
