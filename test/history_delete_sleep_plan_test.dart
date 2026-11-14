import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/core/services/auth_service.dart';
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
  Future<List<SleepPlan>> getSleepPlans(String userId) async {
    loadCount++;
    return [_plan];
  }

  @override
  Future<List<SQIRecord>> getSQIRecords(String userId) async => const [];

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

Future<void> _pumpPlansTab(WidgetTester tester, FirestoreService service) async {
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

void main() {
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

  testWidgets('a failed delete shows friendly copy and no raw error',
      (tester) async {
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
}
