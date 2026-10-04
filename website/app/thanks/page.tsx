import type { Metadata } from 'next';
import { Char, Heart, SvgDefs } from '@/components/Char';
import { KeyBox } from './KeyBox';

export const metadata: Metadata = { title: 'Thank you ♡ OurNotch', robots: { index: false } };

// Where Dodo's checkout lands: three steps, one big button each (devpost/spec-m2.md > Website Pages).
export default async function Thanks({ searchParams }: { searchParams: Promise<{ license_key?: string }> }) {
  const key = (await searchParams).license_key?.split(',')[0]?.trim() || null;
  return (
    <>
      <SvgDefs />
      <nav className="y-nav">
        <div className="y-wrap">
          <a className="y-logo" href="/"><span className="y-logo-notch"><Heart /></span>OurNotch</a>
        </div>
      </nav>

      <main className="y-wrap t-page">
        <div className="t-head">
          <div className="t-chars" aria-hidden="true"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /></div>
          <span className="y-kicker">Thank you</span>
          <h1>Your gift is ready.</h1>
          <p>Three little steps and the first heart is on its way.</p>
        </div>

        <ol className="t-steps">
          <li className="y-blk y-butter">
            <span className="t-n">1</span>
            <div><h2>Download OurNotch</h2><p>Open the download and drag OurNotch into Applications.</p></div>
            <a className="y-btn" href="/download">Download</a>
          </li>
          <li className="y-blk y-blush">
            <span className="t-n">2</span>
            <div><h2>Open OurNotch</h2><p>It switches itself on with your licence. Nothing to type.</p></div>
            {key
              ? <a className="y-btn" href={`ournotch://activate?key=${encodeURIComponent(key)}`}><Heart />Open OurNotch</a>
              : <p className="t-note">Your licence key is in your receipt email. Paste it in OurNotch under <b>I Have a Licence Key</b>.</p>}
          </li>
          <li className="y-blk y-sky">
            <span className="t-n">3</span>
            <div>
              <h2>Invite your love</h2>
              <p>OurNotch writes a little surprise email with a six-letter code. They download it free, type the code, and you&apos;re together. The code lasts 24 hours.</p>
            </div>
          </li>
        </ol>

        {key && <KeyBox licenceKey={key} />}
        <p className="t-help">Something not working? Your key works on one Mac at a time: yours. Write to us at <a className="y-link" href="mailto:hello@ournotch.app">hello@ournotch.app</a>.</p>
      </main>
    </>
  );
}
