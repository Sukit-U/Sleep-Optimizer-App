# Firestore security-rules tests

Runs `../firestore.rules` against the real Firestore emulator using
`@firebase/rules-unit-testing`, covering exactly what the app writes:

- **sqiRecords** — the lowercase `sleepQualityLevel` values the app persists,
  ownership on create/read/delete, unowned queries, invalid payloads
- **recommendations** — `userId` (copied from the parent SQI record) is stored
  on the document, so reads, lists and queries are owner-only: another user's
  direct read, an unowned query, and an unfiltered collection query all fail.
  Writes must match both the owner and the parent record. Legacy documents
  without `userId` are unreadable by design (see
  `../scripts/backfill_recommendation_owner.js`)
- **settings** — `userId == docId == auth.uid`, theme enum, no deletes
- **sleepPlans** — ownership plus schema validation
- **default deny** for unknown collections

## Run

```bash
npm install
npm test
```

`npm test` starts the Firestore emulator via `firebase emulators:exec`, runs
the suite inside it, and shuts the emulator down. The Firestore emulator needs
Java 11+ (firebase-tools needs 21+); if `JAVA_HOME` is not set, the runner
defaults to the JDK bundled with Android Studio
(`C:\Program Files\Android\Android Studio\jbr`) — set `JAVA_HOME` to override.

The tests load `../firestore.rules` directly — no deployment needed — so any
rule change is validated in seconds before `firebase deploy --only firestore:rules`.

Everything here runs against the emulator only. There is deliberately no committed
script that talks to a live project: production is read-only for agents, and checking
deployed rules against `sleep-optimizer-59c83` is a human step (see
[`../docs/ENVIRONMENTS.md`](../docs/ENVIRONMENTS.md)).

The Flutter app can join the same emulators for a full local loop:

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=USE_FIREBASE_EMULATOR=true
```

(Debug builds only; Firestore 8080, Auth 9099. Note `firestore.indexes.json`
only applies to the deployed database — the emulator resolves the app's
`where(userId) + orderBy(createdAt)` queries without it.)
