import { redirect } from 'next/navigation';
import { headers } from 'next/headers';

// ponytail: checkout is in Dodo's test mode, so /download hands out the Beta build (test-mode licences).
// At launch, `scripts/release.sh` uploads the sold build to the root and this goes back to OurNotch.dmg.
const DMG = process.env.DOWNLOAD_URL ?? 'https://downloads.ournotch.app/beta/OurNotch.dmg';

// The newest DMG, uploaded by scripts/release.sh. If it's missing, visitors get the
// "Launching this week" page in the language of the page they came from, instead of a dead link.
export async function GET() {
  const ready = await fetch(DMG, { method: 'HEAD', signal: AbortSignal.timeout(3000) }).then(r => r.ok, () => false);
  if (ready) redirect(DMG);
  const from = (await headers()).get('referer') ?? '';
  const lang = /\/\/[^/]+\/(fr|de)(\/|$)/.exec(from)?.[1];
  redirect(lang ? `/${lang}/launching` : '/launching');
}
