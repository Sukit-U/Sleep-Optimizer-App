# iOS TestFlight Beta Smoke-Test Checklist (`Snoozemate`)

> **Verification Status**
> - **Automated Unit/Widget/Integration Suite:** `PASS` (`flutter test` + `integration_test/beta_smoke_test.dart`)
> - **iOS Archive Guard & Config Invariants:** Verified via `test/ios_release_config_test.dart` and `test/ios_testflight_config_test.dart`
> - **macOS / Xcode Signed IPA Build:** `PENDING` (Windows host cannot run Xcode; built via Codemagic or macOS host)
> - **Real-Device Result:** **`PENDING (not executed on physical iOS hardware / TestFlight)`**

---

## 1. Scope, Environment & Single-Bundle-ID Notice

- **Target Artifact:** Signed iOS App Store / TestFlight Archive (`.ipa`) built with `--release --dart-define=APP_ENV=dev`
- **Bundle Identifier:** `com.snoozefriend.snoozemate`
- **Target Firebase Project:** `sleep-optimizer-dev` (project number `564363714331`, iOS app ID `1:564363714331:ios:e2ce6881627757da3f7dbe`)
- **Forbidden Project:** Production (`sleep-optimizer-59c83`) is strictly read-only and has no PITR or automated backups. TestFlight beta builds must **never** target `sleep-optimizer-59c83`.

> **Important Coexistence Trade-Off on iOS:**
> Unlike Android (which uses `.dev` applicationId suffix `com.snoozefriend.snoozemate.dev`), iOS shares a single Xcode bundle identifier (`com.snoozefriend.snoozemate`) across `APP_ENV=dev` and `APP_ENV=prod`. Installing a TestFlight beta build (`APP_ENV=dev`) and later installing an App Store production build (`APP_ENV=prod`) on the same iOS device will overwrite the app in-place and share local `NSUserDefaults` / Keychain state. Testers should uninstall the TestFlight beta build before switching to a production App Store build.

---

## 2. Pre-Submission Build & Entitlement Checklist (Codemagic / Xcode)

Before inviting TestFlight testers, verify the following pre-flight checks on the archive/IPA:

### 2.1 Build Configuration & `APP_ENV` Guard
- [ ] `ios/scripts/verify_app_env.sh` passed during the Xcode `Verify APP_ENV` build phase with `APP_ENV=dev`.
- [ ] Build command used a strictly numeric `CFBundleShortVersionString` (`--build-name=1.0.0`, no `-beta` suffix in `--build-name`) and a unique, monotonically increasing integer `CFBundleVersion` (`--build-number=<N>`).

### 2.2 App Attest Entitlement & Provisioning Profile
- [ ] `ios/Runner/Runner.entitlements` is linked via `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` with:
  - `com.apple.developer.devicecheck.appattest-environment` = `production`
- [ ] Apple Developer Portal App ID (`com.snoozefriend.snoozemate`) has the **App Attest** capability enabled, and the App Store distribution provisioning profile was generated after enabling it.
- [ ] Firebase Console (`sleep-optimizer-dev`) has the Apple Team ID configured and App Attest registered under App Check for `com.snoozefriend.snoozemate`.

### 2.3 App Store Connect / TestFlight Processing
- [ ] IPA uploaded to App Store Connect via Codemagic (`submit_to_testflight: true`) or Xcode Organizer / Transporter.
- [ ] Build completes Apple processing in App Store Connect -> TestFlight without missing-entitlement or invalid-version warnings.
- [ ] Export compliance (`ITSAppUsesNonExemptEncryption`) answered/configured so the build is ready for internal/external TestFlight testers.

---

## 3. Physical iOS Device (TestFlight) Smoke-Test Checklist

Execute on a physical iPhone running iOS 15.0 or newer installed directly from the **Apple TestFlight** app:

### 3.1 Installation & Target Environment Verification
- [ ] Install `Snoozemate` from the TestFlight app on a physical iPhone.
- [ ] If connected to a Mac with Xcode -> **Window > Devices and Simulators > Open Console**, filter logs by `APP_ENV` or `sleep-optimizer` on first launch:
  - [ ] Confirm log output reports `APP_ENV=dev` and `projectId=sleep-optimizer-dev` (never `sleep-optimizer-59c83`).

### 3.2 Cold Boot & Visual Layout
- [ ] Launch from Home screen -> verify `LaunchScreen.storyboard` transitions cleanly into the Flutter Splash screen (`เริ่มต้นกันเลย`).
- [ ] Verify Thai typography (Kanit font) renders properly without clipped diacritics or missing characters.
- [ ] Verify safe-area insets around the top Dynamic Island / notch and the bottom home indicator on the floating pill navigation bar.

### 3.3 Anonymous Auth & App Check (App Attest / DeviceCheck Fallback)
- [ ] Tap **เริ่มต้นกันเลย** to enter the Home screen, then navigate to **ตั้งค่า** (`Settings`).
- [ ] Confirm **การซิงค์ข้อมูลคลาวด์** (`Cloud sync`) reaches `เชื่อมต่อแล้ว` (`Connected`).
- [ ] Verify that `AppleAppAttestWithDeviceCheckFallbackProvider` activates without error and mints an App Check token on physical hardware.

### 3.4 Sleep Planner Journey
- [ ] Navigate to **จัดเวลานอน** (`Sleep Planner`).
- [ ] Open the wake-up time picker, select a wake-up time, adjust the sleep-latency slider, and toggle activity constraint chips.
- [ ] Verify 6-cycle, 5-cycle (recommended), and 4-cycle bedtime cards render and can be selected.
- [ ] Tap **บันทึกแผน** (`Save plan`) -> verify cloud sync succeeds (`บันทึกในประวัติแล้ว`) and the plan appears in **ประวัติ** (`History` -> `แผนการนอน`).
- [ ] Delete the plan from History and confirm removal.

### 3.5 Sleep Quality Index (SQI) Journey
- [ ] Navigate to **คะแนน SQI** (`Sleep Quality`).
- [ ] Verify incomplete submission guard shows the validation prompt when fewer than 6 questions are answered.
- [ ] Complete all 6 questions and tap **คำนวณคะแนน SQI**.
- [ ] Verify the Recommendation page displays the calculated score (`/ 100`), quality level badge, factor breakdown, and recommendations.
- [ ] Verify the record appears under **ประวัติ** (`History` -> `ประวัติ SQI`), opens its recommendation bottom sheet, and can be deleted cleanly.

### 3.6 Offline Mode & Recovery
- [ ] Enable Airplane Mode on the iPhone and force-restart the app.
- [ ] Confirm the app boots into offline mode without crashing or blocking on a loading screen.
- [ ] Save a Sleep Plan and complete an SQI assessment while offline -> verify local persistence (`บันทึกในเครื่องนี้เท่านั้น...` and `คำนวณแบบออฟไลน์`).
- [ ] Disable Airplane Mode and retry saving -> confirm cloud sync succeeds without duplicating records.

---

## 4. Execution Sign-Off Record

| Field | Value |
|---|---|
| **Platform** | iOS Physical Device (via Apple TestFlight) |
| **Bundle ID & Build** | `com.snoozefriend.snoozemate` (`APP_ENV=dev`) |
| **Target Firebase Project** | `sleep-optimizer-dev` |
| **TestFlight Build Version / Number** | `PENDING` |
| **iPhone Model & iOS Version** | `PENDING` |
| **Tester & Date** | `PENDING` |
| **Real-Device Result** | **`PENDING`** |
