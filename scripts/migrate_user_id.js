#!/usr/bin/env node

/**
 * Firestore Migration: Update sqiRecords userId from 'local-user' to 'default_user'
 *
 * Prerequisites:
 *   1. npm install firebase-admin (v12+ required – uses the modular API)
 *   2. Download a service account key from Firebase Console:
 *      Project Settings → Service Accounts → "Generate new private key"
 *   3. Save the JSON file as service-account-key.json in this directory
 *      OR set GOOGLE_APPLICATION_CREDENTIALS env var
 *
 * Usage:
 *   cd scripts
 *   npm install firebase-admin
 *   node migrate_user_id.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');

// Try explicit key file first, then fall back to GOOGLE_APPLICATION_CREDENTIALS
const KEY_FILE = './service-account-key.json';

async function main() {
  // Initialize
  if (fs.existsSync(KEY_FILE)) {
    initializeApp({
      credential: cert(KEY_FILE),
    });
  } else {
    // Falls back to GOOGLE_APPLICATION_CREDENTIALS env var
    initializeApp({
      projectId: 'sleep-optimizer-59c83',
    });
  }

  const db = getFirestore();
  const collection = db.collection('sqiRecords');

  // 1. Query matching documents
  console.log('Querying sqiRecords where userId == "local-user"...');
  const snapshot = await collection
    .where('userId', '==', 'local-user')
    .get();

  if (snapshot.empty) {
    console.log('✅ No sqiRecords with userId == "local-user" found. Nothing to migrate.');
    process.exit(0);
  }

  console.log(`Found ${snapshot.size} sqiRecords to migrate.`);

  // 2. Batch update (max 500 per batch)
  let updated = 0;
  let batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    batch.update(doc.ref, { userId: 'default_user' });
    count++;
    updated++;

    if (count === 500) {
      await batch.commit();
      console.log(`  ... ${updated} documents updated`);
      batch = db.batch();
      count = 0;
    }
  }

  // Commit remaining
  if (count > 0) {
    await batch.commit();
  }

  console.log(`✅ Migration complete. ${updated} sqiRecords updated.`);
  console.log('   Old value: userId == "local-user"');
  console.log('   New value: userId == "default_user"');
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Migration failed:', err.message);
  console.error('   Ensure you have a service account key file or GOOGLE_APPLICATION_CREDENTIALS set.');
  process.exit(1);
});
