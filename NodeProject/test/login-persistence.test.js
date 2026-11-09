import test from 'node:test';
import assert from 'node:assert/strict';
import {Store} from '../src/client.js';
import {Ipa} from '../src/ipa.js';

test('failed session persistence cannot produce a successful login', async t => {
    const steps = [];
    const key = Buffer.alloc(32, 7);
    t.mock.method(Store, 'login', async (email, password, code, previous, sessionKey) => {
        assert.equal(email, 'panghu@example.invalid');
        assert.equal(sessionKey, key.toString('base64'));
        assert.deepEqual(steps, ['clear']);
        steps.push('authenticate');
        return {accountInfo: {address: {firstName: 'panghu'}}};
    });
    const client = {
        creds: {APPLE_ID: 'panghu@example.invalid', PASSWORD: 'panghu-placeholder', CODE: ''},
        sessionEncryptionKey: key,
        user: {old: true},
        auth: {old: true},
        async loadSessionEntry() { return {user: this.user}; },
        async clearSession() { steps.push('clear'); },
        async saveSession() { throw new Error('panghu simulated disk failure'); },
        applyUser() { assert.fail('must not accept an unsaved session'); },
    };
    await assert.rejects(Ipa.prototype.login.call(client, {force: true}), {code: 'SESSION_SAVE_FAILED'});
    assert.equal(client.user, null);
    assert.deepEqual(client.auth, {});
    assert.deepEqual(steps, ['clear', 'authenticate']);
});

test('successful login saves the new helper session before accepting it', async t => {
    const steps = [];
    const user = {accountInfo: {address: {firstName: 'panghu'}}};
    t.mock.method(Store, 'login', async () => user);
    const client = {
        creds: {APPLE_ID: 'panghu@example.invalid', PASSWORD: 'panghu-placeholder', CODE: ''},
        sessionEncryptionKey: Buffer.alloc(32, 7),
        async loadSessionEntry() { return null; },
        async clearSession() {},
        async saveSession(value) { assert.equal(value, user); steps.push('save'); },
        applyUser(value, cached) {
            assert.equal(value, user);
            assert.equal(cached, false);
            assert.deepEqual(steps, ['save']);
            steps.push('accept');
        },
    };
    await Ipa.prototype.login.call(client);
    assert.deepEqual(steps, ['save', 'accept']);
});

test('a bare 403 or helper transport failure does not repeatedly request login', async () => {
    for (const code of ['STORE_HTTP_REJECTED', 'STORE_TIMEOUT']) {
        const error = Object.assign(new Error('HTTP 403 token/session request failed'), {code});
        const client = {
            usedCachedSession: true,
            async login() { assert.fail('must not reauthenticate for unrelated failures'); },
        };
        await assert.rejects(Ipa.prototype._withReauth.call(client, async () => { throw error; }), e => e === error);
    }
});
