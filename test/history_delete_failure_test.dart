import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/features/history/presentation/pages/history_page.dart';
import 'package:snoozemate/features/history/presentation/widgets/delete_sqi_record_dialog.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';
import 'package:snoozemate/models/sqi_record_model.dart';
import 'package:snoozemate/services/firestore_service.dart';

final _record = SQIRecord(
  recordId: 'rec-1',
  userId: 'owner-1',
  sqiScore: 7,
  sleepQualityLevel: 'Fair',
  questionnaireResponses: const {},
  createdAt: DateTime(2026, 11, 1),
);

/// `implements` means the real constructors never run, so neither fake needs a
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

/// Every delete fails, so the page can only report an unconfirmed outcome.
/// Loads are counted to prove the Refresh action re-reads history.
class _FailingDeleteService implements FirestoreService {
  int loadCount = 0;
  int deleteCalls = 0;

  @override
  Future<List<SleepPlan>> getSleepPlans(String userId) async => const [];

  @override
  Future<List<SQIRecord>> getSQIRecords(String userId) async {
    loadCount++;
    return [_record];
  }

  @override
  Future<void> deleteSqiRecordWithRecommendations({
    required String recordId,
    required String userId,
  }) async {
    deleteCalls++;
    throw Exception('network unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

void main() {
  testWidgets('an unconfirmed delete says so and Refresh reloads history',
      (tester) async {
    final service = _FailingDeleteService();

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AuthService>.value(
          value: _SignedInAuth(),
          child: HistoryPage(firestoreService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(
      find.text(sqiDeleteUnconfirmedMessage),
      findsOneWidget,
      reason: 'the outcome is unknown: say so instead of claiming a failure',
    );

    // The SnackBar action re-reads the list rather than retrying the delete.
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(service.loadCount, 2);
    expect(service.deleteCalls, 1);
  });
}
