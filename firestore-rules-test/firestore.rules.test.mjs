import { readFileSync } from 'node:fs';
import { afterEach, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

// The single source of truth: the same rules file the app deploys.
const RULES = readFileSync(
  new URL('../firestore.rules', import.meta.url),
  'utf8',
);

const ALICE = 'alice-uid-123';
const BOB = 'bob-uid-456';
const NOW = new Date('2026-09-25T22:00:00Z');

let testEnv;

const alice = () => testEnv.authenticatedContext(ALICE).firestore();
const bob = () => testEnv.authenticatedContext(BOB).firestore();
const anon = () => testEnv.unauthenticatedContext().firestore();

// Document factories mirror exactly what the Flutter app writes
// (see lib/features/sleep_quality/presentation/pages/sleep_quality_page.dart,
//  lib/features/sleep_planner/presentation/pages/sleep_planner_page.dart).
const validPlan = (uid) => ({
  userId: uid,
  wakeUpTime: NOW,
  createdAt: NOW,
  sleepCycles: 5,
  suggestedBedtimes: ['10:30 PM', '12:00 AM', '01:30 AM'],
});

const validRecord = (uid) => ({
  userId: uid,
  sqiScore: 73,
  // The app persists SleepQualityLevel enum names, which are lowercase.
  sleepQualityLevel: 'good',
  questionnaireResponses: { 'Sleep duration': 4, Stress: 3, Caffeine: 2 },
  createdAt: NOW,
});

const validRec = (recordId) => ({
  recordId,
  factor: 'Stress',
  title: 'Create a simple wind-down routine',
  description: 'A calm routine can reduce stress and support better sleep.',
  action: 'Try breathing exercises or journaling before bed.',
  priority: 'critical',
  createdAt: NOW,
});

const validSettings = (uid) => ({ userId: uid, theme: 'dark' });

beforeEach(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'rules-test',
    host: '127.0.0.1',
    firestore: { rules: RULES },
  });
  await testEnv.clearFirestore();
});

afterEach(async () => {
  await testEnv.cleanup();
});

