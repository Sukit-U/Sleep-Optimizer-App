# Release Signing Guide — Snoozemate

How Android release and beta builds are signed, and the steps left for the
repository owner because the keystore itself must be created and owned by a
human.

> **Current state:** `android/app/build.gradle.kts` reads `android/key.properties`
> and signs the `release` build type (for both `dev` beta and `prod` production
> flavors) with a `release` signing config built from it.
> When `android/key.properties` or the keystore password is not present, a local
> `flutter build apk --release --flavor dev --dart-define=APP_ENV=dev` produces
> an *unsigned* artifact and Gradle prints
> `android/key.properties not found — release builds will be UNSIGNED`.
> Release builds are **never** signed with the debug key.
>
> The tag-driven release workflow in §5 does **not** tolerate unsigned artifacts:
> without the keystore secrets it fails before building, re-verifies the
> signature and package identity of every artifact before uploading it, and
> deletes the temporary keystore file in an `if: always()` cleanup step.

## 1. Generate the upload keystore (Canonical Path)

Run once, on your own machine, and keep the file safe — losing it means you can
no longer ship updates (unless Play App Signing lets you reset the upload key).

The **single canonical location** expected by `android/key.properties`,
`.github/workflows/release.yml`, and this guide is `android/upload-keystore.jks`
(which resolves to `storeFile=upload-keystore.jks` relative to `android/`):

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You will be prompted for a keystore password, a key password, and your name /
organisation. Use a password manager; do not reuse a personal password.

🚫 `*.jks`, `*.keystore` and `/android/key.properties` are already in
`.gitignore`. Never commit the keystore or its passwords — committing either
burns the key permanently, because git history is forever.

### Reconciling Existing Local Keystore Paths (Human Step)

If your local machine has both an external keystore path in
`android/key.properties` (for example `storeFile=C:/Users/HP/keys/upload-keystore.jks`)
and an untracked file at `android/app/upload-keystore.jks`:

1. Compare their SHA-256 certificate fingerprints without printing passwords:
   ```bash
   keytool -list -v -keystore "C:/Users/HP/keys/upload-keystore.jks" -alias upload
   keytool -list -v -keystore "android/app/upload-keystore.jks" -alias upload
   ```
2. Check which SHA-1 / SHA-256 fingerprint is registered in Firebase Console
   (`sleep-optimizer-dev` and `sleep-optimizer-59c83`) and in your GitHub
   Actions `ANDROID_KEYSTORE_BASE64` secret.
3. Place the canonical upload keystore at `android/upload-keystore.jks` (or keep
   it in your secure keys directory outside the repo and point
   `storeFile=upload-keystore.jks` after copying the authoritative keystore to
   `android/upload-keystore.jks`), and remove the unused duplicate `.jks` copy so
   there is no ambiguity about which key signs local builds.

## 2. Create `android/key.properties`

```properties
storeFile=upload-keystore.jks
keyAlias=upload
storePassword=<your keystore password>
keyPassword=<your key password>
```

`storeFile` is resolved relative to `android/` (the directory that holds
`key.properties`), so `upload-keystore.jks` means `android/upload-keystore.jks`.
Note `.properties` files treat `\` as an escape character — always use forward
slashes (`/`).

### Keep the passwords out of the file (Recommended)

Gradle reads `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_PASSWORD` from the
environment before it reads `key.properties`. So the file can name the keystore
and alias with no secret in it:

```properties
storeFile=upload-keystore.jks
keyAlias=upload
```

```bash
export ANDROID_KEYSTORE_PASSWORD="$(pass show android/upload)"
export ANDROID_KEY_PASSWORD="$ANDROID_KEYSTORE_PASSWORD"
# Beta release build (targets sleep-optimizer-dev):
flutter build apk --release --flavor dev --dart-define=APP_ENV=dev \
  --build-name=1.0.0-beta.1 --build-number=999901
