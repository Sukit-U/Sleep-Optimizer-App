import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/app/app.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/core/services/storage_service.dart';
import 'package:snoozemate/features/sleep_planner/presentation/pages/sleep_planner_page.dart';
import 'package:snoozemate/models/sleep_plan_model.dart';
import 'package:snoozemate/services/firestore_service.dart';
import 'package:snoozemate/shared/widgets/bedtime_option_card.dart';

/// Reports "no user" without touching Firebase, so the offline path runs fast
/// (no sign-in retry delays).
class _OfflineAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  String? get uid => null;

  @override
  void resolveAuth() {}

  @override
  Future<String?> ensureSignedIn({int maxAttempts = 3}) async => null;

  @override
  Future<User> signInAnonymously() async =>
      throw UnimplementedError('offline test never signs in');
}

/// Fails the test if any cloud write is attempted.
class _ForbiddenFirestoreService extends FirestoreService {
  int addSleepPlanCalls = 0;

  @override
  Future<String> addSleepPlan(SleepPlan sleepPlan) async {
    addSleepPlanCalls++;
    throw StateError('cloud must not be used while offline');
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpPlanner(
    WidgetTester tester, {
    required AuthService auth,
    required FirestoreService firestore,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: auth,
        child: MaterialApp(home: SleepPlannerPage(firestoreService: firestore)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseWakeUpTime(WidgetTester tester) async {
    final timeLabel = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .firstWhere(
          (data) => data != null && RegExp(r'^\d{2}:\d{2}$').hasMatch(data),
        )!;
    await tester.tap(find.text(timeLabel), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('calculates bedtimes with no Firebase and no signed-in user', (
    tester,
  ) async {
    final firestore = _ForbiddenFirestoreService();

    await pumpPlanner(
      tester,
      auth: _OfflineAuthService(),
      firestore: firestore,
    );

    // 6/5/4-cycle options render from local logic alone.
    expect(find.byType(BedtimeOptionCard), findsNWidgets(3));
    expect(firestore.addSleepPlanCalls, 0);
  });

  testWidgets(
    'an offline save is kept on-device and never reported as cloud-saved',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.create();
      appStorage = storage;

      final firestore = _ForbiddenFirestoreService();

      await pumpPlanner(
        tester,
        auth: _OfflineAuthService(),
        firestore: firestore,
      );
      await chooseWakeUpTime(tester);

      await tester.tap(find.text('Save plan'), warnIfMissed: false);
      await tester.pump();
      await tester.pumpAndSettle();

      // Cloud is never touched while offline.
      expect(firestore.addSleepPlanCalls, 0);
      // The plan is persisted on-device instead of being lost.
      expect(storage.loadLocalSleepPlans(), hasLength(1));
      // The user is told it is device-only, and the button does not claim a
      // cloud/history save.
      expect(find.textContaining('Saved on this device only'), findsOneWidget);
      expect(find.text('Saved to history'), findsNothing);

      // Let the snackbar auto-dismiss timer finish.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );
}
