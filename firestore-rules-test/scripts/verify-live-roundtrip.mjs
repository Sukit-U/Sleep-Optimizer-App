// Reads production Firestore through the LIVE security rules, as a brand-new
// anonymous user — exactly what the Firebase client SDK does on device.
// Proves the records written by the app's SQI flow persisted and are served
// under the deployed rules (and only the owner's are).
const API_KEY = 'AIzaSyAsuQd3yRFW3s1wfOnZVzNFuSH5-5r6Xhc';
const PROJECT = 'sleep-optimizer-59c83';

const signUp = await fetch(
  `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
  { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' },
);
const { idToken, localId } = await signUp.json();
if (!idToken) {
  console.error('signUp failed:', await signUp.text());
  process.exit(1);
}
console.log('new anonymous uid:', localId);

const runQuery = async (structQuery) => {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
      body: JSON.stringify({ structuredQuery: structQuery }),
    },
  );
  const body = await res.json();
  if (!res.ok || body.some?.((d) => d.error)) {
    console.error('query failed:', JSON.stringify(body).slice(0, 500));
    process.exit(1);
  }
  return body.filter((d) => d.document);
};

// 1) My own (empty) sqiRecords query — should succeed via composite index.
const mine = await runQuery({
  from: [{ collectionId: 'sqiRecords' }],
  where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: { stringValue: localId } } },
  orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
});
console.log('my sqiRecords:', mine.length, '(expected 0 — fresh identity)');

// 2) A query for SOMEONE ELSE's records — rules must reject it (server-side).
const others = await fetch(
  `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery`,
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'sqiRecords' }],
        where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: { stringValue: 'S3IXanycEYYsrKyUmH6whxrAybo1' } } },
        orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }],
      },
    }),
  },
);
const othersBody = await others.json();
console.log(
  'query for another user\'s records:',
  others.ok && !othersBody.some?.((d) => d.error) ? 'UNEXPECTEDLY SUCCEEDED' : 'DENIED by live rules (expected)',
);

// 3) Fetch the app's record + its recommendations by direct document GETs.
const sqiList = await fetch(
  `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/sqiRecords?pageSize=5`,
  { headers: { Authorization: `Bearer ${idToken}` } },
);
const sqiBody = await sqiList.json();
console.log('direct list of all sqiRecords:', sqiBody.documents?.length ?? 0, 'docs visible to a fresh identity');
