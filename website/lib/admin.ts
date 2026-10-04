import { headers } from 'next/headers';
import { verifyAccessToken } from './access-token';

// Who may open /admin. Locally, the dev server is yours. Live, Cloudflare Access stands in front of /admin
// (owner's email only) and signs each request; we check that signature here too, so a request that slips
// past Access (e.g. through the workers.dev address) gets a 404. Settings come from Wrangler (slice 12):
//   ACCESS_TEAM_DOMAIN  e.g. ournotch.cloudflareaccess.com
//   ACCESS_AUD          the Access application's audience tag
//   ADMIN_EMAIL         the owner's email
export async function adminAllowed(): Promise<boolean> {
  if (process.env.NODE_ENV === 'development') return true;
  const team = process.env.ACCESS_TEAM_DOMAIN, aud = process.env.ACCESS_AUD, email = process.env.ADMIN_EMAIL;
  const token = (await headers()).get('cf-access-jwt-assertion');
  if (!team || !aud || !email || !token) return false;
  const iss = `https://${team}`;
  try {
    const { keys } = await fetch(`${iss}/cdn-cgi/access/certs`).then(r => r.json());
    return await verifyAccessToken(token, keys, { aud, iss, email });
  } catch {
    return false;
  }
}
