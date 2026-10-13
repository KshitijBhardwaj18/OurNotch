'use client';

import { useEffect, useState } from 'react';

// Meta's pixel, to measure our ads: page views and "Try it free" clicks (InitiateCheckout). Where the law needs an
// opt-in (EU/EEA, UK, Switzerland: `ask`, from the visitor's country) it loads only after OK; elsewhere it loads
// unless the visitor opted out (Cookie settings, or the browser's Global Privacy Control).
// ponytail: India's DPDP consent duty phases in through 2027; add IN to ASK_FIRST in Shell.tsx when it applies.
// Never on the thank-you page, whose address holds the licence key,
// and with Meta's automatic button and link scanning off, so a key can't reach Meta from anywhere.
// The pixel ID is public: it's in every page that loads the pixel. Empty = no pixel and no notice.
const PIXEL_ID = '';
const KEY = 'ournotch-ads-consent';

type Choice = 'yes' | 'no' | 'ask' | null; // 'ask': Cookie settings was tapped, show the notice

const read = (): Choice => {
  try { return localStorage.getItem(KEY) as Choice; } catch { return null; }
};
const save = (choice: Choice) => {
  try { choice ? localStorage.setItem(KEY, choice) : localStorage.removeItem(KEY); } catch { /* private window: ask again next time */ }
};

declare global { interface Window { fbq?: (...args: unknown[]) => void; _fbq?: unknown } }

function load() {
  if (window.fbq) return;
  const fbq = ((...args: unknown[]) => { (fbq as unknown as { queue: unknown[] }).queue.push(args); }) as Window['fbq'] & { queue: unknown[]; loaded: boolean; version: string; push: unknown };
  fbq.queue = []; fbq.loaded = true; fbq.version = '2.0'; fbq.push = fbq;
  window.fbq = window._fbq = fbq;
  const script = document.createElement('script');
  script.async = true;
  script.src = 'https://connect.facebook.net/en_US/fbevents.js';
  document.head.appendChild(script);
  fbq('set', 'autoConfig', false, PIXEL_ID);
  fbq('init', PIXEL_ID);
  fbq('track', 'PageView');
  document.addEventListener('click', (e) => {
    if ((e.target as Element | null)?.closest('a[href^="/buy"]')) window.fbq?.('track', 'InitiateCheckout');
  });
}

export function MetaPixel({ t, ask }: { t: { text: string; yes: string; no: string }; ask: boolean }) {
  const [choice, setChoice] = useState<Choice>('no'); // nothing shows until the stored choice is read
  useEffect(() => {
    if (!PIXEL_ID || /\/thanks$/.test(location.pathname)) return;
    const stored = read();
    const gpc = (navigator as Navigator & { globalPrivacyControl?: boolean }).globalPrivacyControl === true;
    const now: Choice = stored ?? (ask ? null : gpc ? 'no' : 'yes');
    setChoice(now);
    if (now === 'yes') load();
  }, [ask]);
  if (!PIXEL_ID || (choice && choice !== 'ask')) return null;
  const choose = (c: 'yes' | 'no') => { save(c); setChoice(c); if (c === 'yes') load(); };
  return (
    <div className="y-consent" role="dialog" aria-label={t.text}>
      <p>{t.text}</p>
      <div>
        <button onClick={() => choose('no')}>{t.no}</button>
        <button className="y-consent-yes" onClick={() => choose('yes')}>{t.yes}</button>
      </div>
    </div>
  );
}

// Footer link: forget the choice and ask again (withdrawing consent must be as easy as giving it).
export function CookieSettings({ label }: { label: string }) {
  if (!PIXEL_ID) return null;
  return <button className="y-foot-btn" onClick={() => { save('ask'); location.reload(); }}>{label}</button>;
}
