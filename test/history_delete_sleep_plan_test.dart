import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/app/app.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/core/services/storage_service.dart';
import 'package:snoozemate/features/history/presentation/pages/history_page.dart';
import 'package:snoozemate/features/history/presentation/widgets/delete_sleep_plan_dialog.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';
import 'package:snoozemate/services/firestore_service.dart';

final _plan = SleepPlan(
  planId: 'plan-1',
  userId: 'owner-1',
  wakeUpTime: DateTime(2026, 11, 14, 7, 0),
  createdAt: DateTime(2026, 11, 13, 23, 0),
  sleepCycles: 5,
  suggestedBedtimes: const ['11:15 PM', '12:45 AM', '2:15 AM'],
);

/// `implements` means the real constructors never run, so the fakes need no
/// booted Firebase app.
class _SignedInAuth implements AuthService {
  @override
  String? get uid => 'owner-1';

  @override
  void resolveAuth() {}

  @override
  Future<String?> ensureSignedIn({int maxAttempts = 3}) async => 'owner-1';

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Counts delete calls and list loads. With [failDelete] the delete throws an
/// exception whose text must never reach the UI.
class _PlanService implements FirestoreService {
  _PlanService({this.failDelete = false});

  final bool failDelete;
  int deleteCalls = 0;
  int loadCount = 0;

  @override
  Future<SleepPlanReadBatch> getSleepPlans(String userId) async {
    loadCount++;
    return SleepPlanReadBatch([
      SleepPlanValid(documentId: _plan.planId, plan: _plan),
    ]);
  }

  @override
  Future<SQIRecordReadBatch> getSQIRecords(String userId) async =>
      const SQIRecordReadBatch([]);

