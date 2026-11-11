#!/usr/bin/env node

/**
 * Backfill `userId` on /recommendations documents written before the field
 * existed.
 *
 * Recommendations are owner-scoped: firestore.rules only lets a user read a
 * document whose `userId` equals their auth uid. Legacy documents have no
 * `userId`, so they are unreadable (on purpose — there is no rules fallback).
 * This script copies the owner from the parent `sqiRecords/{recordId}` document.
 *
 * Safety:
 *   - Every run must name its project explicitly: --project=<id>.
 *   - The production project is refused outright; production is a human step
 *     performed outside this repository (see docs/ENVIRONMENTS.md).
 *   - Dry-run is the default. Nothing is written unless --apply is passed.
 *   - Output contains counts only: no UIDs, record IDs, or recommendation text.
 *   - Admin SDK bypasses security rules, so stray documents stay visible as
 *     counts and are never printed.
 *
 * Prerequisites (already installed in this directory):
 *   cd scripts && npm install
 *
 * Emulator (fully offline, no credentials):
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
 *     node backfill_recommendation_owner.js --project=demo-snoozemate --apply
 *
 * Real dev project (human, credentials via ADC):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/dev-service-account.json \
 *     node backfill_recommendation_owner.js --project=sleep-optimizer-dev
 *   # review the dry-run counts, then repeat with --apply
 */

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { FieldPath, getFirestore } = require('firebase-admin/firestore');

const PROD_PROJECT_ID = 'sleep-optimizer-59c83';
const PAGE_SIZE = 200;
const BATCH_SIZE = 400;

function usage() {
  console.log(
    [
      'Usage: node backfill_recommendation_owner.js --project=<project-id> [--apply]',
      '',
      '  --project=<id>  Target project (required). Production is refused.',
      '  --apply         Write the backfill. Without it the run is a dry-run.',
      '',
      'Set FIRESTORE_EMULATOR_HOST to target the local emulator.',
    ].join('\n'),
  );
}

function parseArgs(argv) {
  const projectArg = argv.find((arg) => arg.startsWith('--project='));
  return {
    projectId: projectArg ? projectArg.slice('--project='.length).trim() : '',
    apply: argv.includes('--apply'),
    help: argv.includes('--help') || argv.includes('-h'),
  };
}

async function collectOwner(recommendation, db, ownerCache) {
  const recordId = typeof recommendation.recordId === 'string'
    ? recommendation.recordId
    : '';

  if (!recordId) {
    return { status: 'unresolved' };
  }

  if (!ownerCache.has(recordId)) {
    const parent = await db.collection('sqiRecords').doc(recordId).get();
    ownerCache.set(recordId, parent.exists ? parent.get('userId') : null);
  }

  const owner = ownerCache.get(recordId);
  return typeof owner === 'string' && owner.length > 0
    ? { status: 'resolved', owner }
    : { status: 'unresolved' };
}

async function main() {
  const { projectId, apply, help } = parseArgs(process.argv.slice(2));

  if (help) {
    usage();
    return;
  }
  if (!projectId) {
    console.error('Refusing to run: --project=<id> is required.\n');
    usage();
    process.exitCode = 1;
    return;
  }
  if (projectId === PROD_PROJECT_ID) {
    console.error(
      'Refusing to run against production. This project is read-only for agents; ' +
        'the production backfill is a human step (docs/ENVIRONMENTS.md).',
    );
    process.exitCode = 1;
    return;
  }

  const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
  const appOptions = { projectId };
  if (!emulatorHost) {
    appOptions.credential = applicationDefault();
  }
  initializeApp(appOptions);
  const db = getFirestore();

  console.log(`Target project: ${projectId}`);
  console.log(
    emulatorHost ? `Emulator: ${emulatorHost}` : 'Live project (credentials from ADC)',
  );
  console.log(apply ? 'Mode: APPLY (documents will be written)' : 'Mode: DRY-RUN (no writes)');
  console.log('');

  const stats = {
    scanned: 0,
    alreadyOwned: 0,
    missingOwner: 0,
    resolvable: 0,
    unresolved: 0,
    updated: 0,
  };

  const ownerCache = new Map();
  let pending = [];
  let cursor = null;
  let more = true;

  const flush = async () => {
    if (pending.length === 0) return;
    if (apply) {
      let batch = db.batch();
      let inBatch = 0;
      for (const item of pending) {
        batch.update(item.ref, { userId: item.owner });
        inBatch += 1;
        if (inBatch === BATCH_SIZE) {
          await batch.commit();
          stats.updated += inBatch;
          console.log(`  ... ${stats.updated} documents updated`);
          batch = db.batch();
          inBatch = 0;
        }
      }
      if (inBatch > 0) {
        await batch.commit();
        stats.updated += inBatch;
        console.log(`  ... ${stats.updated} documents updated`);
      }
    } else {
      stats.updated += pending.length;
    }
    pending = [];
  };

  while (more) {
    let query = db
      .collection('recommendations')
      .orderBy(FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (cursor) query = query.startAfter(cursor);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const doc of snapshot.docs) {
      stats.scanned += 1;
      const data = doc.data() || {};
      const existing = data.userId;

      if (typeof existing === 'string' && existing.length > 0) {
        stats.alreadyOwned += 1;
        continue;
      }

      stats.missingOwner += 1;
      const result = await collectOwner(data, db, ownerCache);

      if (result.status === 'unresolved') {
        stats.unresolved += 1;
        continue;
      }

      stats.resolvable += 1;
      pending.push({ ref: doc.ref, owner: result.owner });
    }

    cursor = snapshot.docs[snapshot.docs.length - 1];
    more = snapshot.size === PAGE_SIZE;
    await flush();
    ownerCache.clear();
  }

  console.log('');
  console.log('Summary');
  console.log(`  scanned:            ${stats.scanned}`);
  console.log(`  already owned:      ${stats.alreadyOwned}`);
  console.log(`  missing owner:      ${stats.missingOwner}`);
  console.log(`  resolvable from parent: ${stats.resolvable}`);
  console.log(`  unresolved (no parent owner): ${stats.unresolved}`);
  console.log(
    apply
      ? `  updated:            ${stats.updated}`
      : `  would update:       ${stats.updated} (dry-run)`,
  );

  if (!apply && stats.resolvable > 0) {
    console.log('\nRe-run with --apply to write these changes.');
  }
}

main().catch((error) => {
  console.error('Backfill failed:', error.message);
  console.error('No credentials are printed. Check ADC / emulator host and retry.');
  process.exitCode = 1;
});
