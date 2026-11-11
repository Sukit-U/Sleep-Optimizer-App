#!/usr/bin/env node

/**
 * Firestore migration: rewrite sqiRecords.userId from one legacy value to
 * another (defaults: 'local-user' → 'default_user').
 *
 * Changing `userId` moves ownership of a record, so this is deliberately as
 * strict as scripts/backfill_recommendation_owner.js:
 *
 *   - Every run must name its project explicitly: --project=<id>.
 *   - The production project is refused outright. Production is a human step
 *     performed outside this repository (docs/ENVIRONMENTS.md); agents never
 *     write to it.
 *   - Dry-run is the default. Nothing is written unless --apply is passed.
 *   - Credentials come from Application Default Credentials or the emulator;
 *     no service-account key file is read from the repository.
 *   - Output is counts only: no document IDs or per-document values.
 *
 * Prerequisites (already installed in this directory):
 *   cd scripts && npm install
 *
 * Emulator (fully offline, no credentials):
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
 *     node migrate_user_id.js --project=demo-snoozemate --apply
 *
 * Real dev project (human, credentials via ADC):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/dev-service-account.json \
 *     node migrate_user_id.js --project=sleep-optimizer-dev
 *   # review the dry-run counts, then repeat with --apply
 */

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const PROD_PROJECT_ID = 'sleep-optimizer-59c83';
const DEFAULT_FROM = 'local-user';
const DEFAULT_TO = 'default_user';
const BATCH_SIZE = 400;

function usage() {
  console.log(
    [
      'Usage: node migrate_user_id.js --project=<project-id> [--from=<userId>] [--to=<userId>] [--apply]',
      '',
      '  --project=<id>  Target project (required). Production is refused.',
      '  --from=<userId> Current sqiRecords.userId value (default: local-user).',
      '  --to=<userId>   Replacement sqiRecords.userId value (default: default_user).',
      '  --apply         Write the migration. Without it the run is a dry-run.',
      '',
      'Set FIRESTORE_EMULATOR_HOST to target the local emulator.',
    ].join('\n'),
  );
}

function flagValue(argv, name) {
  const prefix = `--${name}=`;
  const match = argv.find((arg) => arg.startsWith(prefix));
  return match ? match.slice(prefix.length).trim() : '';
}

function parseArgs(argv) {
  return {
    projectId: flagValue(argv, 'project'),
    from: flagValue(argv, 'from') || DEFAULT_FROM,
    to: flagValue(argv, 'to') || DEFAULT_TO,
    apply: argv.includes('--apply'),
    help: argv.includes('--help') || argv.includes('-h'),
  };
}

async function main() {
  const { projectId, from, to, apply, help } = parseArgs(process.argv.slice(2));

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
        'the production migration is a human step (docs/ENVIRONMENTS.md).',
    );
    process.exitCode = 1;
    return;
  }
  if (!from || !to) {
    console.error('Refusing to run: --from and --to must both be non-empty.');
    process.exitCode = 1;
    return;
  }
  if (from === to) {
    console.error('Refusing to run: --from and --to are identical.');
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
  console.log(`Owner value: "${from}" -> "${to}"`);
  console.log(apply ? 'Mode: APPLY (documents will be written)' : 'Mode: DRY-RUN (no writes)');
  console.log('');

  const snapshot = await db
    .collection('sqiRecords')
    .where('userId', '==', from)
    .get();

  if (snapshot.empty) {
    console.log('No sqiRecords matched. Nothing to migrate.');
    return;
  }

  console.log(`Matched: ${snapshot.size} sqiRecords`);

  if (!apply) {
    console.log(`Would update: ${snapshot.size} (dry-run — re-run with --apply to write)`);
    return;
  }

  let updated = 0;
  let batch = db.batch();
  let inBatch = 0;

  for (const doc of snapshot.docs) {
    batch.update(doc.ref, { userId: to });
    inBatch += 1;
    if (inBatch === BATCH_SIZE) {
      await batch.commit();
      updated += inBatch;
      console.log(`  ... ${updated} documents updated`);
      batch = db.batch();
      inBatch = 0;
    }
  }

  if (inBatch > 0) {
    await batch.commit();
    updated += inBatch;
    console.log(`  ... ${updated} documents updated`);
  }

  console.log('');
  console.log(`Updated: ${updated}`);
}

main().catch((error) => {
  console.error('Migration failed:', error.message);
  console.error('No credentials are printed. Check ADC / emulator host and retry.');
  process.exitCode = 1;
});
