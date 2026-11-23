# Android Beta APK Smoke-Test Checklist (`Snoozemate`)

> **Verification Status**
> - **Automated Unit/Widget/Integration Suite:** `PASS` (`flutter test` + `integration_test/beta_smoke_test.dart`)
> - **Dev Debug APK Build (`--debug --flavor dev --dart-define=APP_ENV=dev`):** Verified in CI / local build gate
> - **Real-Device Result:** **`PENDING (not executed on physical Android hardware)`**

---

## 1. Scope & Safety Boundary

- **Target Artifact:** `app-dev-release.apk` (built with `--release --flavor dev --dart-define=APP_ENV=dev`)
- **Application ID:** `com.snoozefriend.snoozemate.dev` (coexists safely alongside any future production install `com.snoozefriend.snoozemate`)
- **Target Firebase Project:** `sleep-optimizer-dev` (project number `564363714331`, Android app ID `1:564363714331:android:de49274c28e969753f7dbe`)
- **Forbidden Project:** Production (`sleep-optimizer-59c83`) is strictly read-only and has no PITR or automated backups. Beta testers must **never** be routed to `sleep-optimizer-59c83`.

---

## 2. Pre-Distribution Artifact Verification (Before Sending to Testers)

Run these checks on the built `app-dev-release.apk` before sharing the APK with beta testers:

### 2.1 Build Command
```powershell
flutter build apk --release --flavor dev --dart-define=APP_ENV=dev --build-name=1.0.0-beta.1 --build-number=10000
```

### 2.2 Package Name & Version Badging (`aapt2`)
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\35.0.0\aapt2.exe" dump badging build\app\outputs\flutter-apk\app-dev-release.apk | Select-String "package:"
```
- [ ] `package: name='com.snoozefriend.snoozemate.dev'` (MUST end with `.dev`)
- [ ] `versionCode='10000'` (or expected monotonic build number)
- [ ] `versionName='1.0.0-beta.1'`

### 2.3 Signature Verification (`apksigner`)
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\35.0.0\apksigner.bat" verify --print-certs -v build\app\outputs\flutter-apk\app-dev-release.apk
```
- [ ] `Verified using v2 scheme (APK Signature Scheme v2): true`
- [ ] Signer certificate SHA-256 matches the registered upload keystore fingerprint (never `CN=Android Debug`).
- [ ] Upload keystore SHA-256 fingerprint is registered in Firebase Console (`sleep-optimizer-dev` -> Project settings -> Android app `com.snoozefriend.snoozemate.dev`) for Play Integrity / App Check.

### 2.4 SHA-256 Checksum Recording
```powershell
Get-FileHash build\app\outputs\flutter-apk\app-dev-release.apk -Algorithm SHA256
```
- [ ] Record the SHA-256 checksum in the beta release notes so testers can verify download integrity.

---

## 3. Physical Android Device Smoke-Test Checklist

Execute on a physical Android device (Android 8.0 / API 26 or newer; recommended Android 13–15):

### 3.1 Clean Installation & Environment Verification
- [ ] Install APK via ADB or direct download:
  ```powershell
  adb install -r build\app\outputs\flutter-apk\app-dev-release.apk
  ```
- [ ] Confirm package is installed under `.dev`:
  ```powershell
  adb shell pm list packages | Select-String "snoozefriend"
  ```
  Expected: `package:com.snoozefriend.snoozemate.dev`
- [ ] Launch the app and verify environment banner in `adb logcat`:
  ```powershell
  adb logcat -d | Select-String "APP_ENV=dev|sleep-optimizer-dev"
  ```
  Expected: log line confirming `APP_ENV=dev` and `projectId=sleep-optimizer-dev` (never `sleep-optimizer-59c83`).

### 3.2 Boot & Onboarding Journey
- [ ] Cold launch renders the Splash / Welcome screen without R8/ProGuard crashes or missing Kanit font glyphs.
- [ ] Tapping **เริ่มต้นกันเลย** (`Continue`) navigates smoothly to the Home screen (`หน้าหลัก`).
- [ ] Force-closing and reopening the app remembers local state cleanly.

### 3.3 Anonymous Authentication & Cloud Sync
- [ ] Open **ตั้งค่า** (`Settings`) from the floating bottom navigation bar.
- [ ] Check **การซิงค์ข้อมูลคลาวด์** (`Cloud sync`) status reaches `เชื่อมต่อแล้ว` (`Connected`).
- [ ] Verify in `adb logcat` that Firebase Anonymous Auth and App Check (`AndroidPlayIntegrityProvider`) complete without unhandled exceptions.

### 3.4 Sleep Planner Flow (Online & Offline)
- [ ] Navigate to **จัดเวลานอน** (`Sleep Planner`).
- [ ] Select a wake-up time, adjust sleep latency slider, toggle optional activity constraints, and verify 6-cycle, 5-cycle (recommended), and 4-cycle bedtime cards update immediately.
- [ ] Tap **บันทึกแผน** (`Save plan`) while online -> verify confirmation and verify the saved plan appears under **ประวัติ** (`History` -> `แผนการนอน`).
- [ ] Delete the saved sleep plan from History -> confirm deletion dialog removes it cleanly.

### 3.5 Sleep Quality Index (SQI) Flow & Recommendations
- [ ] Navigate to **คะแนน SQI** (`Sleep Quality`).
- [ ] Tap **คำนวณคะแนน SQI** with unanswered items -> verify validation snackbar (`กรุณาตอบคำถามประเมิน SQI ให้ครบทุกข้อก่อนกดส่ง`) highlights missing questions.
- [ ] Answer all 6 questions and tap **คำนวณคะแนน SQI** -> verify navigation to the Recommendation result screen with score (`/ 100`), factor breakdown, and prioritized recommendations.
- [ ] Open **ประวัติ** (`History` -> `ประวัติ SQI`) -> tap the saved record to inspect recommendations in the bottom sheet, then test deleting the record.

### 3.6 Offline Resilience
- [ ] Enable Airplane Mode (disable Wi-Fi and mobile data) on the physical device.
- [ ] Cold-start the app while offline -> confirm it boots to Home without hanging on a spinner or showing the fatal boot error screen.
- [ ] Create and save a Sleep Plan while offline -> confirm the snackbar states it was saved on this device only (`บันทึกในเครื่องนี้เท่านั้น...`).
- [ ] Complete an SQI assessment while offline -> confirm the **คำนวณแบบออฟไลน์** (`Calculated offline`) dialog appears and allows viewing the full result locally.
- [ ] Disable Airplane Mode (restore connectivity) and tap Retry -> confirm pending data syncs cleanly without creating duplicate records.

---

## 4. Execution Sign-Off Record

| Field | Value |
|---|---|
| **Platform** | Android Physical Device |
| **Artifact Tested** | `app-dev-release.apk` (`com.snoozefriend.snoozemate.dev`) |
| **Target Firebase Project** | `sleep-optimizer-dev` |
| **Artifact SHA-256** | `PENDING` |
| **Device Model & Android OS Version** | `PENDING` |
| **Tester & Date** | `PENDING` |
| **Real-Device Result** | **`PENDING`** |
