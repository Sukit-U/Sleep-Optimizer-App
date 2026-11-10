# Release Signing Guide — Snoozefriend

How Android release builds are signed, and the steps left for you because the
keystore itself must be created and owned by you.

> **Current state (2026-11-08):** `android/app/build.gradle.kts` reads
> `android/key.properties` and signs the `release` build type with a `release`
> signing config built from it. **No keystore has been generated yet**, so until
> you do §1–§2, `flutter build apk --release --flavor prod --dart-define=APP_ENV=prod`
> produces an *unsigned* artifact and Gradle prints
> `android/key.properties not found — release builds will be UNSIGNED`.
> Release builds are never signed with the debug key.

## 1. Generate the upload keystore

Run once, on your own machine, and keep the file safe — losing it means you can
no longer ship updates (unless Play App Signing lets you reset the upload key).

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
burns the key permanently, because history is forever.

## 2. Create `android/key.properties`

```properties
storeFile=upload-keystore.jks
keyAlias=upload
storePassword=<your keystore password>
keyPassword=<your key password>
```

`storeFile` is resolved relative to `android/` (the directory that holds
`key.properties`), so `upload-keystore.jks` means `android/upload-keystore.jks`.
Note `.properties` files treat `\` as an escape character — use forward slashes.

## 3. Build

Android builds are flavored, so a release build names the prod flavor *and*
`APP_ENV` — the flavor picks `android/app/src/prod/google-services.json`,
`APP_ENV=prod` picks `lib/firebase_options.dart`:

```bash
flutter build appbundle --release --flavor prod --dart-define=APP_ENV=prod
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod
```

A release build without `--flavor` fails ("You must specify a --flavor"), which is
intended: an unflavored artifact would not name the Firebase project it belongs to.

If `android/key.properties` is missing, the build still succeeds but the output
is **unsigned** (Gradle warns, and `app-prod-release-unsigned.apk` is what you get).
There is no `key.properties.example` in the repo on purpose: one file, one
source of truth, and it must never be committed.

## 4. Register the signing certificate with Firebase and Play

The release certificate's SHA-1 has to be attached to the Android app in
Firebase (`com.snoozefriend.snoozemate`, project `sleep-optimizer-59c83`)
before Google sign-in, Play Integrity / App Check, or Dynamic Links can work —
anonymous auth and Firestore do not need it.

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Copy the **SHA-1** (and SHA-256) into
Firebase Console → Project settings → Your apps → *Snoozefriend* → *Add fingerprint*.
Add both the upload-key fingerprint and, after the first Play release, the
**Play App Signing** fingerprint shown in Play Console.

## 5. CI/CD (GitHub Actions)

Branch and PR checks live in `.github/workflows/ci.yml` (push to `main`,
`pull_request`, manual dispatch): analyze + test, the Firestore rules tests, and a
**dev** debug APK built with `--flavor dev --dart-define=APP_ENV=dev`. It never builds
or signs a release artifact.

Release artifacts come from `.github/workflows/release.yml`, which runs on `v*` tags and
on manual dispatch only:

| Job | What it does |
|---|---|
| `verify` | `flutter analyze` + `flutter test` |
| `build-android` (needs `verify`) | prod AAB + APK, uploaded as `app-prod-release-aab` / `app-prod-release-apk` |

That job recreates the two local files above from repository secrets
(Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 android/upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` |

The alias is fixed to `upload` in the workflow, so generate the keystore with
`-alias upload` (§1) or update the workflow. Without the secrets the job still runs,
prints a warning annotation, and produces an **unsigned** bundle and APK — it never
falls back to the debug key. The signing and build steps in `release.yml`:

```yaml
- name: Restore upload keystore
  if: env.ANDROID_KEYSTORE_BASE64 != ''
  run: |
    printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/upload-keystore.jks
    cat > android/key.properties <<PROPERTIES
    storeFile=upload-keystore.jks
    keyAlias=upload
    storePassword=$ANDROID_KEYSTORE_PASSWORD
    keyPassword=$ANDROID_KEY_PASSWORD
    PROPERTIES

- name: Build App Bundle
  run: flutter build appbundle --release --flavor prod --dart-define=APP_ENV=prod

- name: Build APK
  run: flutter build apk --release --flavor prod --dart-define=APP_ENV=prod
```

The keystore written into the workspace is gitignored, and CI runners are disposable.

## 6. Play App Signing

Enable **Play App Signing** for the app: Google holds the *app signing key*, and
the keystore from §1 becomes your *upload key*. That is why a lost upload key is
recoverable — request a reset in Play Console. Do not opt out: if you use your
own app signing key and lose it, the app can never be updated again.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `android/key.properties not found — release builds will be UNSIGNED` | Expected until §2 is done. Create the file. |
| `Keystore was tampered with, or password was incorrect` | Wrong `storePassword`/`keyPassword`, or `storeFile` points at a different keystore. |
| `Failed to read key upload from store` | `keyAlias` does not match the alias used in `keytool -genkey` (`upload` above). |
| `You must specify a --flavor` | Flavored build without a flavor; add `--flavor prod --dart-define=APP_ENV=prod`. |
| Play rejects the upload | The AAB was unsigned (no `key.properties`) or signed with a different upload key than the one Play has on file. |
