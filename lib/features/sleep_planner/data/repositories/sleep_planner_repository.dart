import '../../../../core/services/firebase_service.dart';

abstract class SleepPlannerRepository {
  Future<void> savePlan(Map<String, dynamic> payload);
}

class FirestoreSleepPlannerRepository implements SleepPlannerRepository {
  FirestoreSleepPlannerRepository({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  @override
  Future<void> savePlan(Map<String, dynamic> payload) {
    return _firebaseService.saveSleepPlan(payload);
  }
}
