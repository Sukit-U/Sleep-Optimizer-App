import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snoozemate/app/app.dart';
import 'package:snoozemate/app/app_check.dart';
import 'package:snoozemate/app/bootstrap.dart';
import 'package:snoozemate/app/firebase_environment.dart';
import 'package:snoozemate/core/services/auth_service.dart';
import 'package:snoozemate/core/services/cloud_connection_service.dart';
import 'package:snoozemate/features/home/presentation/pages/home_page.dart';
import 'package:snoozemate/features/sleep_planner/presentation/pages/sleep_planner_page.dart';
import 'package:snoozemate/features/sleep_quality/presentation/pages/sleep_quality_page.dart';
import 'package:snoozemate/features/splash/presentation/pages/splash_page.dart';
import 'package:snoozemate/shared/widgets/bedtime_option_card.dart';

/// Deterministic offline fake for [AuthService] so the smoke test exercises
/// the full app bootstrap, navigation, Sleep Planner, SQI calculation, and
/// local-first persistence without contacting a live Firebase project.
class _FakeBetaAuthService implements AuthService {
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
      throw UnimplementedError('deterministic smoke test does not sign in');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Beta Distribution Deterministic Smoke Suite', () {
    test('beta environment & App Check provider invariants hold for dev', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final androidDev = firebaseOptionsForEnv('dev');
      expect(androidDev.projectId, 'sleep-optimizer-dev');
      expect(androidDev.appId, '1:564363714331:android:de49274c28e969753f7dbe');

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final iosDev = firebaseOptionsForEnv('dev');
      expect(iosDev.projectId, 'sleep-optimizer-dev');
      expect(iosDev.appId, '1:564363714331:ios:e2ce6881627757da3f7dbe');
      expect(iosDev.iosBundleId, 'com.snoozefriend.snoozemate');
      debugDefaultTargetPlatformOverride = null;

      final betaReleaseProviders = appCheckProvidersFor(
        env: 'dev',
        isDebugBuild: false,
      );
      expect(betaReleaseProviders.usesDebugProvider, isFalse);
      expect(betaReleaseProviders.android, isA<AndroidPlayIntegrityProvider>());
      expect(
        betaReleaseProviders.apple,
        isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
      );
    });

    testWidgets(
      'end-to-end journey: AppBootstrap -> Splash -> Home -> Sleep Planner -> SQI offline persistence',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final fakeAuth = _FakeBetaAuthService();

        await tester.pumpWidget(
          AppBootstrap(
            boot: () => bootDependencies(
              createAuthService: () => fakeAuth,
              createCloudConnectionService: (auth) => CloudConnectionService(
                authService: auth,
                getEnv: () => 'dev',
                isDebugBuild: () => false,
                firebaseInit: () async {},
                appCheck: () async {},
                firestoreEmulator: () async {},
                authEmulator: () async {},
                authentication: () async {},
              ),
              initializeCloud: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Splash screen renders first and navigates to Home on Continue.
        expect(find.byType(SplashPage), findsOneWidget);
        expect(find.text('เริ่มต้นกันเลย'), findsOneWidget);

        await tester.tap(find.text('เริ่มต้นกันเลย'));
        await tester.pumpAndSettle();

        // 2. Home screen renders with planner and SQI entry points.
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.text('หน้าหลัก'), findsWidgets);

        // 3. Navigate to Sleep Planner and verify 6/5/4-cycle bedtime cards.
        await tester.tap(find.text('เปิดตัวช่วยจัดเวลานอน'));
        await tester.pumpAndSettle();

        expect(find.byType(SleepPlannerPage), findsOneWidget);
        expect(find.byType(BedtimeOptionCard), findsNWidgets(3));

        // Return to Home via BackButton.
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);

        // 4. Navigate to Sleep Quality (SQI) assessment and complete all 6 items.
        await tester.tap(find.text('เริ่มทำแบบประเมิน'));
        await tester.pumpAndSettle();

        expect(find.byType(SleepQualityPage), findsOneWidget);

        for (var i = 0; i < 6; i++) {
          await tester.tap(find.text('3').at(i));
          await tester.pump();
        }

        await tester.tap(find.text('คำนวณคะแนน SQI'));
        await tester.pumpAndSettle();

        // Offline fallback dialog confirms local calculation & persistence.
        expect(find.text('คำนวณแบบออฟไลน์'), findsOneWidget);
        expect(find.textContaining('60'), findsWidgets);
        expect(appStorage, isNotNull);
        expect(appStorage!.loadLocalSqiAssessments(), hasLength(1));

        // View full recommendation breakdown locally.
        await tester.tap(find.text('ดูผลลัพธ์'));
        await tester.pumpAndSettle();
        expect(find.text('60'), findsOneWidget);
      },
    );
  });
}