  @override
  Future<void> deleteSleepPlan(String planId) async {
    deleteCalls++;
    if (failDelete) {
      throw Exception('permission-denied: projects/sleep-optimizer-59c83');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Cloud service that removes the plan after a successful delete.
class _TrackingPlanService implements FirestoreService {
  _TrackingPlanService();

  int deleteCalls = 0;
  int loadCount = 0;
  bool _deleted = false;

  @override
  Future<SleepPlanReadBatch> getSleepPlans(String userId) async {
    loadCount++;
    if (_deleted) return const SleepPlanReadBatch([]);
    return SleepPlanReadBatch([
      SleepPlanValid(documentId: _plan.planId, plan: _plan),
    ]);
  }

  @override
  Future<SQIRecordReadBatch> getSQIRecords(String userId) async =>
      const SQIRecordReadBatch([]);

  @override
  Future<void> deleteSleepPlan(String planId) async {
    deleteCalls++;
    _deleted = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

final _plan2 = SleepPlan(
  planId: 'plan-2',
  userId: 'owner-1',
  wakeUpTime: DateTime(2026, 11, 15, 7, 0),
  createdAt: DateTime(2026, 11, 14, 23, 0),
  sleepCycles: 6,
  suggestedBedtimes: const ['10:15 PM', '11:45 PM', '1:15 AM'],
);

/// Cloud service returning two plans; deletion removes one.
class _TwoPlanService implements FirestoreService {
  _TwoPlanService();

  int deleteCalls = 0;
  int loadCount = 0;
  final Set<String> _deleted = {};

  @override
  Future<SleepPlanReadBatch> getSleepPlans(String userId) async {
    loadCount++;
    final plans = [_plan, _plan2]
        .where((p) => !_deleted.contains(p.planId))
        .map((p) => SleepPlanValid(documentId: p.planId, plan: p))
        .toList();
    return SleepPlanReadBatch(plans);
  }

  @override
  Future<SQIRecordReadBatch> getSQIRecords(String userId) async =>
      const SQIRecordReadBatch([]);

  @override
  Future<void> deleteSleepPlan(String planId) async {
    deleteCalls++;
    _deleted.add(planId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Cloud service that returns no plans (for local-only tests).
class _EmptyCloudService implements FirestoreService {
  @override
  Future<SleepPlanReadBatch> getSleepPlans(String userId) async =>
      const SleepPlanReadBatch([]);

  @override
  Future<SQIRecordReadBatch> getSQIRecords(String userId) async =>
      const SQIRecordReadBatch([]);

  @override
  Future<void> deleteSleepPlan(String planId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// Stub storage that throws on local delete.
class _FailingDeleteStorage extends StorageService {
  _FailingDeleteStorage(super.prefs);

  @override
  Future<void> deleteLocalSleepPlan(String planId) async {
    throw Exception('disk error');
  }
}

Future<void> _pumpPlansTab(
  WidgetTester tester,
  FirestoreService service,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Provider<AuthService>.value(
        value: _SignedInAuth(),
        child: HistoryPage(firestoreService: service),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Sleep plans'));
  await tester.pumpAndSettle();
}

Future<void> _seedLocalPlan() async {
  final storage = appStorage!;
  await storage.saveLocalSleepPlan({
    'planId': _plan.planId,
    'userId': _plan.userId,
    'wakeUpTime': _plan.wakeUpTime.toIso8601String(),
    'createdAt': _plan.createdAt.toIso8601String(),
    'sleepCycles': _plan.sleepCycles,
    'suggestedBedtimes': _plan.suggestedBedtimes,
    'syncStatus': 'synced',
  });
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    appStorage = storage;
  });

  testWidgets('cancelling the dialog never deletes the plan', (tester) async {
    final service = _PlanService();
    await _pumpPlansTab(tester, service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this plan?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 0, reason: 'a cancelled delete must not run');
    expect(find.text('Delete this plan?'), findsNothing);
  });

  testWidgets('confirming deletes once and reloads the list', (tester) async {
    final service = _PlanService();
    await _pumpPlansTab(tester, service);
    final loadsAfterFirstOpen = service.loadCount;

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(
      service.loadCount,
      loadsAfterFirstOpen + 1,
      reason: 'the list must be re-read after a successful delete',
    );
  });

  testWidgets('a failed delete shows friendly copy and no raw error', (
    tester,
  ) async {
    final service = _PlanService(failDelete: true);
    await _pumpPlansTab(tester, service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(find.text(sleepPlanDeleteUnconfirmedMessage), findsOneWidget);
    expect(
      find.textContaining('permission-denied'),
      findsNothing,
      reason: 'the exception text must stay out of the UI',
    );

    // The action re-reads the list instead of retrying the delete.
    final loadsBeforeRefresh = service.loadCount;
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(service.loadCount, loadsBeforeRefresh + 1);
    expect(service.deleteCalls, 1);
  });

  testWidgets('delete a synced plan removes it from History', (tester) async {
    final service = _TrackingPlanService();
    await _pumpPlansTab(tester, service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('History recreation after deletion keeps deleted plan absent', (
    tester,
  ) async {
    final service = _TwoPlanService();
    await _pumpPlansTab(tester, service);

    // Both plans rendered initially.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

    // Delete plan-1.
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Dispose the original History page by replacing the widget tree.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    // Reconstruct a fresh History page.
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AuthService>.value(
          value: _SignedInAuth(),
          child: HistoryPage(firestoreService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sleep plans'));
    await tester.pumpAndSettle();

    // Deleted plan absent, unaffected plan present.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('cloud deletion failure keeps plan available', (tester) async {
    final service = _PlanService(failDelete: true);
    await _pumpPlansTab(tester, service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(find.text(sleepPlanDeleteUnconfirmedMessage), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('cloud delete succeeds but local delete fails: no resurrection', (
    tester,
  ) async {
    await _seedLocalPlan();

    final prefs = await SharedPreferences.getInstance();
    appStorage = _FailingDeleteStorage(prefs);

    final service = _TrackingPlanService();
    await _pumpPlansTab(tester, service);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('local-only deletion still works', (tester) async {
    await _seedLocalPlan();

    final service = _EmptyCloudService();
    await _pumpPlansTab(tester, service);

    // The seeded local plan must be rendered before deletion.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Removed from UI.
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    // Removed from persistent local storage.
    final storage = appStorage!;
    final remaining = storage.loadLocalSleepPlans();
    expect(remaining.where((p) => p['planId'] == _plan.planId), isEmpty);
  });
}
