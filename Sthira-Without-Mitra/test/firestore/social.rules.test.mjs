import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, runTransaction,
  arrayUnion, arrayRemove, serverTimestamp, collection, query, where, getDocs } from 'firebase/firestore';
const A = 'aaaaaaaaaaaaaaaaaaaa';
const B = 'bbbbbbbbbbbbbbbbbbbb';
const C = 'cccccccccccccccccccc';
let environment;
before(async () => {
  environment = await initializeTestEnvironment({projectId: 'demo-sthira-social',
    firestore: {rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8')}});
});
after(async () => { await environment?.cleanup(); });
beforeEach(async () => {
  await environment.clearFirestore();
  // Published accounts can receive shared-ID invitations; no public directory.
  await environment.withSecurityRulesDisabled(async context => {
    for (const uid of [A, B, C]) {
      await setDoc(doc(context.firestore(), `social_profiles/${uid}`), {uid, name: uid});
    }
  });
});
const db = uid => environment.authenticatedContext(uid).firestore();
const request = (store, target, from) => doc(store, `friend_requests/${target}/requests/${from}`);
const profile = (store, uid) => doc(store, `social_profiles/${uid}`);
const send = (from, to, id = 'request-1') => setDoc(request(db(from), to, from), {
  kind: 'request', requestId: id, fromUid: from, fromName: from,
  fromAvatar: null, sentAt: serverTimestamp(), accepted: false,
});
async function accept(target, from) {
  const store = db(target);
  return runTransaction(store, async tx => {
    const incoming = (await tx.get(request(store, target, from))).data();
    if (!incoming || incoming.kind === 'acceptance') throw new Error('request-changed');
    const id = incoming.requestId ?? 'migrated-request';
    tx.set(profile(store, target), {uid: target, allowedReaders: arrayUnion(from)}, {merge: true});
    tx.update(request(store, target, from), {kind: 'request', requestId: id,
      accepted: true, acceptedAt: serverTimestamp()});
    tx.set(request(store, from, target), {kind: 'acceptance', requestId: id,
      fromUid: target, accepted: true, acceptedAt: serverTimestamp()});
  });
}
async function acknowledge(owner, friend, expectedId = 'request-1') {
  const store = db(owner);
  return runTransaction(store, async tx => {
    const marker = (await tx.get(request(store, owner, friend))).data();
    const source = (await tx.get(request(store, friend, owner))).data();
    if (marker?.kind !== 'acceptance' || source?.kind !== 'request' ||
        !marker.accepted || !source.accepted || marker.requestId !== source.requestId ||
        marker.requestId !== expectedId) return false;
    tx.set(profile(store, owner), {uid: owner, allowedReaders: arrayUnion(friend)}, {merge: true});
    tx.delete(request(store, owner, friend));
    return true;
  });
}
async function remove(owner, friend) {
  const store = db(owner), batch = writeBatch(store);
  batch.set(profile(store, owner), {uid: owner, allowedReaders: arrayRemove(friend)}, {merge: true});
  batch.delete(request(store, owner, friend));
  batch.delete(request(store, friend, owner));
  await batch.commit();
}
const grants = async uid => (await getDoc(profile(db(uid), uid))).data()?.allowedReaders ?? [];

test('one-way request creates role-specific acknowledgement and durable roster', async () => {
  await assertSucceeds(send(A, B));
  await assertSucceeds(accept(B, A));
  assert.deepEqual(await grants(B), [A]);
  assert.equal(await acknowledge(A, B), true);
  assert.deepEqual(await grants(A), [B]);
  const pending = await getDocs(query(collection(db(B), `friend_requests/${B}/requests`),
    where('kind', '==', 'acceptance'), where('accepted', '==', true)));
  assert.equal(pending.size, 0, 'accepted original must not be replayed as an acknowledgement');
});
test('reciprocal pending requests can be accepted atomically', async () => {
  await send(A, B); await send(B, A, 'reverse-request');
  await assertSucceeds(accept(B, A));
  assert.equal(await acknowledge(A, B), true);
  assert.deepEqual(await grants(A), [B]);
});
test('duplicate acceptance is idempotent while the request still exists', async () => {
  await send(A, B); await accept(B, A); await assertSucceeds(accept(B, A));
  assert.deepEqual(await grants(B), [A]);
  assert.equal(await acknowledge(A, B), true);
});
test('removal before acknowledgement revokes access and wins over stale markers', async () => {
  await send(A, B); await accept(B, A);
  await assertSucceeds(getDoc(profile(db(A), B)));
  await remove(B, A);
  await assertFails(getDoc(profile(db(A), B)));
  assert.equal(await acknowledge(A, B), false);
  assert.deepEqual(await grants(B), []);
  await assert.rejects(accept(B, A), /request-changed/);
  await assertFails(setDoc(request(db(B), A, B), {
    kind: 'acceptance', requestId: 'request-1', fromUid: B, accepted: true,
    acceptedAt: serverTimestamp(),
  }));
});
test('decline then resend accepts only the fresh request identity', async () => {
  await send(A, B); await deleteDoc(request(db(B), B, A));
  await send(A, B, 'request-2'); await accept(B, A);
  assert.equal(await acknowledge(A, B, 'request-1'), false);
  assert.equal(await acknowledge(A, B, 'request-2'), true);
});
test('third parties cannot read or accept requests', async () => {
  await send(A, B);
  await assertFails(getDoc(request(db(C), B, A)));
  await assertFails(updateDoc(request(db(C), B, A), {accepted: true}));
});
test('forged acknowledgements need a matching accepted original', async () => {
  await send(A, B);
  const forged = {kind: 'acceptance', requestId: 'request-1', fromUid: B,
    accepted: true, acceptedAt: serverTimestamp()};
  await assertFails(setDoc(request(db(B), A, B), forged));
  await accept(B, A);
  await assertFails(setDoc(request(db(B), A, B), {...forged, requestId: 'wrong'}));
});
test('acceptance cannot alter sender identity or request identity', async () => {
  await send(A, B);
  await assertFails(updateDoc(request(db(B), B, A), {accepted: true, fromName: 'forged'}));
  await assertFails(updateDoc(request(db(B), B, A), {accepted: true, requestId: 'forged'}));
});
test('pending legacy requests can be explicitly accepted with the new roles', async () => {
  await environment.withSecurityRulesDisabled(async context => {
    await setDoc(request(context.firestore(), B, A), {fromUid: A, fromName: 'A', accepted: false});
  });
  await assertSucceeds(accept(B, A));
  assert.equal(await acknowledge(A, B, 'migrated-request'), true);
});
test('profile updates without access fields cannot undo revocation', async () => {
  await send(A, B); await accept(B, A); await remove(B, A);
  await setDoc(profile(db(B), B), {uid: B, name: 'B', todayScore: 70}, {merge: true});
  assert.deepEqual(await grants(B), []);
  await assertFails(getDoc(profile(db(A), B)));
});
test('self requests and forged sender payloads are rejected', async () => {
  await assertFails(send(A, A));
  await assertFails(setDoc(request(db(A), B, A), {kind: 'request', requestId: 'id',
    fromUid: C, accepted: false}));
});

test('pending retries keep their request identity', async () => {
  await send(A, B);
  await assertSucceeds(send(A, B));
  await assertFails(send(A, B, 'replacement-id'));
  assert.equal((await getDoc(request(db(A), B, A))).data().requestId, 'request-1');
});

test('senders cannot reset an accepted request or acknowledgement to pending', async () => {
  await send(A, B); await accept(B, A);
  await assertFails(send(A, B, 'replacement-original'));
  await assertFails(send(B, A, 'replacement-marker'));
  assert.equal((await getDoc(request(db(A), B, A))).data().accepted, true);
  assert.equal((await getDoc(request(db(B), A, B))).data().kind, 'acceptance');
  assert.equal(await acknowledge(A, B), true);
});

test('new invitations reject malformed metadata and unrecognized fields', async () => {
  const valid = {kind: 'request', requestId: 'request-1', fromUid: A,
    fromName: 'A', fromAvatar: null, sentAt: serverTimestamp(), accepted: false};
  const invalid = [
    {fromName: {name: 'A'}},
    {fromName: 'A'.repeat(121)},
    {fromAvatar: ['avatar']},
    {fromAvatar: 'a'.repeat(2049)},
    {sentAt: 'yesterday'},
    {accepted: 0},
    {requestId: ''},
    {requestId: 'a'.repeat(129)},
    {extra: 'unrecognized'},
  ];
  for (const fields of invalid) {
    await assertFails(setDoc(request(db(A), B, A), {...valid, ...fields}));
  }
  const {sentAt, ...missingTime} = valid;
  await assertFails(setDoc(request(db(A), B, A), missingTime));
  await assertSucceeds(setDoc(request(db(A), B, A), {
    ...valid, fromName: 'A'.repeat(120), fromAvatar: 'a'.repeat(2048),
  }));
});

test('acceptance timestamps must be timestamps', async () => {
  await send(A, B);
  await assertFails(updateDoc(request(db(B), B, A), {
    accepted: true, acceptedAt: 'today',
  }));
  await accept(B, A);
  await assertFails(setDoc(request(db(B), A, B), {
    kind: 'acceptance', requestId: 'request-1', fromUid: B,
    accepted: true, acceptedAt: 42,
  }));
});

test('legacy pending senders can upgrade once without replacing a modern identity', async () => {
  await environment.withSecurityRulesDisabled(async context => {
    await setDoc(request(context.firestore(), B, A), {
      fromUid: A, fromName: 'A', accepted: false,
    });
  });
  await assertSucceeds(send(A, B, 'upgraded-request'));
  await assertFails(send(A, B, 'replaced-upgrade'));
  await assertSucceeds(accept(B, A));
  assert.equal(await acknowledge(A, B, 'upgraded-request'), true);
});

test('anonymous and nonparticipant writes cannot forge or delete invitations', async () => {
  const anonymous = environment.unauthenticatedContext().firestore();
  await send(A, B);
  await assertFails(getDoc(request(anonymous, B, A)));
  await assertFails(deleteDoc(request(anonymous, B, A)));
  await assertFails(deleteDoc(request(db(C), B, A)));
  await assertFails(setDoc(request(db(C), B, A), {
    kind: 'request', requestId: 'request-1', fromUid: A, fromName: 'A',
    fromAvatar: null, sentAt: serverTimestamp(), accepted: false,
  }));
  await assertSucceeds(deleteDoc(request(db(A), B, A)));
});

test('daily stats and their coverage metadata remain private until explicitly shared', async () => {
  const stats = {uid: B, name: 'B', todaySteps: 0, todayScore: 42,
    statsDate: '2026-09-19', weekStartDate: '2026-09-14',
    hasStepsRecord: true, weeklyStepsRecordedDays: 2, weekScoreRecordedDays: 3,
    allowedReaders: []};
  await assertSucceeds(setDoc(profile(db(B), B), stats));
  await assertSucceeds(getDoc(profile(db(B), B)));
  await assertFails(getDoc(profile(environment.unauthenticatedContext().firestore(), B)));
  await assertFails(getDoc(profile(db(A), B)));
  await assertFails(getDocs(collection(db(A), 'social_profiles')));
  await send(A, B);
  await assertFails(getDoc(profile(db(A), B)), 'an invitation alone is not a sharing grant');
  await accept(B, A);
  const shared = await assertSucceeds(getDoc(profile(db(A), B)));
  assert.equal(shared.data().hasStepsRecord, true);
  assert.equal(shared.data().weeklyStepsRecordedDays, 2);
  await assertFails(getDoc(profile(db(C), B)));
  await assertFails(updateDoc(profile(db(A), B), {todayScore: 100}));
  await assertFails(updateDoc(profile(db(A), B), {allowedReaders: arrayUnion(C)}));
  await remove(B, A);
  await assertFails(getDoc(profile(db(A), B)));
  await assertSucceeds(setDoc(profile(db(B), B), {
    ...stats, weekScoreRecordedDays: 4,
  }, {merge: true}));
  await assertFails(getDoc(profile(db(A), B)));
});

test('declining an invitation never creates profile access', async () => {
  await setDoc(profile(db(B), B), {uid: B, name: 'B', todaySteps: 100});
  await send(A, B);
  await deleteDoc(request(db(B), B, A));
  await assertFails(getDoc(profile(db(A), B)));
  assert.deepEqual(await grants(B), []);
});

test('new requests require an available private target profile', async () => {
  await deleteDoc(profile(db(B), B));
  await assertFails(send(A, B));
  await assertFails(getDoc(profile(db(A), B)));
  await setDoc(profile(db(B), B), {uid: B, name: 'B'});
  await assertSucceeds(send(A, B));
  await assertFails(getDoc(profile(db(A), B)), 'availability does not grant a profile read');
});

test('profile availability does not block an existing request or acknowledgement', async () => {
  await send(A, B);
  await deleteDoc(profile(db(B), B));
  await assertSucceeds(send(A, B));
  await deleteDoc(profile(db(A), A));
  await assertSucceeds(accept(B, A));
  assert.equal(await acknowledge(A, B), true);
  assert.deepEqual(await grants(A), [B]);
  assert.deepEqual(await grants(B), [A]);
});