```

When `ANDROID_KEY_PASSWORD` is unset it falls back to
`ANDROID_KEYSTORE_PASSWORD`, the same rule the release workflow uses. A
keystore without a password stays unsigned instead of signing with the debug
key.

A password that was ever stored in plaintext must be rotated. Run
`keytool -genkey` again with a new password and delete the old keystore, then
repeat §4 because the certificate changes. Check every copy of the old file,
including backups and other checkouts.

`.github/workflows/release.yml` exports these two names at job level from
repository secrets, its temporary `key.properties` holds no password, and an
`if: always()` cleanup step deletes both `android/upload-keystore.jks` and
`android/key.properties` immediately after verification.

## 3. Build & Flavor / `APP_ENV` Safety Guard

Android builds are flavored, and `android/app/build.gradle.kts` enforces at
build time that `--flavor` and `--dart-define=APP_ENV` always match:

- **Beta Release Build (`dev` -> `sleep-optimizer-dev`, applicationId `com.snoozefriend.snoozemate.dev`):**
  ```bash
  flutter build apk --release --flavor dev --dart-define=APP_ENV=dev \
    --build-name=1.0.0-beta.1 --build-number=999901
  flutter build appbundle --release --flavor dev --dart-define=APP_ENV=dev \
    --build-name=1.0.0-beta.1 --build-number=999901
  ```
- **Production Release Build (`prod` -> `sleep-optimizer-59c83`, applicationId `com.snoozefriend.snoozemate`):**
  ```bash
  flutter build appbundle --release --flavor prod --dart-define=APP_ENV=prod \
    --build-name=1.0.0 --build-number=1000000
  flutter build apk --release --flavor prod --dart-define=APP_ENV=prod \
    --build-name=1.0.0 --build-number=1000000
  ```

### Build-Time Mismatch Protection

- A build without `--flavor` fails (`You must specify a --flavor`).
- A build where `--flavor` and `--dart-define=APP_ENV` disagree (for example
  `--flavor dev --dart-define=APP_ENV=prod` or
  `--flavor prod --dart-define=APP_ENV=dev`) fails immediately in Gradle with:
  `Flavor '<flavor>' does not match --dart-define=APP_ENV=<env>`.
- A `prod` release build without an explicit `--dart-define=APP_ENV=prod` fails
  immediately in Gradle with:
  `Production release build requires explicit --dart-define=APP_ENV=prod`.

If `android/key.properties` is missing, the local build still compiles so you
can verify code/resource shrinking, but the output is **unsigned** (Gradle
warns, and `app-<flavor>-release-unsigned.apk` is produced). There is no
`key.properties.example` in the repo on purpose: one file, one source of truth,
and it must never be committed.

## 4. Register the signing certificate with Firebase and Play

The release certificate's SHA-1 and SHA-256 must be attached to the Android apps
in Firebase before Google sign-in, Play Integrity / App Check, or Dynamic Links
can work:

- **Beta (`dev`):** `com.snoozefriend.snoozemate.dev` in Firebase project
  `sleep-optimizer-dev`
- **Production (`prod`):** `com.snoozefriend.snoozemate` in Firebase project
  `sleep-optimizer-59c83`

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Copy the **SHA-1** and **SHA-256** into
Firebase Console → Project settings → Your apps → *Add fingerprint*.
Add both the upload-key fingerprint and, after the first Play release, the
**Play App Signing** fingerprint shown in Play Console.

## 5. CI/CD (GitHub Actions)

Branch and PR checks live in `.github/workflows/ci.yml` (push to `main`,
`pull_request`, manual dispatch): analyze + test, the Firestore rules tests, a **dev**
debug APK built with `--flavor dev --dart-define=APP_ENV=dev`, and an unsigned iOS
release compile on `macos-latest`. None of these jobs signs anything.

Signed release and beta artifacts come from `.github/workflows/release.yml`,
which runs on `v*` tags (and on `workflow_dispatch` with `target_env` and
`release_tag`).

| Job | What it does |
|---|---|
| `verify` | `flutter analyze`, `flutter test`, and `sh scripts/android-release-version.sh --self-test` |
| `build-android` (needs `verify`) | derives version + environment from the tag, checks `pubspec.yaml`, validates signing secrets, builds signed AAB + APK for `dev` (beta) or `prod` (release), verifies signatures and package identity, deletes temporary keystore files (`if: always()`), uploads workflow artifacts, and creates a draft GitHub pre-release for `v*-beta.*` tags |

### Version and channel come from the tag

`scripts/android-release-version.sh` turns the tag into the Android version and
channel fields:

| Tag | Mode | versionName | base_version_name | versionCode | Channel / Env |
|---|---|---|---|---|---|
| `v1.0.0-beta.1` | `--allow-beta` | `1.0.0-beta.1` | `1.0.0` | `999901` | `beta` / `dev` |
| `v1.0.0-beta.2` | `--allow-beta` | `1.0.0-beta.2` | `1.0.0` | `999902` | `beta` / `dev` |
| `v1.0.0` | standard / `--allow-beta` | `1.0.0` | `1.0.0` | `1000000` | `prod` / `prod` |
| `v1.2.3-beta.12` | `--allow-beta` | `1.2.3-beta.12` | `1.2.3` | `1020212` | `beta` / `dev` |
| `v2.4.99` | standard / `--allow-beta` | `2.4.99` | `2.4.99` | `2049900` | `prod` / `prod` |

With `baseCode = MAJOR * 10000 + MINOR * 100 + PATCH`, stable tags map to
`baseCode * 100` and beta tags (`-beta.N`, `1 <= N <= 99`) map to
`(baseCode - 1) * 100 + N`. Two releases therefore never share a version code,
and every beta and stable release increases monotonically (`v1.0.0-beta.1 <
v1.0.0-beta.2 < v1.0.0`). Standard mode (`sh scripts/android-release-version.sh <tag>`)
accepts only `vMAJOR.MINOR.PATCH`. Extended mode (`--allow-beta`) also accepts
`vMAJOR.MINOR.PATCH-beta.N` (`1 <= N <= 99`), routing beta tags strictly to the
`dev` flavor (`sleep-optimizer-dev`).

Rules that follow from that:

- **Beta tags never touch production.** Any `vMAJOR.MINOR.PATCH-beta.N` tag
  enforces `--flavor dev --dart-define=APP_ENV=dev` (`com.snoozefriend.snoozemate.dev`,
  `sleep-optimizer-dev`). Attempting to dispatch a `-beta.N` tag with
  `target_env=prod` is rejected by `release.yml`.
- **A fix ships as a new tag.** Re-running the same tag produces the same versionCode,
  and Play rejects a second upload that reuses a code it already holds.
- **`pubspec.yaml` must name the same base version.** The workflow reads `version:`
  (ignoring its `+build` part) and fails when it differs from `base_version_name`.

### Signing is required, not optional

`build-android` recreates `android/upload-keystore.jks` and
`android/key.properties` temporarily from repository secrets
(Settings → Secrets and variables → Actions). The first three are required:

| Secret | Required | Value |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | yes | the keystore file, base64 encoded in one line (`base64 -w 0 android/upload-keystore.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | yes | `storePassword` |
| `ANDROID_KEYSTORE_ALIAS` | yes | `keyAlias` (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | no | `keyPassword`; when unset it falls back to `ANDROID_KEYSTORE_PASSWORD` |

After building, the workflow verifies the artifacts instead of trusting Gradle:

- fails if Gradle produced any `*unsigned*` APK;
- `jarsigner -verify` must report `jar verified` for the AAB;
- `apksigner verify --print-certs` must accept the APK, and its signer certificate
  SHA-256 must equal the `upload` key's fingerprint from the restored keystore;
- `aapt2 dump badging` (or `aapt`) must report the expected `package: name`
  (`com.snoozefriend.snoozemate.dev` for `dev`, `com.snoozefriend.snoozemate`
  for `prod`), `versionCode`, and `versionName`;
- `rm -f android/upload-keystore.jks android/key.properties` runs with
  `if: always()` before any artifact upload step.

## 6. Play App Signing

Enable **Play App Signing** for the app: Google holds the *app signing key*, and
the keystore from §1 becomes your *upload key*. That is why a lost upload key is
recoverable — request a reset in Play Console. Do not opt out: if you use your
own app signing key and lose it, the app can never be updated again.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `android/key.properties not found — release builds will be UNSIGNED` | Local build without §2. Create the file; the release workflow refuses to run unsigned instead. |
| `Keystore was tampered with, or password was incorrect` | Wrong `storePassword`/`keyPassword`, or `storeFile` points at a different keystore. |
| `Failed to read key upload from store` | `keyAlias` does not match the alias used in `keytool -genkey` (`upload` above). |
| `You must specify a --flavor` | Flavored build without a flavor; add `--flavor dev --dart-define=APP_ENV=dev` (beta) or `--flavor prod --dart-define=APP_ENV=prod` (prod). |
| `Flavor 'dev' does not match --dart-define=APP_ENV=prod` | Mismatched `--flavor` and `APP_ENV`; always pair `dev` with `APP_ENV=dev` and `prod` with `APP_ENV=prod`. |
| Play rejects the upload | Signed with a different upload key than the one Play has on file, or the versionCode was already used by an earlier tag. |
