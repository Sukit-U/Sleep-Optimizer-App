# iOS TestFlight Beta Distribution Runbook

This runbook covers how iOS TestFlight beta builds of **Snoozemate** are configured, signed, versioned, and uploaded to App Store Connect, what the repository itself guarantees, and which external credentials and portal steps an owner must complete.

---

## 1. Environment & Bundle Identifier Policy (`sleep-optimizer-dev`)

### Why TestFlight Beta Targets `sleep-optimizer-dev` (`APP_ENV=dev`)

All iOS TestFlight beta builds target the **`dev` Firebase project (`sleep-optimizer-dev`, project number `564363714331`)** by compiling with `--dart-define=APP_ENV=dev`:

- **Production data safety:** The production Firebase project (`sleep-optimizer-59c83`) is currently on the Spark plan with Point-in-Time Recovery disabled (`POINT_IN_TIME_RECOVERY_DISABLED`) and no automated backups (`docs/INCIDENT_sleepplans-delete.md`, `docs/ENVIRONMENTS.md`). Routing beta testers to `sleep-optimizer-dev` guarantees that beta testing traffic never touches unbacked-up production data.
- **Compile-time selection:** Passing `--dart-define=APP_ENV=dev` selects `lib/firebase_options_dev.dart` (`1:564363714331:ios:e2ce6881627757da3f7dbe`).
- **Two-layer archive guard:**
  1. **Xcode build phase (`ios/scripts/verify_app_env.sh`):** Fails any `Release` or `Profile` archive in Xcode before Dart compilation if `DART_DEFINES` does not explicitly contain `APP_ENV=dev` or `APP_ENV=prod`.
  2. **Runtime launch guard (`rejectImplicitEnvOnIos` in `lib/app/firebase_environment.dart`):** Throws a `StateError` on startup if an iOS release/profile binary was somehow built without an explicit `--dart-define=APP_ENV`.

### Single Bundle ID Trade-Off (`com.snoozefriend.snoozemate`)

Unlike Android (which uses `--flavor dev` with `applicationIdSuffix = ".dev"` so dev and prod install side-by-side), iOS uses a **single bundle identifier (`com.snoozefriend.snoozemate`)** across `Debug`, `Profile`, and `Release` (`ios/Runner.xcodeproj/project.pbxproj`) and in both `sleep-optimizer-dev` and `sleep-optimizer-59c83`:

- **Implication for testers:** A TestFlight beta build (`APP_ENV=dev`) and a future App Store production build (`APP_ENV=prod`) cannot coexist on the same physical iOS device. Installing the App Store production build over a TestFlight beta build overwrites the app binary in-place and shares the device's local `SharedPreferences` / Keychain container for `com.snoozefriend.snoozemate` while switching the remote Firebase backend from `sleep-optimizer-dev` to `sleep-optimizer-59c83`.
- **Recommendation for testers:** Testers should uninstall the TestFlight beta build before installing a production App Store release so local cached preferences start clean.

---

## 2. App Check & App Attest Entitlement (`ios/Runner/Runner.entitlements`)

In `lib/app/app_check.dart`, any iOS build other than a `dev` debug build registers `AppleAppAttestWithDeviceCheckFallbackProvider()`:

| Build Mode | `--dart-define=APP_ENV` | iOS App Check Provider |
|---|---|---|
| Debug (`kDebugMode == true`) | `dev` | `AppleDebugProvider` |
| Release / Profile (`flutter build ipa --release`) | `dev` (TestFlight Beta) | `AppleAppAttestWithDeviceCheckFallbackProvider` |
| Debug / Profile / Release | `prod` (App Store) | `AppleAppAttestWithDeviceCheckFallbackProvider` |

### What Is Configured in the Repository

- `ios/Runner/Runner.entitlements` is committed with:
  ```xml
  <key>com.apple.developer.devicecheck.appattest-environment</key>
  <string>production</string>
  ```
- `ios/Runner.xcodeproj/project.pbxproj` wires `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` across all three `Runner` target configurations (`Debug`, `Release`, `Profile`).
- Why `production` in `Runner.entitlements`? Apple's App Attest service uses the `production` environment for builds signed with an App Store distribution provisioning profile (which covers both **TestFlight** and **App Store** distributions). In `Debug` builds (`APP_ENV=dev`), `lib/app/app_check.dart` selects `AppleDebugProvider`, which does not invoke `DCAppAttestService`.
- Runtime behavior (verified against `FirebaseAppCheckPlugin.swift`): `FirebaseAppCheck.instance.activate()` configures `AppCheckProviderWrapper` at boot; when Firestore or Auth requests a token on an iOS 14+ physical device (`DCAppAttestService.shared.isSupported == true`), `DCAppAttestService` requires the `com.apple.developer.devicecheck.appattest-environment` entitlement in the signed binary and provisioning profile, plus App Attest registration in the Firebase Console.

