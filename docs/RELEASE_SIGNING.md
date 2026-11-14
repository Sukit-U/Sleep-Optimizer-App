# Release Signing Guide — Snoozefriend

How Android release builds are signed, and the steps left for you because the
keystore itself must be created and owned by you.

> **Current state:** `android/app/build.gradle.kts` reads `android/key.properties`
> and signs the `release` build type with a `release` signing config built from it.
> **No keystore has been generated yet**, so a local
> `flutter build apk --release --flavor prod --dart-define=APP_ENV=prod` produces an
> *unsigned* artifact and Gradle prints
> `android/key.properties not found — release builds will be UNSIGNED`.
> Release builds are never signed with the debug key.
>
> The tag-driven release workflow in §5 does **not** tolerate that: without the
> keystore secrets it fails before building, and it re-verifies the signature of
> every artifact before uploading it.

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
`pull_request`, manual dispatch): analyze + test, the Firestore rules tests, a **dev**
debug APK built with `--flavor dev --dart-define=APP_ENV=dev`, and an unsigned iOS
release compile on `macos-latest`
(`flutter build ios --release --no-codesign --dart-define=APP_ENV=prod`). None of these
jobs signs anything, and the iOS job needs no credentials: it proves the Xcode project
and Pods compile, not that a signed build is shippable.

Release artifacts come from `.github/workflows/release.yml`, which runs on `v*` tags (and
on a manual dispatch, but only when the dispatch targets a tag ref). The tag is the only
source of truth for the version.

| Job | What it does |
|---|---|
| `verify` | `flutter analyze`, `flutter test`, and the release-version self-test |
| `build-android` (needs `verify`) | derives the version from the tag, checks the signing secrets, builds prod AAB + APK, verifies both signatures, uploads `app-prod-release-aab` / `app-prod-release-apk` |

### Version comes from the tag

`scripts/android-release-version.sh` turns the tag into the Android version fields:

| Tag | versionName | versionCode |
|---|---|---|
| `v1.0.0` | `1.0.0` | `10000` |
| `v1.2.3` | `1.2.3` | `10203` |
| `v2.4.99` | `2.4.99` | `20499` |

`versionCode = MAJOR * 10000 + MINOR * 100 + PATCH`, so a higher semver is always a
higher code and two releases never share one. The script rejects anything that is not
`vMAJOR.MINOR.PATCH`: no missing prefix, no `-rc1`/`+2` suffix, no two- or four-part
tags, no leading zeros. It also enforces the Android/Play limits: `MINOR` and `PATCH`
below 100 (so the code keeps semver order) and `MAJOR` below 210000 (Play caps
versionCode at 2100000000).

Rules that follow from that:

- **A fix ships as a new tag.** Re-running the same tag produces the same versionCode,
  and Play rejects a second upload that reuses a code it already holds.
- **A dispatch from a branch fails.** There is no tag to take a version from, so the
  workflow stops with an error instead of inventing one. Dispatch from the tag:
  `gh workflow run release.yml --ref v1.2.3`.
- **`pubspec.yaml` must name the same version.** The workflow reads `version:` (ignoring
  its `+build` part) and fails when it differs from the tag, so the source and the
  artifact never disagree. The build number is not read from pubspec at all; `--build-name`
  and `--build-number` come from the tag.

### Signing is required, not optional

`build-android` recreates the two local files above from repository secrets
(Settings → Secrets and variables → Actions). All three are required:

| Secret | Required | Value |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | yes | the keystore file, base64 encoded in one line |
| `ANDROID_KEYSTORE_PASSWORD` | yes | `storePassword` |
| `ANDROID_KEYSTORE_ALIAS` | yes | `keyAlias` |
| `ANDROID_KEY_PASSWORD` | no | `keyPassword`; when unset it falls back to `ANDROID_KEYSTORE_PASSWORD` |

Before building, the job restores the keystore and opens it with `keytool -list`, using
`ANDROID_KEYSTORE_ALIAS` and `ANDROID_KEYSTORE_PASSWORD` through `-storepass:env` so no
password reaches the log. It then requests a certificate signing request for that alias,
which is the only way to prove `keyPassword` works without exporting the key: a wrong key
password fails there instead of turning into an unsigned artifact.

After building, it verifies the artifacts instead of trusting Gradle:

- fails if Gradle produced any `*unsigned*` APK;
- `jarsigner -verify` must report `jar verified` for the AAB;
- `apksigner verify --print-certs` must accept the APK, and its signer certificate
  SHA-256 must equal the `upload` key's fingerprint from the restored keystore;
- `aapt dump badging` must report the tag's `versionCode` and `versionName`.

The upload steps use exact paths (no `*-unsigned*` glob) and `if-no-files-found: error`,
so a missing or unsigned artifact fails the run rather than being published.


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
| `You must specify a --flavor` | Flavored build without a flavor; add `--flavor prod --dart-define=APP_ENV=prod`. |
| Play rejects the upload | Signed with a different upload key than the one Play has on file, or the versionCode was already used by an earlier tag. |
