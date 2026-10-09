// The /admin token check. Run: node website/lib/admin.test.mjs
import assert from 'node:assert/strict';
import { verifyAccessToken } from './access-token.ts';

const b64url = buf => Buffer.from(buf).toString('base64url');
const { publicKey, privateKey } = await crypto.subtle.generateKey(
  { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' }, true, ['sign', 'verify']);
const jwk = { ...(await crypto.subtle.exportKey('jwk', publicKey)), kid: 'k1' };
const expect = { aud: 'aud-123', iss: 'https://ournotch.cloudflareaccess.com', email: 'owner@example.com' };

async function token(claims, kid = 'k1', key = privateKey) {
  const h = b64url(JSON.stringify({ alg: 'RS256', kid })), p = b64url(JSON.stringify(claims));
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${h}.${p}`));
  return `${h}.${p}.${b64url(sig)}`;
}
const good = { aud: ['aud-123'], iss: expect.iss, email: 'Owner@example.com', exp: Date.now() / 1000 + 60 };

assert.equal(await verifyAccessToken(await token(good), [jwk], expect), true, 'the owner, signed by Access');
assert.equal(await verifyAccessToken(await token({ ...good, email: 'someone@else.com' }), [jwk], expect), false, 'someone else');
assert.equal(await verifyAccessToken(await token({ ...good, aud: ['other-app'] }), [jwk], expect), false, 'another Access app');
assert.equal(await verifyAccessToken(await token({ ...good, iss: 'https://evil.cloudflareaccess.com' }), [jwk], expect), false, 'another team');
assert.equal(await verifyAccessToken(await token({ ...good, exp: Date.now() / 1000 - 1 }), [jwk], expect), false, 'expired');
assert.equal(await verifyAccessToken(await token(good, 'unknown'), [jwk], expect), false, 'unknown key');
const forger = (await crypto.subtle.generateKey({ name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' }, true, ['sign'])).privateKey;
assert.equal(await verifyAccessToken(await token(good, 'k1', forger), [jwk], expect), false, 'forged signature');
const [h, , s] = (await token(good)).split('.');
assert.equal(await verifyAccessToken(`${h}.${b64url(JSON.stringify({ ...good, email: 'x@y.z' }))}.${s}`, [jwk], expect), false, 'tampered claims');
assert.equal(await verifyAccessToken('not-a-token', [jwk], expect), false, 'garbage');
console.log('admin token check: 9 cases pass');
