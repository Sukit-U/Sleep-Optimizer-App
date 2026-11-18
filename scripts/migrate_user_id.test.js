const test = require('node:test');
const assert = require('node:assert/strict');

const { selectRecommendationsToMigrate } = require('./migrate_user_id');

function rec(id, data) {
  return { id, data: () => data };
}

test('cascades recommendations whose parent record is migrating', () => {
  const selected = selectRecommendationsToMigrate(
    [rec('r1', { recordId: 'sqi-1' }), rec('r2', { recordId: 'sqi-2' })],
    new Set(['sqi-1']),
  );
  assert.deepEqual(
    selected.map((doc) => doc.id),
    ['r1'],
  );
});

test('cascades every matching recommendation so none is orphaned', () => {
  const selected = selectRecommendationsToMigrate(
    [
      rec('r1', { recordId: 'sqi-1' }),
      rec('r2', { recordId: 'sqi-1' }),
      rec('r3', { recordId: 'sqi-1' }),
    ],
    new Set(['sqi-1']),
  );
  assert.equal(selected.length, 3);
});

test('skips a recommendation without a recordId', () => {
  const selected = selectRecommendationsToMigrate(
    [rec('legacy', { userId: 'local-user' })],
    new Set(['sqi-1']),
  );
  assert.equal(selected.length, 0);
});

test('skips a recommendation with a non-string recordId', () => {
  const selected = selectRecommendationsToMigrate(
    [rec('r1', { recordId: 42 }), rec('r2', { recordId: null }), rec('r3', { recordId: { id: 'sqi-1' } })],
    new Set(['sqi-1']),
  );
  assert.equal(selected.length, 0);
});

test('skips a recommendation whose parent record is not migrating', () => {
  const selected = selectRecommendationsToMigrate(
    [rec('r1', { recordId: 'sqi-2' })],
    new Set(['sqi-1']),
  );
  assert.equal(selected.length, 0);
});

test('treats a document without data as unmigrated', () => {
  const selected = selectRecommendationsToMigrate([rec('r1', undefined)], new Set(['sqi-1']));
  assert.equal(selected.length, 0);
});
