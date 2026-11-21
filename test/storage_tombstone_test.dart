import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/core/services/storage_service.dart';

void main() {
  test('tombstone persists across StorageService reconstruction', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Instance 1
    final s1 = StorageService(prefs);
    await s1.saveLocalSleepPlan({
      'planId': 'plan-deleted',
      'userId': 'owner-1',
      'wakeUpTime': '2026-11-14T07:00:00.000',
      'createdAt': '2026-11-13T23:00:00.000',
      'sleepCycles': 5,
      'suggestedBedtimes': ['11:15 PM'],
      'syncStatus': 'synced',
    });
    await s1.saveLocalSleepPlan({
      'planId': 'plan-kept',
      'userId': 'owner-1',
      'wakeUpTime': '2026-11-15T07:00:00.000',
      'createdAt': '2026-11-14T23:00:00.000',
      'sleepCycles': 6,
      'suggestedBedtimes': ['10:15 PM'],
      'syncStatus': 'synced',
    });

    // Simulate deletion + tombstone creation.
    await s1.deleteLocalSleepPlan('plan-deleted');

    // Reconstruct a new StorageService using the same backing.
    final s2 = StorageService(prefs);

    // Tombstone persisted.
    expect(s2.loadDeletedSleepPlanIds(), contains('plan-deleted'));

    // Tombstoned plan excluded.
    final plans = s2.loadLocalSleepPlans();
    expect(plans.where((p) => p['planId'] == 'plan-deleted'), isEmpty);

    // Non-deleted plan remains.
    expect(plans.where((p) => p['planId'] == 'plan-kept'), hasLength(1));
  });
}
