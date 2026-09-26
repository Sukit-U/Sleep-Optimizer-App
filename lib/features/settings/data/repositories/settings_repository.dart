import '../../../../core/services/storage_service.dart';
import '../../../../services/firestore_service.dart';

abstract class SettingsRepository {
  Future<void> saveSettings(Map<String, dynamic> payload);
  Future<Map<String, dynamic>?> loadSettings(String userId);
}

class FirestoreSettingsRepository {
  FirestoreSettingsRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  Future<void> saveSettings(Map<String, dynamic> payload) async {
    try {
      // Try Firestore first
      await _firestoreService.saveSettings(payload);
      // If successful, also save to local storage for offline use
      final storage = await StorageService.create();
      await storage.saveTheme(payload['theme'] as String);
    } catch (e) {
      // Fall back to local storage if Firestore fails
      final storage = await StorageService.create();
      await storage.saveTheme(payload['theme'] as String);
      throw Exception('Failed to save settings to Firestore, saved locally: $e');
    }
  }

  Future<Map<String, dynamic>?> loadSettings(String userId) async {
    try {
      // Try Firestore first
      final firestoreSettings = await _firestoreService.getSettings(userId);
      if (firestoreSettings != null) {
        return firestoreSettings;
      }
    } catch (e) {
      // If Firestore fails, fall back to local storage
      final storage = await StorageService.create();
      final localTheme = storage.loadTheme();
      if (localTheme != null) {
        return {'userId': userId, 'theme': localTheme};
      }
      throw Exception('Failed to load settings from both Firestore and local storage: $e');
    }
    return null;
  }
}