describe('sqiRecords', () => {
  it('owner saves a record with the lowercase level the app writes', async () => {
    await assertSucceeds(
      alice().collection('sqiRecords').add(validRecord(ALICE)),
    );
  });

  it('rejects capitalized levels the app never writes', async () => {
    const doc = { ...validRecord(ALICE), sleepQualityLevel: 'Good' };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('rejects saving with someone else’s userId', async () => {
    await assertFails(bob().collection('sqiRecords').add(validRecord(ALICE)));
  });

  it('rejects unauthenticated saves', async () => {
    await assertFails(anon().collection('sqiRecords').add(validRecord(ALICE)));
  });

  it('rejects records missing required fields', async () => {
    const { questionnaireResponses, ...incomplete } = validRecord(ALICE);
    await assertFails(alice().collection('sqiRecords').add(incomplete));
  });

  it('rejects out-of-range sqiScore', async () => {
    const doc = { ...validRecord(ALICE), sqiScore: 101 };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('owner lists their own records', async () => {
    await assertSucceeds(
      assertSucceeds(alice().collection('sqiRecords').add(validRecord(ALICE))),
    );
    await assertSucceeds(
      alice()
        .collection('sqiRecords')
        .where('userId', '==', ALICE)
        .orderBy('createdAt', 'desc')
        .get(),
    );
  });

  it('rejects a query for another user’s records', async () => {
    await assertSucceeds(
      alice().collection('sqiRecords').add(validRecord(ALICE)),
    );
    await assertFails(
      bob()
        .collection('sqiRecords')
        .where('userId', '==', ALICE)
        .orderBy('createdAt', 'desc')
        .get(),
    );
  });

  it("rejects direct reads and deletes of another user's record", async () => {
    const ref = await assertSucceeds(
      alice().collection('sqiRecords').add(validRecord(ALICE)),
    );
    await assertFails(bob().collection('sqiRecords').doc(ref.id).get());
    await assertFails(bob().collection('sqiRecords').doc(ref.id).delete());
    await assertSucceeds(alice().collection('sqiRecords').doc(ref.id).delete());
  });
});

describe('recommendations', () => {
  let recordRef;

  beforeEach(async () => {
    recordRef = await assertSucceeds(
      alice().collection('sqiRecords').add(validRecord(ALICE)),
    );
  });

  it('owner creates a recommendation for their own record', async () => {
    await assertSucceeds(
      alice().collection('recommendations').add(validRec(recordRef.id)),
    );
  });

  it('rejects a recommendation pointing at another user’s record', async () => {
    await assertFails(
      bob().collection('recommendations').add(validRec(recordRef.id)),
    );
  });

  it('rejects a recommendation pointing at a nonexistent record', async () => {
    await assertFails(
      alice().collection('recommendations').add(validRec('no-such-record')),
    );
  });

  // Reads cannot inspect the where('recordId', ...) query parameter, so the
  // deployed rule allows any authenticated read (write paths still enforce
  // parent-record ownership). This test proves reads are not accidentally
  // re-broken by a rule referencing request.resource.data on reads.
  it('authenticated users can read recommendations (deliberate relaxation)', async () => {
    await assertSucceeds(
      alice().collection('recommendations').add(validRec(recordRef.id)),
    );
    await assertSucceeds(
      bob()
        .collection('recommendations')
        .where('recordId', '==', recordRef.id)
        .orderBy('createdAt', 'desc')
        .get(),
    );
  });
});

describe('settings', () => {
  it('owner saves their settings', async () => {
    await assertSucceeds(
      alice().collection('settings').doc(ALICE).set(validSettings(ALICE)),
    );
  });

  it('rejects userId that does not match the document ID', async () => {
    await assertFails(
      alice().collection('settings').doc(ALICE).set(validSettings(BOB)),
    );
  });

  it('rejects writing another user’s settings document', async () => {
    await assertFails(
      bob().collection('settings').doc(ALICE).set(validSettings(ALICE)),
    );
  });

  it('rejects reading another user’s settings', async () => {
    await assertSucceeds(
      alice().collection('settings').doc(ALICE).set(validSettings(ALICE)),
    );
    await assertFails(bob().collection('settings').doc(ALICE).get());
  });

  it('rejects an invalid theme value', async () => {
    await assertFails(
      alice()
        .collection('settings')
        .doc(ALICE)
        .set({ userId: ALICE, theme: 'blue' }),
    );
  });

  it('rejects deletes', async () => {
    await assertSucceeds(
      alice().collection('settings').doc(ALICE).set(validSettings(ALICE)),
    );
    await assertFails(alice().collection('settings').doc(ALICE).delete());
  });
});

describe('sleepPlans', () => {
  it('owner saves a valid plan; others and bad payloads are rejected', async () => {
    await assertSucceeds(alice().collection('sleepPlans').add(validPlan(ALICE)));
    await assertFails(bob().collection('sleepPlans').add(validPlan(ALICE)));
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), sleepCycles: 11 }),
    );
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: [] }),
    );
  });

  it('rejects queries and deletes for another user’s plans', async () => {
    const ref = await assertSucceeds(
      alice().collection('sleepPlans').add(validPlan(ALICE)),
    );
    await assertFails(
      bob()
        .collection('sleepPlans')
        .where('userId', '==', ALICE)
        .orderBy('createdAt', 'desc')
        .get(),
    );
    await assertFails(bob().collection('sleepPlans').doc(ref.id).delete());
  });
});

describe('default deny', () => {
  it('blocks unknown collections', async () => {
    await assertFails(alice().collection('users').doc(ALICE).set({ x: 1 }));
    await assertFails(alice().collection('users').doc(ALICE).get());
  });
});
