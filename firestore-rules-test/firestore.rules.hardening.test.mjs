import { readFileSync } from 'node:fs';
import { afterEach, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const RULES = readFileSync(
  new URL('../firestore.rules', import.meta.url),
  'utf8',
);

const ALICE = 'alice-uid-123';
const NOW = new Date('2026-09-25T22:00:00Z');

let testEnv;
const alice = () => testEnv.authenticatedContext(ALICE).firestore();

const validRecord = (uid) => ({
  userId: uid,
  sqiScore: 73,
  sleepQualityLevel: 'good',
  questionnaireResponses: {
    'Sleep duration': 4,
    'Sleep regularity': 3,
    'Screen time': 2,
    Exercise: 5,
    Stress: 1,
    Caffeine: 4,
  },
  createdAt: NOW,
});

const validPlan = (uid) => ({
  userId: uid,
  wakeUpTime: NOW,
  createdAt: NOW,
  sleepCycles: 5,
  suggestedBedtimes: ['10:30 PM', '12:00 AM', '01:30 AM'],
});

beforeEach(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-rules-test',
    host: '127.0.0.1',
    firestore: { rules: RULES },
  });
  await testEnv.clearFirestore();
});

afterEach(async () => {
  await testEnv.cleanup();
});

describe('Category B - questionnaireResponses hardening', () => {
  it('accepts exactly the six expected keys', async () => {
    await assertSucceeds(alice().collection('sqiRecords').add(validRecord(ALICE)));
  });

  it('rejects a missing questionnaire key', async () => {
    const { 'Caffeine': _removed, ...responses } = validRecord(ALICE).questionnaireResponses;
    const doc = { ...validRecord(ALICE), questionnaireResponses: responses };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('rejects an extra questionnaire key', async () => {
    const doc = {
      ...validRecord(ALICE),
      questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Extra: 3 },
    };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('rejects a null questionnaire value', async () => {
    const doc = {
      ...validRecord(ALICE),
      questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: null },
    };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('rejects a wrong questionnaire value type', async () => {
    const doc = {
      ...validRecord(ALICE),
      questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: 'bad' },
    };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('rejects a questionnaire value below 1', async () => {
    const doc = {
      ...validRecord(ALICE),
      questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: 0 },
    };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('rejects a questionnaire value above 5', async () => {
    const doc = {
      ...validRecord(ALICE),
      questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: 6 },
    };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });

  it('accepts questionnaire values 1 and 5', async () => {
    const doc = {
      ...validRecord(ALICE),
      questionnaireResponses: {
        'Sleep duration': 1,
        'Sleep regularity': 5,
        'Screen time': 1,
        Exercise: 5,
        Stress: 1,
        Caffeine: 5,
      },
    };
    await assertSucceeds(alice().collection('sqiRecords').add(doc));
  });

  it('rejects a non-map questionnaireResponses', async () => {
    const doc = { ...validRecord(ALICE), questionnaireResponses: ['bad'] };
    await assertFails(alice().collection('sqiRecords').add(doc));
  });
});

describe('Category B - suggestedBedtimes hardening', () => {
  it('rejects a non-list suggestedBedtimes', async () => {
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: 'bad' }),
    );
  });

  it('rejects a non-string bedtime element', async () => {
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: [42] }),
    );
  });

  it('rejects an empty bedtime string', async () => {
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: [''] }),
    );
  });

  it('rejects a bedtime string longer than 100 characters', async () => {
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: ['x'.repeat(101)] }),
    );
  });

  it('rejects an empty suggestedBedtimes list', async () => {
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: [] }),
    );
  });

  it('accepts one suggestedBedtime item', async () => {
    await assertSucceeds(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: ['10:30 PM'] }),
    );
  });

  it('accepts ten suggestedBedtime items', async () => {
    const bedtimes = Array.from({ length: 10 }, (_, i) => `Bedtime ${i + 1}`);
    await assertSucceeds(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: bedtimes }),
    );
  });

  it('rejects eleven suggestedBedtime items', async () => {
    const bedtimes = Array.from({ length: 11 }, (_, i) => `Bedtime ${i + 1}`);
    await assertFails(
      alice().collection('sleepPlans').add({ ...validPlan(ALICE), suggestedBedtimes: bedtimes }),
    );
  });
});

describe('Category B - questionnaireResponses update hardening', () => {
  it('rejects an update with a missing questionnaire key', async () => {
    const db = alice();
    await db.collection('sqiRecords').doc('sqi-update').set(validRecord(ALICE));
    const { 'Caffeine': _removed, ...responses } = validRecord(ALICE).questionnaireResponses;
    await assertFails(
      db.collection('sqiRecords').doc('sqi-update').update({ questionnaireResponses: responses }),
    );
  });

  it('rejects an update with an extra questionnaire key', async () => {
    const db = alice();
    await db.collection('sqiRecords').doc('sqi-update').set(validRecord(ALICE));
    await assertFails(
      db.collection('sqiRecords').doc('sqi-update').update({
        questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Extra: 3 },
      }),
    );
  });

  it('rejects an update with a null questionnaire value', async () => {
    const db = alice();
    await db.collection('sqiRecords').doc('sqi-update').set(validRecord(ALICE));
    await assertFails(
      db.collection('sqiRecords').doc('sqi-update').update({
        questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: null },
      }),
    );
  });

  it('rejects an update with a wrong questionnaire value type', async () => {
    const db = alice();
    await db.collection('sqiRecords').doc('sqi-update').set(validRecord(ALICE));
    await assertFails(
      db.collection('sqiRecords').doc('sqi-update').update({
        questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: 'bad' },
      }),
    );
  });

  it('rejects an update with a questionnaire value below 1', async () => {
    const db = alice();
    await db.collection('sqiRecords').doc('sqi-update').set(validRecord(ALICE));
    await assertFails(
      db.collection('sqiRecords').doc('sqi-update').update({
        questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: 0 },
      }),
    );
  });

  it('rejects an update with a questionnaire value above 5', async () => {
    const db = alice();
    await db.collection('sqiRecords').doc('sqi-update').set(validRecord(ALICE));
    await assertFails(
      db.collection('sqiRecords').doc('sqi-update').update({
        questionnaireResponses: { ...validRecord(ALICE).questionnaireResponses, Caffeine: 6 },
      }),
    );
  });
});

describe('Category B - suggestedBedtimes update hardening', () => {
  it('rejects an update with a non-string bedtime element', async () => {
    const db = alice();
    await db.collection('sleepPlans').doc('plan-update').set(validPlan(ALICE));
    await assertFails(
      db.collection('sleepPlans').doc('plan-update').update({ suggestedBedtimes: [42] }),
    );
  });

  it('rejects an update with an empty bedtime string', async () => {
    const db = alice();
    await db.collection('sleepPlans').doc('plan-update').set(validPlan(ALICE));
    await assertFails(
      db.collection('sleepPlans').doc('plan-update').update({ suggestedBedtimes: [''] }),
    );
  });

  it('rejects an update with a bedtime string longer than 100 characters', async () => {
    const db = alice();
    await db.collection('sleepPlans').doc('plan-update').set(validPlan(ALICE));
    await assertFails(
      db.collection('sleepPlans').doc('plan-update').update({ suggestedBedtimes: ['x'.repeat(101)] }),
    );
  });
});
