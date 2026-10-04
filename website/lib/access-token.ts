// Checks a Cloudflare Access token (Cf-Access-Jwt-Assertion) with Web Crypto, which Workers and Node both have.

type Jwk = JsonWebKey & { kid?: string };

const bytes = (b64url: string) => {
  const b64 = b64url.replace(/-/g, '+').replace(/_/g, '/');
  return Uint8Array.from(atob(b64 + '='.repeat((4 - (b64.length % 4)) % 4)), c => c.charCodeAt(0));
};
const json = (b64url: string) => JSON.parse(new TextDecoder().decode(bytes(b64url)));

// An RS256 token signed by one of Access's keys, for this application, from this team, not expired, for the owner.
export async function verifyAccessToken(token: string, keys: Jwk[], expect: { aud: string; iss: string; email: string }, now = Date.now() / 1000) {
  const [h, p, sig] = token.split('.');
  if (!h || !p || !sig) return false;
  const header = json(h), claims = json(p);
  const jwk = keys.find(k => k.kid === header.kid);
  if (header.alg !== 'RS256' || !jwk) return false;
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const signed = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, bytes(sig), new TextEncoder().encode(`${h}.${p}`));
  const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
  return signed && audiences.includes(expect.aud) && claims.iss === expect.iss && claims.exp > now
    && String(claims.email ?? '').toLowerCase() === expect.email.toLowerCase();
}