---

## 3. External Setup Checklist (Required Before First TestFlight Build)

None of the credentials or portal settings below live in the repository. Never commit certificates (`.p12`, `.cer`), provisioning profiles (`.mobileprovision`), or App Store Connect API keys (`.p8`).

| # | Requirement | Where to Configure | Details |
|---|---|---|---|
| 1 | **Apple Developer Team ID (`DEVELOPMENT_TEAM`)** | Apple Developer Portal / Codemagic | 10-character Apple Team ID. Used by `xcode-project use-profiles` in Codemagic and recorded in Firebase Console for App Attest. |
| 2 | **App Attest Capability on App ID** | Apple Developer Portal → Certificates, Identifiers & Profiles → Identifiers → `com.snoozefriend.snoozemate` | Enable **App Attest** capability on the explicit App ID `com.snoozefriend.snoozemate` and save. |
| 3 | **Apple Distribution Certificate** | Codemagic → App settings → Code signing identities → iOS certificates | Upload or let Codemagic generate an **Apple Distribution** certificate (`.p12`) for your Team ID. |
| 4 | **App Store Provisioning Profile** | Codemagic → App settings → Code signing identities → iOS provisioning profiles (or automatic fetch via ASC integration) | Must be an **App Store** distribution profile for `com.snoozefriend.snoozemate` generated *after* enabling the App Attest capability on the App ID. |
| 5 | **App Store Connect API Key (`codemagic` integration)** | App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys, then Codemagic → Team/User settings → Integrations → App Store Connect | Create an API Key (`.p8`) with **App Manager** or **Developer** role. Save the **Issuer ID**, **Key ID**, and `.p8` file under the integration name `codemagic` (referenced by `integrations.app_store_connect: codemagic` in `codemagic.yaml`). |
| 6 | **App Record & 10-Digit `APP_STORE_APPLE_ID`** | App Store Connect → Apps → New App (`com.snoozefriend.snoozemate`), then Codemagic → Environment variables | Copy the 10-digit **Apple ID** from App Store Connect → General → App Information. Set `APP_STORE_APPLE_ID` in Codemagic environment variables (or in `codemagic.yaml`). |
| 7 | **Firebase Console App Check Registration (`sleep-optimizer-dev`)** | Firebase Console (`sleep-optimizer-dev`) → App Check → Apps → iOS (`com.snoozefriend.snoozemate`, `1:564363714331:ios:e2ce6881627757da3f7dbe`) | Register **App Attest** (and **DeviceCheck** fallback) with your 10-character Apple Team ID. Keep App Check enforcement **OFF** during initial beta verification until *Verified* request metrics are confirmed (`docs/APP_CHECK.md`). |

---

## 4. Versioning & Build Number Rules for App Store Connect

App Store Connect enforces two strict rules on uploaded IPAs:

1. **`CFBundleShortVersionString` (`--build-name`) must be strictly numeric `MAJOR.MINOR.PATCH`** (e.g. `1.0.0`). Pre-release suffixes such as `1.0.0-beta.1` are rejected by App Store Connect validation.
2. **`CFBundleVersion` (`--build-number`) must increase monotonically** for every upload. Reusing `1` from `pubspec.yaml` (`version: 1.0.0+1`) will fail on the second upload with a duplicate build number error.

### How `codemagic.yaml` (`ios-workflow`) Handles Versioning

When triggered by a git tag matching `v*` (for example `v1.0.0-beta.1` or `v1.0.0`):

1. **`BUILD_NAME`:** Strips the leading `v` and any `-beta.*` suffix from `CM_TAG` (so `v1.0.0-beta.1` becomes `1.0.0`) and validates that it matches `^[0-9]+\.[0-9]+\.[0-9]+$`.
2. **`BUILD_NUM`:**
   - Starts with Codemagic's monotonically increasing `$BUILD_NUMBER`.
   - When `APP_STORE_APPLE_ID` is configured, queries `app-store-connect get-latest-testflight-build-number "$APP_STORE_APPLE_ID"` and uses `max($BUILD_NUMBER, LATEST_TESTFLIGHT + 1)`.
