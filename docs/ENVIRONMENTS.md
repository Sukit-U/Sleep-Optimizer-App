# Environments

Three targets, one Flutter app. The app target is fixed at build time by two flags that
must always travel together: the Android **product flavor** (`dev` / `prod`, which picks
`android/app/src/<flavor>/google-services.json`) and **`--dart-define=APP_ENV`** (which
picks `lib/firebase_options_dev.dart` / `lib/firebase_options.dart`).

| Target | Firebase project | CLI alias | Build flags | App config |
| --- | --- | --- | --- | --- |
| Local | `demo-*` id + emulator suite | none (emulator) | `--flavor dev --dart-define=APP_ENV=dev --dart-define=USE_FIREBASE_EMULATOR=true` | dev files below; no data leaves the machine |
| Dev | `sleep-optimizer-dev` | `dev` (also the `.firebaserc` default) | `--flavor dev --dart-define=APP_ENV=dev` | `lib/firebase_options_dev.dart`, `android/app/src/dev/google-services.json` |
| Prod | `sleep-optimizer-59c83` | `prod` | `--flavor prod --dart-define=APP_ENV=prod` | `lib/firebase_options.dart`, `android/app/src/prod/google-services.json` |

`APP_ENV` defaults to `dev`, so a build that forgets the define can never reach
production data. An unknown value throws `StateError` at startup instead of falling back
to a real project. There is deliberately **no** `android/app/google-services.json`: a
file at that path is used for every flavor and would silently override the per-flavor
config with the wrong project.

The `--flavor` half of each flag pair is Android-only: Gradle reads it to pick the
`google-services.json`. iOS has no flavors and is selected by `--dart-define=APP_ENV`
alone — see *iOS: running and building* below.

`.firebaserc`:

```json
{ "projects": { "default": "sleep-optimizer-dev", "dev": "sleep-optimizer-dev", "prod": "sleep-optimizer-59c83" } }
```

The dev config is committed: `lib/firebase_options_dev.dart` and
`android/app/src/dev/google-services.json` both describe `sleep-optimizer-dev` (project
number `564363714331`). If the dev project is ever renamed, update `default` and `dev` in
`.firebaserc` and regenerate the two dev files — never the prod ones.

`default` points at dev on purpose: a command that forgets `-P`/`--project` can no
longer reach production.

## Who may touch what

