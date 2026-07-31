// Run: flutter run --target lib/scripts/user_id_migration.dart
//
// This script migrates all sqiRecords with userId == 'local-user'
// to userId == 'default_user', so they appear in HistoryPage.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

Future<void> finish(int exitCode) async {
  if (exitCode == 0) {
    print('✅ Done. You can close this window.');
  } else {
    print('❌ Failed. Check the errors above.');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    await finish(1);
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('sqiRecords');

  // ── 1. Find matching documents ──
  List<QueryDocumentSnapshot> docs;
  try {
    final snapshot = await collection
        .where('userId', isEqualTo: 'local-user')
        .get();
    docs = snapshot.docs;
  } catch (e) {
    print('❌ Firestore query failed: $e');
    print('   If the error mentions a missing index, create it from the link above.');
    await finish(1);
    return;
  }

  if (docs.isEmpty) {
    print('✅ No sqiRecords with userId == "local-user" found. Nothing to migrate.');
    await finish(0);
    return;
  }

  print('Found ${docs.length} sqiRecords with userId == "local-user". Migrating...');

  // ── 2. Batch update (Firestore batches handle up to 500 operations) ──
  int updated = 0;
  WriteBatch batch = firestore.batch();

  try {
    for (final doc in docs) {
      batch.update(doc.reference, {'userId': 'default_user'});
      updated++;

      // Commit every 500 docs and start a new batch
      if (updated % 500 == 0) {
        await batch.commit();
        print('  ... $updated documents updated');
        batch = firestore.batch();
      }
    }

    // Commit remaining
    if (updated % 500 != 0) {
      await batch.commit();
    }
  } catch (e) {
    print('❌ Batch update failed after $updated documents: $e');
    await finish(1);
    return;
  }

  print('✅ Migration complete. $updated sqiRecords updated.');
  print('   Old value: userId == "local-user"');
  print('   New value: userId == "default_user"');
  await finish(0);
}
