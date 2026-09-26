# Firestore security-rules tests

Runs `../firestore.rules` against the real Firestore emulator using
`@firebase/rules-unit-testing`, covering exactly what the app writes:

- **sqiRecords** — the lowercase `sleepQualityLevel` values the app persists,
  ownership on create/read/delete, unowned queries, invalid payloads
- **recommendations** — writes gated on parent-record ownership; reads
  authenticated-only (rules cannot see `where('recordId', …)` parameters)
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

To run the suite directly against an already-running emulator (e.g. started by
`firebase emulators:start` elsewhere):

```bash
npm run test:direct
```

The tests load `../firestore.rules` directly — no deployment needed — so any
rule change is validated in seconds before `firebase deploy --only firestore:rules`.

`scripts/verify-live-roundtrip.mjs` reads **production** Firestore through the
**live** rules as a fresh anonymous identity (REST, same endpoints the SDK
uses) — used to verify per-user isolation after end-to-end app runs.

The Flutter app can join the same emulators for a full local loop:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

(Debug builds only; Firestore 8080, Auth 9099. Note `firestore.indexes.json`
only applies to the deployed database — the emulator resolves the app's
`where(userId) + orderBy(createdAt)` queries without it.)
