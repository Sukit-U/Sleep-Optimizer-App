import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snoozemate/features/history/presentation/widgets/delete_sleep_plan_dialog.dart';

/// Runs the confirmation flow through a button, then stands in for the delete:
/// [deleted] counts the calls that would have reached Firestore.
Future<({bool? confirmed, int deleted})> _runFlow(
  WidgetTester tester,
  Future<void> Function() interactWithDialog,
) async {
  bool? confirmed;
  var deleted = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              confirmed = await confirmDeleteSleepPlan(context);
              if (confirmed == true) deleted++;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  await interactWithDialog();
  await tester.pumpAndSettle();

  return (confirmed: confirmed, deleted: deleted);
}

void main() {
  testWidgets('dialog asks about the plan and warns there is no undo',
      (tester) async {
    await _runFlow(tester, () async {
      expect(find.text('Delete this plan?'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  testWidgets('cancelling never deletes anything', (tester) async {
    final result = await _runFlow(tester, () async {
      await tester.tap(find.text('Cancel'));
    });

    expect(result.confirmed, isFalse);
    expect(result.deleted, 0, reason: 'a cancelled delete must not run');
  });

  testWidgets('dismissing the dialog counts as cancel', (tester) async {
    final result = await _runFlow(tester, () async {
      // Taps the barrier outside the dialog.
      await tester.tapAt(const Offset(5, 5));
    });

    expect(result.confirmed, isFalse);
    expect(result.deleted, 0);
  });

  testWidgets('confirming deletes exactly once', (tester) async {
    final result = await _runFlow(tester, () async {
      await tester.tap(find.text('Delete'));
    });

    expect(result.confirmed, isTrue);
    expect(result.deleted, 1);
  });

  test('failure copy does not promise an outcome it cannot verify', () {
    final copy = sleepPlanDeleteUnconfirmedMessage.toLowerCase();

    expect(sleepPlanDeleteUnconfirmedMessage, isNotEmpty);
    expect(copy, isNot(contains('nothing was removed')));
    expect(copy, isNot(contains('was deleted')));
    expect(copy, isNot(contains('successfully')));
    // It must point the user at the list instead of a blind retry.
    expect(copy, contains('refresh'));
  });
}
