# scripts/

One-off migrations that run with the Firebase Admin SDK. They are not part of
the app build and are never invoked by `flutter run` or `flutter test`.

## Safety model

Both scripts follow the same rules:

- `--project=<id>` is required on every run. There is no default and
  `.firebaserc` is ignored.
- The production project (`sleep-optimizer-59c83`) is refused before any
  connection is opened. Production changes are a human step; see
  [`../docs/ENVIRONMENTS.md`](../docs/ENVIRONMENTS.md).
- Dry-run is the default. `--apply` is required to write anything.
- Output is counts only: no document IDs, UIDs, emails or tokens.
- Credentials come from Application Default Credentials or
  `FIRESTORE_EMULATOR_HOST`. Neither script reads a key file from this folder.

## Secrets

- Never commit a service-account key. `.gitignore` blocks the common names
  (`service-account-key*.json`, `*-firebase-adminsdk-*.json`,
  `firebase-adminsdk*.json`), but the rule matters more than the pattern.
- Keep the key outside the repository and point
  `GOOGLE_APPLICATION_CREDENTIALS` at it for that shell only.
- Prefer the emulator, which needs no credentials at all, for every test.
- Never paste a key or its contents into chat, an issue, a log, or a file in
  this folder.
- If a key was ever committed, rotate it in the Firebase console. Deleting the
  file does not revoke it.

## backfill_recommendation_owner.js

Copies `userId` from the parent `sqiRecords/{recordId}` onto recommendation
documents written before the owner field existed. Recommendations are
owner-scoped in `firestore.rules`, so documents without `userId` are
unreadable until they are backfilled (there is no rules fallback).

`userId` is copied, never inferred from the caller. A recommendation whose
parent record is missing, or whose parent has no `userId`, is counted as
unresolved and left untouched.

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
  node backfill_recommendation_owner.js --project=demo-snoozemate
# review the counts, then repeat with --apply
```

## migrate_user_id.js

Rewrites `sqiRecords.userId` from one legacy value to another (default
`local-user` → `default_user`) for records created before the app used
anonymous Auth UIDs. This moves record ownership, so it also refuses
production.

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
  node migrate_user_id.js --project=demo-snoozemate --from=local-user --to=default_user
# review the counts, then repeat with --apply
```

Both scripts accept `--help`. Step-by-step instructions, including how to run
the rules tests first, are in
[`../docs/RULES_AND_BACKFILL_DEV.md`](../docs/RULES_AND_BACKFILL_DEV.md).
