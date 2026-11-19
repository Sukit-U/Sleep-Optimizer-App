import '../../../../core/services/storage_service.dart';
import '../../../../models/sleep_plan_model.dart';
import '../../../../services/firestore_service.dart';

abstract class SleepPlanRepository {
  Future<String> addSleepPlan(SleepPlan sleepPlan);
  Future<List<SleepPlan>> getSleepPlans(String userId);
}

class FirestoreSleepPlanRepository implements SleepPlanRepository {
  FirestoreSleepPlanRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  @override
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    return await _firestoreService.addSleepPlan(sleepPlan);
  }

  @override
  Future<List<SleepPlan>> getSleepPlans(String userId) async {
    final batch = await _firestoreService.getSleepPlans(userId);
    return batch.results
        .whereType<SleepPlanValid>()
        .map((r) => r.plan)
        .toList();
  }
}

/// Local implementation of [SleepPlanRepository] for offline mode.
///
/// Uses [StorageService] to persist sleep plans locally.
class LocalSleepPlanRepository implements SleepPlanRepository {
  LocalSleepPlanRepository(this._storage);

  final StorageService _storage;

  @override
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    final planData = {
      ...sleepPlan.toFirestore(),
      'planId': sleepPlan.planId.isEmpty
          ? 'local-${DateTime.now().millisecondsSinceEpoch}'
          : sleepPlan.planId,
      'createdAt': sleepPlan.createdAt.toIso8601String(),
      'wakeUpTime': sleepPlan.wakeUpTime.toIso8601String(),
    };
    await _storage.saveLocalSleepPlan(planData);
    return planData['planId'] as String;
  }

  @override
  Future<List<SleepPlan>> getSleepPlans(String userId) async {
    final localPlans = _storage.loadLocalSleepPlans();
    return localPlans
        .where((plan) => plan['userId'] == userId)
        .map(
          (plan) => SleepPlan(
            planId: plan['planId'] as String,
            userId: plan['userId'] as String,
            wakeUpTime: DateTime.parse(plan['wakeUpTime'] as String),
            createdAt: DateTime.parse(plan['createdAt'] as String),
            sleepCycles: plan['sleepCycles'] as int,
            suggestedBedtimes: List<String>.from(
              plan['suggestedBedtimes'] as List,
            ),
          ),
        )
        .toList();
  }
}
