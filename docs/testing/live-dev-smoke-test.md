# Live Dev Smoke Test Runbook (Snoozemate)

This runbook documents how to run the **Live Dev** smoke test against the
`sleep-optimizer-dev` Firebase project from an Android emulator. It complements
(but does not replace) the emulator-based Firestore Rules suite in
`firestore-rules-test/`.

> **Safety boundary.** Dev (`sleep-optimizer-dev`) only. Production
> (`sleep-optimizer-59c83`) is never accessed, queried, deployed to, or modified.
> See `docs/ENVIRONMENTS.md`.

## 1. Prerequisites

- Flutter SDK on `PATH` (verified: `C:\Users\HP\flutter\bin`).
- Android SDK with platform-tools + an emulator image (verified: Android 15 /
  API 35, AVD `Medium_Phone`).
- Java 17+ for Gradle. If `JAVA_HOME` is unset, use the JDK bundled with
  Android Studio: `C:\Program Files\Android\Android Studio\jbr`.
- Firebase CLI logged in (`firebase login`) with access to `sleep-optimizer-dev`.
- Project dependencies installed (`flutter pub get`).
- No other integration-test process running on the emulator.

## 2. Start the emulator

```powershell
flutter emulators
flutter emulators --launch Medium_Phone
```

Wait for boot to complete (the emulator window shows the home screen).

## 3. Verify the device

```powershell
flutter devices
```

Expected: `emulator-5554` (sdk gphone64 x86_64, Android 15 / API 35).

