# Android Beta Distribution Guide — Snoozemate

This runbook documents how Android beta builds are configured, signed,
verified, and distributed to testers for **Snoozemate (`Sleep-Optimizer-App`)**.

---

## 1. Beta Environment & Safety Policy (`sleep-optimizer-dev`)

All Android beta builds **must** target the **Dev** Firebase environment
(`sleep-optimizer-dev`, project number `564363714331`) and never the production
project (`sleep-optimizer-59c83`):

| Property | Android Beta Value | Production Release Value |
|---|---|---|
| Gradle Flavor | `--flavor dev` | `--flavor prod` |
| Dart Environment | `--dart-define=APP_ENV=dev` | `--dart-define=APP_ENV=prod` |
| Application ID | `com.snoozefriend.snoozemate.dev` | `com.snoozefriend.snoozemate` |
| Native Config | `android/app/src/dev/google-services.json` | `android/app/src/prod/google-services.json` |
| Dart Config | `lib/firebase_options_dev.dart` | `lib/firebase_options.dart` |
| Firebase Project | `sleep-optimizer-dev` | `sleep-optimizer-59c83` |
| Tag Format | `vMAJOR.MINOR.PATCH-beta.N` (`N` in `1..99`) | `vMAJOR.MINOR.PATCH` |
| Output APK | `build/app/outputs/flutter-apk/app-dev-release.apk` | `build/app/outputs/flutter-apk/app-prod-release.apk` |
| Output AAB | `build/app/outputs/bundle/devRelease/app-dev-release.aab` | `build/app/outputs/bundle/prodRelease/app-prod-release.aab` |

### Why Beta Uses `dev` (`com.snoozefriend.snoozemate.dev`)

1. **Production Data Safety:** `sleep-optimizer-59c83` is on the Spark plan with
   Point-in-Time Recovery (PITR) disabled and no automated backups
   (see `docs/INCIDENT_sleepplans-delete.md` and `docs/ENVIRONMENTS.md`).
   Isolating beta testers on `sleep-optimizer-dev` guarantees beta testing cannot
   pollute or damage production data.
2. **Side-by-Side Installation:** Because the `dev` flavor adds
   `applicationIdSuffix = ".dev"`, testers can install the beta app
   (`com.snoozefriend.snoozemate.dev`) alongside a future production build
   (`com.snoozefriend.snoozemate`) without package conflicts. *(Note: a `.dev`
   beta installation does not in-place upgrade to the non-suffixed production
   package.)*
3. **Dual-Layer Mismatch Guard:**
   - **Build-Time (Gradle):** `android/app/build.gradle.kts` decodes
     `-Pdart-defines` and throws a `GradleException` if `--flavor` and
     `--dart-define=APP_ENV` disagree (for example `--flavor dev` with
     `APP_ENV=prod`).
   - **Runtime (Dart):** `CloudConnectionService` and
     `verifyFirebaseOptionsMatchEnv` verify at startup that the active
     `FirebaseOptions` `projectId` and `appId` match `APP_ENV` and log
     `APP_ENV=dev projectId=sleep-optimizer-dev` to `adb logcat`.

---

## 2. Keystore Path Reconciliation (Human Prerequisite)

The repository standardizes on **`android/upload-keystore.jks`** (referenced as
`storeFile=upload-keystore.jks` inside `android/key.properties`). Both files are
gitignored and must never be committed.

If your local workstation has an external path in `android/key.properties`
(e.g., `storeFile=C:/Users/HP/keys/upload-keystore.jks`) and an untracked file at
`android/app/upload-keystore.jks`:

1. Compare the SHA-256 certificate fingerprints of both keystores:
   ```bash
   keytool -list -v -keystore "C:/Users/HP/keys/upload-keystore.jks" -alias upload
   keytool -list -v -keystore "android/app/upload-keystore.jks" -alias upload
   ```
2. Verify which SHA-1 / SHA-256 certificate fingerprint is registered on
   `com.snoozefriend.snoozemate.dev` in Firebase Console (`sleep-optimizer-dev`
   → Project settings → Your apps) and stored in the GitHub Actions secret
   `ANDROID_KEYSTORE_BASE64`.
3. Copy the authoritative upload keystore to `android/upload-keystore.jks`,
   update `android/key.properties` to:
   ```properties
   storeFile=upload-keystore.jks
   keyAlias=upload
   ```
   and delete the unused duplicate keystore file so local and CI builds always
   use the exact same upload certificate.

---

## 3. Reproducible Local Beta Build & Verification

### Step 1 — Derive Version Name and Version Code

Use `scripts/android-release-version.sh --allow-beta` so local beta builds follow
the exact same version rules as CI:

```bash
sh scripts/android-release-version.sh --allow-beta v1.0.0-beta.1
# Outputs:
# version_name=1.0.0-beta.1
# base_version_name=1.0.0
# version_code=10000
# release_channel=beta
# target_env=dev
```

### Step 2 — Build Signed Beta APK (and Optional AAB)

Provide the keystore password via environment variables (so no password is saved
in `android/key.properties`) and build the `dev` release artifact:

```bash
export ANDROID_KEYSTORE_PASSWORD="<your-keystore-password>"
export ANDROID_KEY_PASSWORD="$ANDROID_KEYSTORE_PASSWORD"

flutter build apk --release \
  --flavor dev \
  --dart-define=APP_ENV=dev \
  --build-name=1.0.0-beta.1 \
  --build-number=10000
```

