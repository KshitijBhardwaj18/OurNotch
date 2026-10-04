import type { CSSProperties } from 'react';
import { headers } from 'next/headers';
import { Char, Heart, SvgDefs } from '@/components/Char';
import { Bento } from '@/components/Bento';
import { HeroDemo } from '@/components/HeroDemo';
import { MadeForTwo } from '@/components/MadeForTwo';
import { Reveal } from '@/components/bits';
import { checkoutUrl, originFrom, priceFor } from '@/lib/prices';

// Hero hearts: [left %, top %, size px, color], around the headline and beside the video. Phones skip them.
const PASTEL = ['#FFD3DC', '#FFE9A6', '#CFE3FF', '#CFEFDF', '#FF8FAB'];
const HEARTS = [
  [6, 6, 30, 0], [91, 9, 36, 1], [4, 24, 20, 4], [93, 27, 22, 3],
  [3, 52, 28, 2], [95, 60, 30, 0], [5, 82, 22, 1], [94, 88, 18, 4],
];

const DETAILS = [
  ['🔐', 'Private', 'Everything is end-to-end encrypted. Only your two Macs can read it.'],
  ['☁️', 'Easy on your iCloud', 'It syncs through iCloud without using any of your iCloud storage.'],
  ['🔑', 'No account', 'No sign-up and no password. Just a six-letter pairing code.'],
  ['👀', 'On every screen', 'It stays in the notch in every app and desktop, even full-screen ones.'],
  ['🫧', 'No inbox', 'No unread badges and no history to scroll. Only the latest thing from them.'],
  ['💻', 'No notch needed', 'On Macs without one, it lives in a small black pill at the top of the screen.'],
];

const FAQ = [
  ['Do we both need to buy it?', "No. One license covers your Mac and your person's."],
  ['What do we need?', 'Two Macs with macOS 14 Sonoma or later, each signed in to iCloud.'],
  ['Can anyone else see what we send?', "No. It's end-to-end encrypted, so only your two Macs can read it."],
  ['My iCloud storage is full. Will it work?', "Yes. OurNotch doesn't use your iCloud storage."],
  ['What if my Mac has no notch?', 'OurNotch shows a small black pill at the top of the screen instead, and works the same way.'],
  ['Is there an iPhone app?', 'Not yet. OurNotch is Mac-only for now.'],
];

// Cloudflare adds the visitor's country; `?country=IN` overrides it for checking prices locally.
export default async function Home({ searchParams }: { searchParams: Promise<{ country?: string }> }) {
  const h = await headers();
  const PRICE = priceFor((await searchParams).country ?? h.get('cf-ipcountry'));
  const CHECKOUT = checkoutUrl(originFrom(h));
  return (
    <>
      <SvgDefs />
      <Reveal />

      <nav className="y-nav">
        <div className="y-wrap">
          <a className="y-logo" href="#top"><span className="y-logo-notch"><Heart /></span>OurNotch</a>
          <div className="y-links">
            <a href="#fits">Features</a><a href="#buy">Pricing</a><a href="#faq">FAQ</a>
            <a className="y-btn" href="#buy">Get OurNotch</a>
          </div>
        </div>
      </nav>

      <header className="y-hero y-wrap" id="top">
        <div className="y-hearts" aria-hidden="true">
          {HEARTS.map(([x, y, w, c], i) => (
            <svg key={i} viewBox="-12 -12 24 21" width={w}
              style={{ left: `${x}%`, top: `${y}%`, fill: PASTEL[c], '--r': `${(i % 2 ? 1 : -1) * (6 + i % 4 * 4)}deg`, '--d': `${5 + i % 4}s`, '--dl': `-${i * .7}s` } as CSSProperties}>
              <use href="#hrt" />
            </svg>
          ))}
        </div>
        <h1>Send love, <em>notch to notch.</em></h1>
        <p className="y-sub">OurNotch keeps your person at the top of your MacBook screen. Send them a note, an emoji or a photo, and it appears in their notch.</p>
        <div className="y-show"><HeroDemo /></div>
        <div className="y-ctas">
          <a className="y-btn" href="#buy"><Heart />Get it for {PRICE}</a>
          <a className="y-link" href="#fits">See how it works</a>
        </div>
        <p className="y-under"><b>One-time purchase.</b> Works on both your Macs.</p>
      </header>

      <section className="y-sec y-wrap" id="fits">
        <div className="y-head y-head-split rv">
          <div><span className="y-kicker">What fits in a notch</span><h2>Tiny things. Big feelings.</h2></div>
          <p>It&apos;s closed most of the day, and still shows you a little bit of them. Hover over it to send something back.</p>
        </div>
        <Bento />
      </section>

      <section className="y-sec y-wrap">
        <div className="y-head rv">
          <span className="y-kicker">Made for two</span>
          <h2>Built for exactly two Macs.</h2>
          <p>You pair once with a six-letter code. After that, whatever you send lands in their notch within seconds, and theirs lands in yours.</p>
        </div>
        <div className="y-stage y-blk y-blush rv">
          <MadeForTwo />
          <p className="y-hint">Tap either side to send a heart.</p>
        </div>
      </section>

      <section className="y-sec y-wrap">
        <div className="y-head rv"><span className="y-kicker">The details</span><h2>Quiet, private, and always there.</h2></div>
        <div className="y-grid">
          {DETAILS.map(([ic, h, p]) => (
            <div key={h} className="y-g rv"><div className="y-ic">{ic}</div><h3>{h}</h3><p>{p}</p></div>
          ))}
        </div>
      </section>

      <section className="y-sec y-wrap" id="buy">
        <div className="y-calm rv">
          <div className="y-calm-art y-blk y-mint">
            <Char kind="pip" className="is-happy" />
            <div className="y-lic-tag">1 license · 2 Macs</div>
            <Char kind="bun" className="is-love" />
          </div>
          <div className="y-calm-copy y-blk y-mist">
            <span className="y-kicker">Pricing</span>
            <h2>One license for both of you.</h2>
            <p>Buy it once and install it on your Mac and your person&apos;s. No subscription.</p>
            <div className="y-amt">{PRICE}<small>one time</small></div>
            <ul><li>Your Mac and your person&apos;s</li><li>Notes, emoji, moods and photos</li><li>Your time together, counted live</li></ul>
            <a className="y-btn" href={CHECKOUT}><Heart />Get OurNotch</a>
            <p className="y-fine">Needs macOS 14 Sonoma or later and iCloud on both Macs. Your love can <a className="y-link" href="/download">download it free</a> and join with your invite.</p>
          </div>
        </div>
      </section>

      <section className="y-sec y-wrap" id="faq">
        <div className="y-fgrid">
          <div className="rv"><span className="y-kicker">FAQ</span><h2>Good questions.</h2></div>
          <div className="y-qs">
            {FAQ.map(([q, a], i) => (
              <details key={q} className="rv" open={i === 0}><summary>{q}</summary><p>{a}</p></details>
            ))}
          </div>
        </div>
      </section>

      <section className="y-end y-wrap">
        <div className="y-sleep">
          <Char kind="pip" className="is-sleep s1" /><Char kind="bun" className="is-sleep s2" />
          <span className="y-zz">z z</span>
        </div>
        <h2>Give your notch someone to love.</h2>
        <a className="y-btn" href="#buy"><Heart />Get it for {PRICE}</a>
      </section>

      <footer className="y-wrap"><div className="y-small"><span>OurNotch · made for two</span><span>Not affiliated with Apple.</span></div></footer>
    </>
  );
}
