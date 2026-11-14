import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/features/sleep_planner/presentation/pages/sleep_planner_page.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';
import 'package:snoozemate/services/firestore_service.dart';
import 'package:snoozemate/shared/widgets/planner_save_button.dart';

/// Signs in only when the test releases the gate, so the sign-in await stays
/// open long enough for a second tap to land.
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signInGate});

  final Completer<String?>? signInGate;

  @override
  User? get currentUser => null;

  @override
  String? get uid => 'test-uid';

  @override
  Future<String?> ensureSignedIn({int maxAttempts = 3}) async =>
      signInGate?.future ?? Future<String?>.value('test-uid');

  @override
  Future<User> signInAnonymously() async =>
      throw UnimplementedError('the test never signs in');
}

/// Keeps the write pending until the test releases it, and counts every attempt
/// so a duplicate save would be visible.
class _GatedFirestoreService extends FirestoreService {
  final gate = Completer<void>();
  int addSleepPlanCalls = 0;

  @override
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    addSleepPlanCalls++;
    await gate.future;
    return 'plan-1';
  }
}

class _FailingFirestoreService extends FirestoreService {
  int addSleepPlanCalls = 0;

  @override
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    addSleepPlanCalls++;
    throw Exception('offline');
  }
}

void main() {
  setUpAll(() {
    // No font downloads in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpPlanner(
    WidgetTester tester,
    AuthService authService,
    FirestoreService firestoreService,
  ) async {
    // Tall enough that the save button is laid out without scrolling.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: authService,
        child: MaterialApp(
          home: SleepPlannerPage(firestoreService: firestoreService),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A save needs a chosen wake-up time, which the page starts without.
  Future<void> chooseWakeUpTime(WidgetTester tester) async {
    final timeLabel = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .firstWhere(
          (data) =>
              data != null && RegExp(r'^\d{2}:\d{2} [AP]M$').hasMatch(data),
        )!;
    await tester.tap(find.text(timeLabel), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('repeated taps during sign-in and during the write save once',
      (tester) async {
    final signInGate = Completer<String?>();
    final firestoreService = _GatedFirestoreService();
    await pumpPlanner(
      tester,
      _FakeAuthService(signInGate: signInGate),
      firestoreService,
    );
    await chooseWakeUpTime(tester);

    await tester.tap(find.text('Save plan'), warnIfMissed: false);
    await tester.pump();

    // Still signing in, and the button must already be closed.
    expect(find.text('Saving…'), findsOneWidget);
    expect(
      tester.widget<PlannerSaveButton>(find.byType(PlannerSaveButton)).onPressed,
      isNull,
      reason: 'the button must close before the first await returns',
    );

    await tester.tap(find.byType(PlannerSaveButton), warnIfMissed: false);
    await tester.pump();

    signInGate.complete('test-uid');
    await tester.pump();
    await tester.pump();
    expect(firestoreService.addSleepPlanCalls, 1);

    // The second tap of a fast double tap, now inside the write.
    await tester.tap(find.byType(PlannerSaveButton), warnIfMissed: false);
    await tester.pump();
    expect(
      firestoreService.addSleepPlanCalls,
      1,
      reason: 'a tap during the write must not start a second save',
    );

    firestoreService.gate.complete();
    await tester.pumpAndSettle();

    expect(firestoreService.addSleepPlanCalls, 1);
    expect(find.text('Saved to history'), findsOneWidget);

    // Let the "Saved" label timer finish so no timer outlives the test.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('a failed save re-enables the button', (tester) async {
    final firestoreService = _FailingFirestoreService();
    await pumpPlanner(tester, _FakeAuthService(), firestoreService);
    await chooseWakeUpTime(tester);

    await tester.tap(find.text('Save plan'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(firestoreService.addSleepPlanCalls, 1);
    expect(
      find.text('Could not save plan. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Saving…'), findsNothing);
    expect(
      tester.widget<PlannerSaveButton>(find.byType(PlannerSaveButton)).onPressed,
      isNotNull,
      reason: 'a failed save must leave the button usable',
    );

    await tester.tap(find.text('Save plan'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(firestoreService.addSleepPlanCalls, 2);
  });
}
