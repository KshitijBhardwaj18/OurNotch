import { redirect } from 'next/navigation';
import { headers } from 'next/headers';

// The sold build (live licences). Test couples get the Beta from downloads.ournotch.app/beta/.
const FEED = 'https://downloads.ournotch.app/appcast.xml';
const FALLBACK = 'https://downloads.ournotch.app/OurNotch.dmg';

// The newest DMG, by its versioned name from the update feed (OurNotch-1.0.22.dmg): Cloudflare keeps the plain
// OurNotch.dmg for hours after a release, while a new version's file has never been cached. If the feed can't
// be read, the plain name; if that's missing too, the "Launching" page in the visitor's language.
export async function GET() {
  const feed = await fetch(FEED, { cache: 'no-store', signal: AbortSignal.timeout(3000) }).then(r => (r.ok ? r.text() : ''), () => '');
  const latest = /url="(https:\/\/downloads\.ournotch\.app\/OurNotch-[\d.]+\.dmg)"/.exec(feed)?.[1];
  if (latest) redirect(latest);
  const ready = await fetch(FALLBACK, { method: 'HEAD', signal: AbortSignal.timeout(3000) }).then(r => r.ok, () => false);
  if (ready) redirect(FALLBACK);
  const from = (await headers()).get('referer') ?? '';
  const lang = /\/\/[^/]+\/(fr|de)(\/|$)/.exec(from)?.[1];
  redirect(lang ? `/${lang}/launching` : '/launching');
}