3. **Build command:**
   ```bash
   flutter build ipa --release \
     --dart-define=APP_ENV=$APP_ENV \
     --build-name="$BUILD_NAME" \
     --build-number="$BUILD_NUM" \
     --export-options-plist=/Users/builder/export_options.plist
   ```

---

## 5. Building & Uploading to TestFlight

### Option A: Automated Codemagic Tag Build (Recommended)

1. Complete the **External Setup Checklist** in Section 3.
2. Push a beta tag from a clean commit on the release branch (human step — agents never push or tag):
   ```bash
   git tag -a v1.0.0-beta.1 -m "iOS TestFlight beta 1 (sleep-optimizer-dev)"
   git push origin v1.0.0-beta.1
   ```
3. Codemagic triggers `ios-workflow`:
   - Applies App Store provisioning profiles via `xcode-project use-profiles`.
   - Runs `flutter pub get`, `pod install`, `flutter analyze`, and `flutter test`.
   - Derives `BUILD_NAME=1.0.0` and monotonic `BUILD_NUM`.
   - Builds the signed `.ipa` with `--dart-define=APP_ENV=dev` (verified by the `Verify APP_ENV` Xcode phase).
   - Uploads the `.ipa` to App Store Connect TestFlight (`submit_to_testflight: true`, `submit_to_app_store: false`).
4. In **App Store Connect → TestFlight**, wait for build processing to complete, complete the Export Compliance questionnaire (standard HTTPS/TLS only), and add internal/external beta tester groups.

### Option B: Manual Local Xcode Archive on macOS

If archiving manually on a macOS workstation with Xcode:

1. Run Flutter's config generation with explicit `APP_ENV=dev`, numeric `--build-name`, and incremented `--build-number`:
   ```bash
   flutter pub get
   flutter build ios --config-only --release \
     --dart-define=APP_ENV=dev \
     --build-name=1.0.0 \
     --build-number=2
   ```
2. Open `ios/Runner.xcworkspace` in Xcode.
3. In **Runner → Signing & Capabilities**:
   - Confirm **Automatically manage signing** (or select your App Store provisioning profile).
   - Select your Apple Developer **Team**.
   - Verify **Bundle Identifier** is `com.snoozefriend.snoozemate` and **App Attest** capability (`Runner/Runner.entitlements`) is present.
4. Select **Any iOS Device (arm64)** and choose **Product → Archive** (the `Verify APP_ENV` build phase will verify `DART_DEFINES` contains `APP_ENV=dev`).
5. In the Xcode Organizer, click **Distribute App → TestFlight & App Store → Upload**.

---

## 6. Switching from TestFlight Beta (`dev`) to App Store Production (`prod`)

Do **not** switch `ios-workflow` to `APP_ENV: "prod"` until:
1. `sleep-optimizer-59c83` is upgraded to the **Blaze** plan with **Point-in-Time Recovery (PITR)** and a **daily backup schedule** enabled (`docs/ENVIRONMENTS.md`).
2. `firestore.rules` and `firestore.indexes.json` are verified deployed on `sleep-optimizer-59c83`.
3. App Attest is registered for `com.snoozefriend.snoozemate` (`1:790423794853:ios:6d0bdd4fa56c8f5f1fc94c`) in the `sleep-optimizer-59c83` Firebase Console.

Once those human prerequisites are met, update `APP_ENV: "prod"` in `codemagic.yaml` for production release tags.

---

## 7. Current Verification Status & Known Limits

- **Repository config & static tests (`test/ios_release_config_test.dart`, `test/ios_testflight_config_test.dart`):** `PASS` (verified via `flutter test`).
- **Signed iOS `.ipa` build, signing, TestFlight upload, and physical iOS device install:** **`UNKNOWN` / `PENDING`**.
  - Local remediation was performed on Windows, where `xcodebuild`, CocoaPods, and `flutter build ipa` cannot run.
  - Live Codemagic signing identities, App Store Connect API Key integration, `APP_STORE_APPLE_ID`, and physical iOS hardware smoke testing (see `docs/testing/ios-testflight-smoke-checklist.md`) must be executed on macOS/Codemagic and a real iOS device before declaring iOS TestFlight distribution complete.
