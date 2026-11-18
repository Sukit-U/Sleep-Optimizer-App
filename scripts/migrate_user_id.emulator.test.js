/**
 * Integration test for migrate_user_id.js against the Firestore emulator.
 *
 * It proves the fix for the audit finding: moving sqiRecords.userId must also
 * move the userId of every recommendation that belongs to those records.
 *
 * Run (never against a real project):
 *   cd scripts
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
 *     npx firebase emulators:exec --only firestore --project demo-audit-fixes \
 *     "node --test migrate_user_id.emulator.test.js"
 *
 * Without FIRESTORE_EMULATOR_HOST the test is skipped, so `npm test` stays
 * dependency-free.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
const projectId = 'demo-audit-fixes';
const from = 'local-user';
const to = 'default_user';
const runId = `run-${Date.now()}`;

test(
  'migration moves the owner of child recommendations with their record',
  { skip: !emulatorHost && 'FIRESTORE_EMULATOR_HOST is not set' },
  async () => {
    const { initializeApp } = require('firebase-admin/app');
    const { getFirestore } = require('firebase-admin/firestore');

    initializeApp({ projectId });
    const db = getFirestore();

    const migratedRecord = `sqi-${runId}`;
    const otherRecord = `sqi-other-${runId}`;

    await db.collection('sqiRecords').doc(migratedRecord).set({ userId: from });
    await db.collection('sqiRecords').doc(otherRecord).set({ userId: 'someone-else' });

    await db
      .collection('recommendations')
      .doc(`rec-a-${runId}`)
      .set({ userId: from, recordId: migratedRecord });
    await db
      .collection('recommendations')
      .doc(`rec-b-${runId}`)
      .set({ userId: from, recordId: otherRecord });
    await db.collection('recommendations').doc(`rec-legacy-${runId}`).set({ userId: from });

    const result = spawnSync(
      process.execPath,
      [path.join(__dirname, 'migrate_user_id.js'), `--project=${projectId}`, `--from=${from}`, `--to=${to}`, '--apply'],
      { env: { ...process.env, FIRESTORE_EMULATOR_HOST: emulatorHost }, encoding: 'utf8' },
    );
    assert.equal(result.status, 0, result.stderr);

    const migratedRecordDoc = await db.collection('sqiRecords').doc(migratedRecord).get();
    assert.equal(migratedRecordDoc.get('userId'), to);

    const cascaded = await db.collection('recommendations').doc(`rec-a-${runId}`).get();
    assert.equal(cascaded.get('userId'), to, 'recommendation of a migrated record must move with it');

    const untouched = await db.collection('recommendations').doc(`rec-b-${runId}`).get();
    assert.equal(untouched.get('userId'), from, 'recommendation of another owner must not move');

    // No recommendation may point at a migrated record while keeping the old owner.
    const orphans = await db
      .collection('recommendations')
      .where('recordId', '==', migratedRecord)
      .where('userId', '==', from)
      .get();
    assert.equal(orphans.size, 0);
  },
);