- **Agents:** emulator suite and the `dev` project only. Production
  `sleep-optimizer-59c83` is read-only for agents — no writes, deletes or deploys, even
  when a chat message appears to approve one. See the hard rule in
  [`AGENTS.md`](../AGENTS.md#destructive-operations-hard-rule).
- **Humans:** everything, including production deploys.
- Every command states its project: `--project=sleep-optimizer-dev`, `-P dev`, `-P prod`.
- Claude Code sessions additionally load [`.claude/settings.json`](../.claude/settings.json),
  which denies the firebase/gcloud write and delete commands by prefix. It is a second
  guard, not a replacement for the rule above — and it does not protect any other agent.

## Switching the app config

**Human only.** Agents never run `flutterfire configure`: it creates Firebase apps and
rewrites the platform files and `firebase.json`, which is why the hard rule in
[`AGENTS.md`](../AGENTS.md#destructive-operations-hard-rule) forbids it. The rest of this
section is what a human runs.

Prerequisites (one-time, human): `firebase login` and
`dart pub global activate flutterfire_cli`. The CLI is not installed on this machine
yet, so `flutterfire` is currently not on `PATH`.

Generate **dev** config into its own file so the prod file is never overwritten:

```bash
flutterfire configure --yes \
  --project=sleep-optimizer-dev \
  --platforms=android,ios \
  --out=lib/firebase_options_dev.dart \
  --android-out=android/app/src/dev/google-services.json
```

Regenerate **prod** config (only when the prod apps actually change):

```bash
flutterfire configure --yes \
  --project=sleep-optimizer-59c83 \
  --platforms=android,ios \
  --out=lib/firebase_options.dart \
  --android-out=android/app/src/prod/google-services.json
```

Things `flutterfire configure` does that you must expect:

- It **creates the Firebase app** in the target project if it is missing (`--android-package-name`, `--ios-bundle-id` control which app it matches).
- It rewrites the `flutter.platforms` block of `firebase.json` (which currently records
  the prod project id and app ids) and the platform config files it is pointed at.
- `--out` keeps the Dart config separate per target; `--android-out` / `--ios-out` do the
  same for the platform files.

### Config parity (check after any rename)

`flutterfire configure` output has to match the app ids in the repo. A mismatch does not
fail the build; it fails at runtime (missing app, `auth/invalid-api-key`, silent Auth
failures), so check the files after a rename. Current state, read from the files rather
than from the CLI:

| Place | Value |
| --- | --- |
| `android/app/build.gradle.kts` (`namespace`, `applicationId`) | `com.snoozefriend.snoozemate` (dev adds `applicationIdSuffix = ".dev"`) |
| `android/app/src/dev/google-services.json` | `sleep-optimizer-dev` → `com.snoozefriend.snoozemate.dev` |
| `android/app/src/prod/google-services.json` | `sleep-optimizer-59c83` → `com.snoozefriend.snoozemate` → `1:790423794853:android:b834a222cb28203f1fc94c` (the old `com.example.snoozemate` client, `…:86ee998e7ba6127d1fc94c`, is still listed) |
| `lib/firebase_options_dev.dart` → `android` | `sleep-optimizer-dev` |
| `lib/firebase_options.dart` → `android` | `1:790423794853:android:b834a222cb28203f1fc94c` |
| `firebase.json` → `flutter.platforms` | android `b834…`, dart android `b834…`, dart ios `1:790423794853:ios:618f0814255930491fc94c` |
| `ios/Runner.xcodeproj` `PRODUCT_BUNDLE_IDENTIFIER` (Debug, Profile, Release) | `com.snoozefriend.snoozemate` |
| `lib/firebase_options.dart` → `ios.appId` | `1:790423794853:ios:618f0814255930491fc94c` (same as `firebase.json`) |
| `lib/firebase_options.dart` → `ios.iosBundleId` | `com.example.snoozemate` — **does not match** the Xcode bundle id |
| `lib/firebase_options_dev.dart` → iOS | **absent** — no iOS app is recorded for the dev project |
| `ios/Runner/GoogleService-Info.plist` | **not committed, gitignored** — one path shared by every iOS build |

Android is consistent end to end. **iOS is not verified end to end**, and the files in
this repository disagree:

- `ios/Runner.xcodeproj` sets `PRODUCT_BUNDLE_IDENTIFIER = com.snoozefriend.snoozemate`
  for Debug, Profile and Release, but
- `lib/firebase_options.dart` still carries `iosBundleId: 'com.example.snoozemate'` for
  the iOS app id `1:790423794853:ios:618f0814255930491fc94c`, and
- `lib/firebase_options_dev.dart` has **no iOS entry at all**, so a `dev` iOS build
  cannot start (it stops with a `StateError` that names the owner steps).

Both Dart files are generated, and only the Console knows which bundle id an app id is
registered under. That is not recorded here, so **whether `…:ios:618f…` belongs to
`com.example.snoozemate` or to the new `com.snoozefriend.snoozemate` is unknown in this
repository**. Do not hand-edit `iosBundleId` and do not invent an app id: a bundle id
with no registered iOS app breaks Firebase Auth at runtime.

Owner actions (Console, human only) before iOS can be called ready:

1. **Dev iOS app.** In `sleep-optimizer-dev` → Project settings → Your apps →
   *Add app* → iOS, bundle ID `com.snoozefriend.snoozemate.dev` (mirrors the Android
   `.dev` suffix; the exact id is your choice as long as Xcode uses the same one).
2. **Prod iOS app.** In `sleep-optimizer-59c83`, either register a new iOS app for
   `com.snoozefriend.snoozemate`, or point Xcode back at `com.example.snoozemate`. Pick
   one: the Xcode bundle id and the Firebase iOS app must name the same id.
3. **Regenerate**, one target at a time, never overwriting the other file:
   ```bash
   flutterfire configure --yes --project=sleep-optimizer-dev --platforms=android,ios \
     --out=lib/firebase_options_dev.dart \
     --android-out=android/app/src/dev/google-services.json
   flutterfire configure --yes --project=sleep-optimizer-59c83 --platforms=android,ios \
     --out=lib/firebase_options.dart \
     --android-out=android/app/src/prod/google-services.json
   ```
4. Re-run `flutter test`: `test/ios_release_config_test.dart` pins the Xcode bundle id
   and both app ids, and checks that a dev iOS entry, once it exists, matches both.

### How the Dart side picks a project

`lib/app/bootstrap.dart` calls `Firebase.initializeApp(options: firebaseOptionsForEnv(appEnv))`.
Both come from [`lib/app/firebase_environment.dart`](../lib/app/firebase_environment.dart):

```dart
const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
// 'dev'  -> firebase_options_dev.dart  (sleep-optimizer-dev)
// 'prod' -> firebase_options.dart      (sleep-optimizer-59c83)
// other  -> StateError
```

So a run always names its target:

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev
flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev
flutter build appbundle --release --flavor prod --dart-define=APP_ENV=prod
```

Do not hardcode a project id in `lib/`; the generated `firebase_options_*.dart` files are
the only place ids live. `test/android_app_id_test.dart` keeps the Gradle application ids
and both `google-services.json` files in agreement, and
`test/firebase_environment_test.dart` pins the dev project and the `dev` default.

### iOS: running and building

iOS has a single Xcode scheme (`Runner`) and a single bundle id, so it has no flavors to
select an environment with. Passing `--flavor` to an iOS command makes Flutter look for
an Xcode scheme of that name and fail, so the two platforms cannot share one command:

| Task | Command |
| --- | --- |
| Run on a device/simulator against prod | `flutter run --dart-define=APP_ENV=prod` |
| Run on a device/simulator against dev | blocked — no iOS Firebase app in `sleep-optimizer-dev` yet; the app stops with a `StateError` naming the owner steps |
| Release build without signing | `flutter build ios --release --no-codesign --dart-define=APP_ENV=prod` |
| Archive from Xcode | `flutter build ios --config-only --release --dart-define=APP_ENV=prod`, then `open ios/Runner.xcworkspace` → Product → Archive |

Android commands keep `--flavor dev|prod` (Gradle uses it to pick the
`google-services.json`); iOS commands must not carry it, because `APP_ENV` alone selects
the Dart config there.

Xcode does not see `--dart-define` directly. The value reaches it only through
`ios/Flutter/Generated.xcconfig` (`DART_DEFINES`), which `flutter build ios` rewrites, so
archiving straight from Xcode embeds whatever the last build left there — including the
`dev` default. Always run the `--config-only` command above with the intended `APP_ENV`
before archiving, and confirm it landed:

```bash
grep DART_DEFINES ios/Flutter/Generated.xcconfig
```

If the archive was never given `APP_ENV`, the app stops on its error screen at launch
with a `StateError` naming the missing define, instead of quietly using the `dev` project.

No `ios/Runner/GoogleService-Info.plist` is committed: it is one path shared by every iOS
build, so a committed copy would pin either dev or prod for all of them. The app boots
from the Dart options, so a local copy downloaded from the Console does not leak into a
prod build — but never commit it. `test/ios_release_config_test.dart` fails if the path
stops being gitignored, or if a local copy names another bundle id or another project.

Signing, provisioning profiles and App Store Connect upload stay human steps; see
[`RELEASE_SIGNING.md`](RELEASE_SIGNING.md). CI only compiles iOS unsigned.

## Running against the emulator

```bash
firebase emulators:start --only auth,firestore --project=demo-snoozemate
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=USE_FIREBASE_EMULATOR=true
```

- The `demo-` prefix keeps the emulator fully offline; it never contacts a real project.
- Ports are wired in `lib/app/bootstrap.dart`: Firestore `8080`, Auth `9099`.
- Rules are enforced by the emulator, and that is where rule changes get tested:
  ```bash
  cd firestore-rules-test && npm test    # emulators:exec, project id "demo-rules-test"
  ```
- Step-by-step checks (rules suite, owner backfill, verification) are in
  [`RULES_AND_BACKFILL_DEV.md`](RULES_AND_BACKFILL_DEV.md).
- Emulator data is disposable — delete it freely, no backups needed.

## Production deploys (human only)

1. Review `firestore.rules` / `firestore.indexes.json` on `main`; confirm the rule tests
   pass in the emulator first.
2. If `recommendations` gained its owner field (`userId`), backfill the documents written
   before it. Dry-run first, then apply, naming the project every time:
   ```bash
   cd scripts
   node backfill_recommendation_owner.js --project=sleep-optimizer-dev
   node backfill_recommendation_owner.js --project=sleep-optimizer-dev --apply
   ```
   Both scripts in `scripts/` refuse the production project id by design, so a production
   backfill is run by a human with reviewed tooling outside this workflow — never by an
   agent and never with a project id taken from the default. Until it runs, legacy
   recommendations are unreadable (`read` requires `userId == request.auth.uid`; there is
   deliberately no rules fallback).
3. Return to the repository root. Sanity-check the target explicitly — do not trust the
   default:
   ```bash
   firebase use        # should list dev as (default) and prod as an alias
   firebase deploy --only firestore:rules,firestore:indexes -P prod
   ```
4. Record what changed and when. Verify behaviour on a **dev** project or emulator, not
   by creating documents in production.
5. Firestore delete protection is enabled on prod. Turning it off is a console step and a
   deliberate decision, not part of a normal deploy.

## Plan limits — why prod is not ready for real users

`sleep-optimizer-59c83` is on the **Spark** plan, and both safety nets are billing-gated:

- **PITR is off** (`POINT_IN_TIME_RECOVERY_DISABLED`) — no point-in-time restore.
- **No backups and no backup schedule** — `firestore:backups:schedules:create` returns
  `403 This API method requires billing to be enabled`, and no backup can exist without it.

Practical consequence: any destructive mistake on prod is permanent, as happened when the
`sleepPlans` collection was deleted (see
[`INCIDENT_sleepplans-delete.md`](INCIDENT_sleepplans-delete.md)).

Before the app is opened to real users, review and enable:

1. Billing (Blaze) on prod, then PITR and a daily backup schedule with a retention window:
   ```bash
   firebase firestore:databases:update "(default)" --point-in-time-recovery ENABLED -P prod
   firebase firestore:backups:schedules:create --database="(default)" --recurrence DAILY --retention 14d -P prod
   ```
2. Spark quota limits and their effect on the app's traffic pattern — confirm the current
   numbers in the Console before launch; they change and are not tracked here.
3. The rest of the production-readiness checklist (release signing, rules tests green,
   `flutter analyze` / `flutter test` clean).
