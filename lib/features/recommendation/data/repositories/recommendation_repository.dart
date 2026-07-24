import '../../../../core/services/firebase_service.dart';

abstract class RecommendationRepository {
  Future<void> saveRecommendations(List<Map<String, dynamic>> payload);
}

class FirestoreRecommendationRepository implements RecommendationRepository {
  FirestoreRecommendationRepository({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  @override
  Future<void> saveRecommendations(List<Map<String, dynamic>> payload) {
    return Future.wait(
      payload.map((entry) => _firebaseService.saveSqiRecord(entry)),
    );
  }
}