> **Note:** If `android/key.properties` or `ANDROID_KEYSTORE_PASSWORD` is absent,
> Gradle never falls back to debug signing; it prints a warning and outputs an
> unsigned APK (`app-dev-release-unsigned.apk`). Never distribute an unsigned or
> debug-signed APK to beta testers.

### Step 3 — Verify Signature, Package Identity, and Checksum

Before distributing `build/app/outputs/flutter-apk/app-dev-release.apk`, run all
 three verification checks:

1. **Verify APK signature and certificate digest (`apksigner`):**
   ```bash
   "$ANDROID_HOME/build-tools/<version>/apksigner" verify --print-certs \
     build/app/outputs/flutter-apk/app-dev-release.apk
   ```
   Confirm `Signer #1 certificate SHA-256 digest` matches your `upload` key's
   SHA-256 fingerprint (and is **not** `CN=Android Debug`).

2. **Verify package name, `versionCode`, and `versionName` (`aapt2`):**
   ```bash
   "$ANDROID_HOME/build-tools/<version>/aapt2" dump badging \
     build/app/outputs/flutter-apk/app-dev-release.apk | head -n 1
   ```
   Expected output contains:
   `package: name='com.snoozefriend.snoozemate.dev' versionCode='10000' versionName='1.0.0-beta.1'`

3. **Generate SHA-256 checksum for testers:**
   ```bash
   sha256sum build/app/outputs/flutter-apk/app-dev-release.apk \
     > build/app/outputs/flutter-apk/app-dev-release.apk.sha256
   ```

---

## 4. Automated CI Beta Builds (`.github/workflows/release.yml`)

`.github/workflows/release.yml` builds, verifies, and packages signed Android
beta artifacts whenever a `vMAJOR.MINOR.PATCH-beta.N` tag is pushed (or when
dispatched manually via `workflow_dispatch` with `target_env=dev`).

### Required GitHub Repository Secrets

Configure in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Required | Description |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Yes | Base64-encoded `android/upload-keystore.jks` (`base64 -w 0 android/upload-keystore.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Yes | Keystore password (`storePassword`) |
| `ANDROID_KEYSTORE_ALIAS` | Yes | Key alias (`upload`) |
| `ANDROID_KEY_PASSWORD` | No | Key password (defaults to `ANDROID_KEYSTORE_PASSWORD` when unset) |

### What `release.yml` Does on a Beta Tag (`v1.0.0-beta.1`)

1. Runs `flutter analyze`, `flutter test`, and
   `sh scripts/android-release-version.sh --self-test`.
2. Parses `v1.0.0-beta.1` via
   `sh scripts/android-release-version.sh --allow-beta v1.0.0-beta.1` and forces
   `FLAVOR=dev`, `APP_ENV=dev`, `EXPECTED_PACKAGE=com.snoozefriend.snoozemate.dev`,
   and `FIREBASE_PROJECT=sleep-optimizer-dev`.
3. Verifies `pubspec.yaml` declares matching base version `1.0.0`.
4. Decodes `ANDROID_KEYSTORE_BASE64` to `android/upload-keystore.jks`, validates
   the store and key passwords via `keytool` (`-storepass:env` / `-keypass:env`
   so secrets are never echoed), and writes a passwordless
   `android/key.properties`.
5. Builds `app-dev-release.aab` and `app-dev-release.apk`.
6. Verifies both signatures (`jarsigner` + `apksigner verify --print-certs`),
   compares the APK's SHA-256 signer certificate against the keystore, and checks
   `aapt2 dump badging` for `com.snoozefriend.snoozemate.dev`, `versionCode`,
   and `versionName`.
7. Deletes `android/upload-keystore.jks` and `android/key.properties` in an
   `if: always()` step so signing files can never leak into artifacts.
8. Uploads `app-dev-release-aab` and `app-dev-release-apk` as workflow artifacts
   and creates a **Draft GitHub Pre-Release** (`--draft --prerelease`) attaching
   `app-dev-release.apk` and `app-dev-release.apk.sha256` for human review.

---

## 5. Beta Distribution Methods for Testers

After running the physical-device checks in
`docs/testing/android-beta-smoke-checklist.md`, distribute the verified
`app-dev-release.apk` (or `app-dev-release.aab`) using one of the following
channels:

1. **GitHub Pre-Release Draft (Default in `release.yml`):**
   - Review the draft pre-release created by `release.yml` for tag
     `v1.0.0-beta.1`.
   - Confirm `app-dev-release.apk` and `app-dev-release.apk.sha256` are attached
     and that the release is marked **Pre-release**.
   - Share the download link with invited beta testers so they can download and
     sideload `app-dev-release.apk` directly on Android devices.
2. **Firebase App Distribution (Recommended for Managed Tester Groups):**
   - Upload `app-dev-release.apk` to the `com.snoozefriend.snoozemate.dev`
     Android app in the **`sleep-optimizer-dev`** Firebase Console (App
     Distribution → Releases) or via the Firebase CLI:
     ```bash
     firebase appdistribution:distribute build/app/outputs/flutter-apk/app-dev-release.apk \
       --project=sleep-optimizer-dev \
       --app=1:564363714331:android:cd0fb661bf15fb903f7dbe \
       --release-notes="Snoozemate Android Beta v1.0.0-beta.1 (dev environment)"
     ```
3. **Google Play Internal Testing Track (Optional via AAB):**
   - If you register `com.snoozefriend.snoozemate.dev` (or test via Play
     Internal Testing), upload `app-dev-release.aab` manually in Google Play
     Console → Testing → Internal testing, and ensure Play App Signing's SHA-1 /
     SHA-256 certificate fingerprint is added to `sleep-optimizer-dev` in
     Firebase Console.
