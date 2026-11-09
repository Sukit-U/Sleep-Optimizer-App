# Incident: `sleepPlans` collection deleted on `sleep-optimizer-59c83`

- **Date:** 2026-11-08
- **Project / database:** `sleep-optimizer-59c83` / `(default)` (Firestore Native, `asia-southeast3`)
- **Severity:** data loss, no recovery available
- **Status:** closed; controls added (see Prevention)

## What happened

While cleaning up the documents created for a `firestore.rules` verification run, an
agent ran a **collection-level** delete against the live project:

```bash
firebase firestore:delete "sleepPlans" --shallow --force --project=sleep-optimizer-59c83
```

The command was intended as a probe of the CLI's behaviour but is a destructive
operation in its own right: it deleted **every document in the `sleepPlans`
collection**, not one document. It was run twice.

Deletion was confirmed afterwards with a controlled, single-document experiment
(create two documents, delete one by path, read both back as the owning user): the
deleted document returned `403`, the other `200` — so the collection-level command
had really removed data, and CLI exit code `0` had been wrongly read as "nothing
matched".

## Impact

- All documents in `sleepPlans` were lost.
- Per the project owner, that collection contained **test data only; no real user
  data existed**. This assessment comes from the owner and was not verifiable from
  the environment used.
- **Not recoverable:** PITR was `POINT_IN_TIME_RECOVERY_DISABLED`, there were no
  backups and no backup schedules, and the project is on a plan without billing, so
  no backup could have existed.

## Other collections

Only `sleepPlans` received a collection-scoped delete; the other commands used
single-document paths (`sqiRecords/…`, `recommendations/…`, `settings/…`), and those
paths were chosen explicitly to delete only test documents. `sqiRecords`,
`recommendations` and `settings` are therefore **expected** to be intact.

**[Unverified]** — this was not confirmed by reading the live data. Confirming it
requires authenticated reads (the rules scope every collection to the owning user),
and no further write/delete/read operations were run against the project for this
document.

## Root cause

1. A destructive, collection-scoped command was run against the **live** project
   instead of a single document path or an emulator.
2. Nothing could undo it: no PITR, no backups, no export.
3. The command was not covered by an explicit, per-command approval for that
   destructive action.
4. `--force` + exit code `0` was treated as success without a read-back check, which
   masked that the first attempt (with an unsupported `-y` flag) had failed and the
   second had deleted data.

## Prevention

Recorded as a hard rule in [`AGENTS.md`](../AGENTS.md#destructive-operations-hard-rule):

- Deletes must name exactly one document (`collection/docId`) — never a bare
  collection path, never `--all-collections`, never `firestore:bulkdelete`.
- No deploys or deletions against production without explicit per-command approval.
- Exit code `0` does not mean "deleted"; confirm with a read as the owning user.
- Test data should be created with a throwaway account and removed the same way it
  was created, or not created at all.

Changes made to the project after the incident:

- Firestore **delete protection enabled** (`DELETE_PROTECTION_ENABLED`) — prevents
  deletion of the whole database.
- Rules verification for future work should run against the Firestore emulator or a
  throwaway project, not the live one.

Still open:

- **PITR and scheduled backups are blocked** — both require billing (Blaze plan) and
  were rejected with `403 This API method requires billing to be enabled`. Once
  billing is enabled, run:
  ```bash
  firebase firestore:databases:update "(default)" \
    --point-in-time-recovery ENABLED --project=sleep-optimizer-59c83
  firebase firestore:backups:schedules:create --database="(default)" \
    --recurrence DAILY --retention 14d --project=sleep-optimizer-59c83
  ```
