import '../../../../core/services/storage_service.dart';
import '../../../../models/sleep_plan_model.dart';
import '../../../../services/firestore_service.dart';

abstract class SleepPlanRepository {
  Future<String> addSleepPlan(SleepPlan sleepPlan);
  Future<List<SleepPlan>> getSleepPlans(String userId);
}

/// Extension to support local-first sync operations.
abstract class LocalSleepPlanRepository extends SleepPlanRepository {
  /// Updates the sync status of an existing local plan.
  Future<void> updateSyncStatus(
    String planId,
    LocalSleepPlanSyncStatus status, {
    String? cloudPlanId,
    String? error,
    DateTime? attemptTime,
  });

  /// Deletes a local plan by planId.
  Future<void> deleteLocalPlan(String planId);
}

class FirestoreSleepPlanRepository implements SleepPlanRepository {
  FirestoreSleepPlanRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  @override
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    return await _firestoreService.addSleepPlan(sleepPlan);
  }

  /// Idempotent save for retrying a plan with a known planId.
  Future<void> saveSleepPlan(SleepPlan sleepPlan) async {
    await _firestoreService.saveSleepPlan(sleepPlan);
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
/// Uses [StorageService] to persist sleep plans locally with sync status tracking.
class LocalSleepPlanRepositoryImpl implements LocalSleepPlanRepository {
  LocalSleepPlanRepositoryImpl(this._storage);

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
      'syncStatus':
          sleepPlan.syncStatus?.name ?? LocalSleepPlanSyncStatus.pending.name,
      if (sleepPlan.cloudPlanId != null) 'cloudPlanId': sleepPlan.cloudPlanId,
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
            syncStatus: plan['syncStatus'] != null
                ? LocalSleepPlanSyncStatus.values.firstWhere(
                    (s) => s.name == plan['syncStatus'],
                    orElse: () => LocalSleepPlanSyncStatus.pending,
                  )
                : null,
            cloudPlanId: plan['cloudPlanId'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<void> updateSyncStatus(
    String planId,
    LocalSleepPlanSyncStatus status, {
    String? cloudPlanId,
    String? error,
    DateTime? attemptTime,
  }) async {
    final existing = _storage.loadLocalSleepPlans();
    final idx = existing.indexWhere((e) => e['planId'] == planId);
    if (idx >= 0) {
      existing[idx] = {
        ...existing[idx],
        'syncStatus': status.name,
        if (cloudPlanId != null) 'cloudPlanId': cloudPlanId,
        if (error != null) 'lastSyncError': error,
        if (attemptTime != null)
          'lastSyncAttempt': attemptTime.toIso8601String(),
      };
      await _storage.saveLocalSleepPlan(existing[idx]);
    }
  }

  @override
  Future<void> deleteLocalPlan(String planId) async {
    await _storage.deleteLocalSleepPlan(planId);
  }
}