If `adb` is not on `PATH`, locate it explicitly:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
Test-Path $adb
```

Then:

```powershell
& $adb -s emulator-5554 get-state
```

## 4. Verify the Dev app

Confirm the Dev package is installed (and that no Prod package is present):

```powershell
& $adb -s emulator-5554 shell pm list packages | Select-String "snoozefriend"
```

Expected: `package:com.snoozefriend.snoozemate.dev` only.

Launch the app:

```powershell
& $adb -s emulator-5554 shell monkey -p com.snoozefriend.snoozemate.dev -c android.intent.category.LAUNCHER 1
```

Verify it is resumed and inspect Firebase/App Check logs:

```powershell
& $adb -s emulator-5554 shell dumpsys activity activities | Select-String "topResumedActivity|com.snoozefriend.snoozemate.dev"
```

Do not rebuild or reinstall the APK unless evidence shows it is missing or invalid.
If reinstall is necessary, verify the existing APK hash against the Phase C
SHA-256 first: `3D1BB67343C2BFF0EC1A788E2F1EBCA940786ADE41AADFD32A32E20C86963658`.

## 5. Firebase Dev verification (read-only)

```powershell
firebase --project=sleep-optimizer-dev projects:list
```

Confirm `sleep-optimizer-dev` (project number `564363714331`) is present and that
`sleep-optimizer-59c83` is never selected. The Dev app config is committed:
`lib/firebase_options_dev.dart` (`projectId: sleep-optimizer-dev`,
`appId: 1:564363714331:android:de49274c28e969753f7dbe`).

## 6. Run tests

### 6.1 Unit tests (SQI / Sleep Plan / models)

```powershell
flutter test
```

Or a specific file:

```powershell
flutter test test/sqi_record_model_test.dart
flutter test test/sleep_plan_model_test.dart
```

### 6.2 Firestore Rules emulator tests (NOT Live Dev)

```powershell
cd firestore-rules-test
npm install
npm test
```

`npm test` starts the Firestore emulator, runs the suite, and shuts it down.
This suite runs against the **emulator only** and validates `../firestore.rules`.
It is not a substitute for Live Dev verification.

Expected: `64 passed, 0 failed` (as of the Phase D run).

### 6.3 Live Dev smoke test (temporary harness)

The Live Dev smoke test is run through a **temporary** integration-test harness
that is created for the run and removed afterwards. It is not committed.

Steps:

1. Add the SDK dependency temporarily to `pubspec.yaml` (dev_dependencies):

   ```yaml
   dev_dependencies:
     integration_test:
       sdk: flutter
   ```

   Then `flutter pub get`.

2. Create `integration_test/live_dev_smoke_test.dart` following the contract in
   `docs/ENVIRONMENTS.md` and the repository methods in
   `lib/services/firestore_service.dart`:
   - Initialize Firebase with `DefaultFirebaseOptions.currentPlatform` from
     `lib/firebase_options_dev.dart`.
   - Activate App Check with `env: 'dev'`.
   - Assert `projectId == 'sleep-optimizer-dev'` and the Dev `appId`.
   - Create a **dedicated** anonymous Auth session (never reuse the two
     pre-existing accounts `0Q2sNA7kkAdcAqAmv19GIAuIdYU2` /
     `5LRaJmyar8fa06948TD016EwXsE2`).
   - Record the new UID and confirm it differs from both forbidden UIDs.
   - SQI: `newSqiRecordId()` -> `saveSqiRecord()` -> `getSQIRecords()` (verify
     all 6 questionnaire keys) -> `deleteSqiRecordWithRecommendations()`.
   - Sleep Plan: `addSleepPlan()` -> `getSleepPlans()` -> `deleteSleepPlan()`.
     (No repository Update method exists; document this as
     `NOT_SUPPORTED_BY_REPOSITORY` and test Rules-level Update via the SDK.)
   - Invalid payloads (missing/extra/null/wrong-type/out-of-range SQI keys;
     wrong-type/empty/>10/empty-string/non-string/>100-char bedtimes) must be
     rejected with `permission-denied`. Valid payloads must be accepted.
   - Cleanup: delete only the created test documents, verify absence (a read on
     a deleted document may be denied by the rules - treat `permission-denied`
     as "absent"), verify via owner queries that no test IDs remain, then delete
     the dedicated Auth account (in a `finally` block so it always runs).

3. Run with Java 17 and the Gradle heap override (the project's daemon otherwise
   defaults to 8 GB and can OOM):

   ```powershell
   $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
   $env:GRADLE_OPTS = '-Dorg.gradle.jvmargs="-Xmx2g -XX:MaxMetaspaceSize=512m -XX:ReservedCodeCacheSize=256m -XX:+HeapDumpOnOutOfMemoryError"'
   flutter test integration_test/live_dev_smoke_test.dart -d emulator-5554 --flavor dev --dart-define=APP_ENV=dev
   ```

   Expected: `All tests passed!` and `LIVED_TEST|RESULT=ALL_ASSERTIONS_PASSED`.

4. Remove the temporary harness and restore `pubspec.yaml` / `pubspec.lock`:

   ```powershell
   Remove-Item -LiteralPath "integration_test\live_dev_smoke_test.dart" -Force
   git checkout -- pubspec.yaml pubspec.lock
   ```

   Confirm `git status` matches the pre-run baseline (no stray changes).

## 7. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `adb` not recognized | Use `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`. |
| `emulator-5554` not listed | Boot the AVD: `flutter emulators --launch Medium_Phone`. |
| Dev package missing | Install the Dev APK; verify SHA-256 `3D1BB673...` first. |
| Gradle "requires JVM 17" | Set `$env:JAVA_HOME` to the Android Studio JBR. |
| Gradle OOM | Set `$env:GRADLE_OPTS` with `-Xmx2g` (see 6.3). |
| `permission-denied` on valid write | App Check debug token not registered in the Firebase console, or rules mismatch. |
| Auth account not cleaned up | Ensure deletion runs in a `finally` block while still signed in. |
| Firestore read denied after delete | Expected - rules deny reads on non-existent documents. |

## 8. Safety checklist

- [ ] Dev project only (`sleep-optimizer-dev`); Production never touched.
- [ ] No Firestore Rules / config / index changes; no deployment.
- [ ] No Production source changes; no permanent test infrastructure left behind.
- [ ] Dedicated test UID used; the two pre-existing anonymous accounts untouched.
- [ ] Unique, controlled document IDs; all test documents deleted and verified.
- [ ] Temporary harness and `pubspec` changes reverted; working tree matches baseline.
- [ ] No stash / reset / checkout / clean / discard of unrelated files.

## 9. Expected outcomes

- **PASS** - every CRUD, invalid-payload, valid-payload, and cleanup assertion
  succeeded with evidence; Auth account deleted; working tree restored.
- **FAIL** - at least one assertion failed with evidence (report the failing
  case and stop; do not claim PASS).
- **BLOCKED** - a precondition was not met (device unavailable, UID not
  attributable, environment mismatch); no writes performed.
EOF