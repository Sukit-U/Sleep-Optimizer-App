# Rules checks and owner backfill — dev runbook

Step-by-step for changing `firestore.rules` and for backfilling the
`recommendations.userId` owner field. Everything here is emulator or `dev`
project work. Production is a human step described at the end; agents never
run it.

## Ground rules

- Rules changes are tested against the emulator, never by writing documents to
  a live project.
- Every firebase/gcloud command names its project: `--project=demo-…` or
  `-P dev`. Never rely on the `.firebaserc` default.
- The scripts in [`../scripts/`](../scripts) refuse the production project id
  by design. Do not edit that guard to "just run it once".
- No service-account key files in the repository. See
  [`../scripts/README.md`](../scripts/README.md).
- No collection-level deletes, no `--all-collections`, no
  `firestore:bulkdelete`. One document path at a time, and only when the task
  is explicitly about removing that document.

## Prerequisites

| Tool | Why |
| --- | --- |
| Flutter SDK | run the app, `flutter analyze` |
| Node 20+ | rules tests and migration scripts |
| Java 21+ | Firestore emulator (`firebase-tools`) |
| `firebase-tools` | installed locally in `firestore-rules-test/` |

On Windows the rules-test runner defaults `JAVA_HOME` to the JDK bundled with
Android Studio (`C:\Program Files\Android\Android Studio\jbr`). Export
`JAVA_HOME` to override it.

## 1. Run the rules tests first

This is the only required check for a rules change. It loads
`../firestore.rules` from disk, so no deployment is involved.

```bash
cd firestore-rules-test
npm install        # first run only
npm test
```

What happens:

- `firebase emulators:exec --only firestore --project demo-rules-test` starts a
  throwaway emulator on `127.0.0.1`.
- The suite asserts owner reads, cross-user reads, unauthenticated access,
  query scoping, schema validation and default deny.
- The emulator shuts down when the suite finishes.

A clean run ends with `tests N`, `pass N`, `fail 0` and exit code 0. Do not
run `npm test` inside the `emulators:exec` command string — the runner does
that already, and nesting it starts a second emulator that collides on ports.

To run a single case while iterating:

```bash
cd firestore-rules-test
npx firebase emulators:exec --only firestore --project demo-rules-test \
  "node --test --test-name-pattern=recommendations firestore.rules.test.mjs"
```

## 2. Check the behaviour in the app (optional)

Only needed when the change affects what a screen shows, not for a pure rules
assertion.

```bash
# terminal 1 - from the repository root
firebase emulators:start --only auth,firestore --project=demo-snoozemate

# terminal 2
flutter run --flavor dev --dart-define=APP_ENV=dev \
  --dart-define=USE_FIREBASE_EMULATOR=true
```

Walk through the flow that matters: answer the SQI questionnaire, open
History, open a saved assessment's recommendations. Emulator data is
disposable — restarting the suite wipes it.

A second user means a fresh anonymous identity: clear the app's data (or use a
second emulator/device profile), then repeat the flow. The two users must not
see each other's records or recommendations.

## 3. Backfill owners on the emulator

The backfill exists because recommendation documents written before the owner
field have no `userId`, and `firestore.rules` has no fallback for them. Run it
against the emulator first, with the emulator still running:

```bash
# dry-run: prints counts, writes nothing
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
  node scripts/backfill_recommendation_owner.js --project=demo-snoozemate
```

Expect a summary with `scanned`, `missing owner`, `resolvable from parent` and
`would update`. Check the numbers before continuing:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
  node scripts/backfill_recommendation_owner.js --project=demo-snoozemate --apply
```

Then re-run the dry-run. It should report `missing owner: 0` (or only the
documents it counted as `unresolved`). The Admin SDK bypasses security rules,
so a successful write here does not prove the app can read the result — check
step 2 again.

`unresolved` means the parent `sqiRecords/{recordId}` is missing or has no
`userId`. Those rows need a human decision; the script leaves them untouched.

## 4. Backfill on the dev project (human)

Credentials for a real project come from Application Default Credentials. Keep
the key outside the repository:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/outside/the/repo/dev-admin.json

node scripts/backfill_recommendation_owner.js --project=sleep-optimizer-dev
# review the counts, then
node scripts/backfill_recommendation_owner.js --project=sleep-optimizer-dev --apply
```

`node scripts/migrate_user_id.js` uses the same pattern when the legacy
`sqiRecords.userId` value needs rewriting.

Rules and indexes reach the dev project only through a human-run deploy. The
new recommendation query needs the composite index from
`firestore.indexes.json`, so deploy indexes before (or with) rules:

```bash
firebase deploy --only firestore:indexes -P dev
firebase deploy --only firestore:rules -P dev
```

## 5. What "working" looks like

| Case | Expected |
| --- | --- |
| Owner opens History and expands an assessment | recommendations load |
| Second user queries the first user's `recordId` | `permission denied` in logs, no data |
| Unauthenticated client reads `recommendations` | denied |
| Query without `where('userId', …)` | denied (rules are not filters) |
| Document written before the owner field | unreadable by everyone until backfilled |
| New SQI submission | `userId` written with each recommendation |

If a user sees an empty recommendation sheet after a successful SQI
submission, check the write path first: `addRecommendation` throws
`ArgumentError` when `userId` is empty rather than saving an unowned document.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `Missing or insufficient permissions` on `/recommendations` | the query is not owner-scoped, or the document predates `userId` |
| `The query requires an index` | composite index not deployed; the emulator does not need it |
| `JAVA_HOME` / `java` not found | export the Android Studio JBR path |
| `Script exited with code 1` from `emulators:exec` | the suite failed; read the first failing assertion, not the emulator shutdown lines |
| Port 8080 or 9099 already in use | another emulator is running; stop it instead of changing app ports |
| `MetadataLookupWarning` from the Admin SDK | harmless in the emulator; it is not a production connection |

## Never do this

- `firebase firestore:delete "collection" --shallow --force`, `--all-collections`
  or `firestore:bulkdelete` — see
  [`INCIDENT_sleepplans-delete.md`](INCIDENT_sleepplans-delete.md).
- `flutterfire configure` — creates apps and rewrites platform config.
- Any write, delete or deploy against `sleep-optimizer-59c83` by an agent.
- Weakening a rule so that legacy documents stay readable. Backfill instead.
- Committing a key file, or pasting one into chat or a log.

Production rollout stays human: review the diff, run the backfill dry-run and
apply with reviewed tooling, deploy indexes and rules with `-P prod`, release
the matching app build, then verify on a **dev** project. See
[`ENVIRONMENTS.md`](ENVIRONMENTS.md).
