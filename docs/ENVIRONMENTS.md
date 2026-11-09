# Environments

Three targets, one Flutter app. Nothing in the app switches them automatically today —
you choose the target with the Firebase CLI alias and with the `firebase_options` file
the code imports.

| Target | Firebase project | CLI alias | App config |
| --- | --- | --- | --- |
| Local | `demo-*` id + emulator suite | none (emulator) | resolved from whatever `firebase_options.dart` holds; no data leaves the machine |
| Dev | `sleep-optimizer-dev` | `dev` (also the `.firebaserc` default) | `lib/firebase_options_dev.dart` (not wired yet) |
| Prod | `sleep-optimizer-59c83` | `prod` | `lib/firebase_options.dart`, `android/app/google-services.json` |

`.firebaserc`:

```json
{ "projects": { "default": "sleep-optimizer-dev", "dev": "sleep-optimizer-dev", "prod": "sleep-optimizer-59c83" } }
```

> **TODO (owner):** `sleep-optimizer-dev` is a placeholder for the project you create in
> the Console. If your dev project id differs, change both `default` and `dev` in
> `.firebaserc` — and nothing else. Until it exists, every CLI command that resolves the
> default fails loudly with "project not found", which is the intended fail-safe.

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
  --android-out=android/app/google-services.json
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
| `android/app/build.gradle.kts` (`namespace`, `applicationId`) | `com.snoozefriend.snoozemate` |
| `android/app/google-services.json` | `com.snoozefriend.snoozemate` → `1:790423794853:android:b834a222cb28203f1fc94c` (the old `com.example.snoozemate` client, `…:86ee998e7ba6127d1fc94c`, is still listed) |
| `lib/firebase_options.dart` → `android` | `1:790423794853:android:b834a222cb28203f1fc94c` |
| `firebase.json` → `flutter.platforms` | android `b834…`, dart android `b834…`, dart ios `1:790423794853:ios:618f0814255930491fc94c` |
| `ios/Runner.xcodeproj` `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.snoozemate` |
| `lib/firebase_options.dart` → `ios.iosBundleId` | `com.example.snoozemate` |

Android is consistent end to end. **iOS is not part of the rename yet:** it still uses
`com.example.snoozemate`, and its config matches that old bundle id, so the app builds and
runs — but iOS does not share the new Android id. Closing the gap is a human step: register
an iOS app for `com.snoozefriend.snoozemate` in the Console, change
`PRODUCT_BUNDLE_IDENTIFIER` in Xcode, then regenerate `lib/firebase_options.dart` with
`flutterfire configure`. Do not hand-edit `iosBundleId`: a bundle id with no registered
iOS app breaks sign-in.

Wiring the Dart side is **deliberately not done yet**. Today
`lib/app/bootstrap.dart` imports `lib/firebase_options.dart` (prod). When the dev project
is ready, the switch becomes a compile-time choice, for example:

```dart
// lib/app/bootstrap.dart
const useDev = bool.fromEnvironment('FIREBASE_ENV_DEV');
// firebase_options_dev.dart exposes the same `DefaultFirebaseOptions` shape
```

then `flutter run --dart-define=FIREBASE_ENV_DEV=true`. Do not hardcode a project id in
`lib/`; the generated `firebase_options_*.dart` files are the only place ids live.

## Running against the emulator

```bash
firebase emulators:start --only auth,firestore --project=demo-snoozemate
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

- The `demo-` prefix keeps the emulator fully offline; it never contacts a real project.
- Ports are wired in `lib/app/bootstrap.dart`: Firestore `8080`, Auth `9099`.
- Rules are enforced by the emulator, and that is where rule changes get tested:
  ```bash
  cd firestore-rules-test && npm test    # emulators:exec, project id "demo-rules-test"
  ```
- Emulator data is disposable — delete it freely, no backups needed.

## Production deploys (human only)

1. Review `firestore.rules` / `firestore.indexes.json` on `main`; confirm the rule tests
   pass in the emulator first.
2. Sanity-check the target explicitly — do not trust the default:
   ```bash
   firebase use        # should list dev as (default) and prod as an alias
   firebase deploy --only firestore:rules,firestore:indexes -P prod
   ```
3. Record what changed and when. Verify behaviour on a **dev** project or emulator, not
   by creating documents in production.
4. Firestore delete protection is enabled on prod. Turning it off is a console step and a
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
