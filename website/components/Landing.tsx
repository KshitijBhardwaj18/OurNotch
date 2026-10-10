import type { CSSProperties } from 'react';
import { headers } from 'next/headers';
import { Char, Heart, SvgDefs } from '@/components/Char';
import { Bento } from '@/components/Bento';
import { HeroDemo } from '@/components/HeroDemo';
import { MadeForTwo } from '@/components/MadeForTwo';
import { SiteFooter } from '@/components/SiteFooter';
import { Reveal } from '@/components/bits';
import { copy, fill, href, type Lang } from '@/lib/i18n';
import { checkoutUrl, priceFor } from '@/lib/prices';

// Hero hearts: [left %, top %, size px, color], around the headline and beside the video. Phones skip them.
const PASTEL = ['#FFD3DC', '#FFE9A6', '#CFE3FF', '#CFEFDF', '#FF8FAB'];
const HEARTS = [
  [6, 6, 30, 0], [91, 9, 36, 1], [4, 24, 20, 4], [93, 27, 22, 3],
  [3, 52, 28, 2], [95, 60, 30, 0], [5, 82, 22, 1], [94, 88, 18, 4],
];

// One license, two Macs: a Mac each, joined by a heart, Pip under one and Bun under the other.
function Mac({ x, screen }: { x: number; screen: string }) {
  return (
    <g transform={`translate(${x} 40)`}>
      <rect x="0" y="0" width="160" height="108" rx="11" fill="#fff" stroke="var(--ink)" strokeWidth="3" />
      <rect x="8" y="8" width="144" height="92" rx="6" fill={screen} />
      <path d="M58 8 Q61 8 61 11 V13 Q61 18 66 18 H94 Q99 18 99 13 V11 Q99 8 102 8 Z" fill="#000" />
      <circle cx="68" cy="13" r="2.6" fill="#FF8FAB" />
      <use href="#hrt" transform="translate(92 13) scale(.22)" fill="#FF375F" />
      <path d="M-14 108 H174 Q177 117 167 118 H-7 Q-17 117 -14 108 Z" fill="#fff" stroke="var(--ink)" strokeWidth="3" strokeLinejoin="round" />
    </g>
  );
}

function TwoMacs() {
  return (
    <svg className="y-two-macs" viewBox="0 0 420 300" aria-hidden="true">
      <path d="M130 46 C 170 -6, 250 -6, 290 46" fill="none" stroke="var(--ink)" strokeWidth="3" strokeLinecap="round" strokeDasharray=".5 11" opacity=".35" />
      <use href="#hrt" transform="translate(210 14) scale(1.15)" fill="#FF375F" stroke="var(--ink)" strokeWidth="2" />
      <Mac x={20} screen="var(--butter)" /><Mac x={240} screen="var(--sky)" />
      <Char kind="pip" className="is-happy" x="45" y="170" width="110" height="119" />
      <Char kind="bun" className="is-love" x="265" y="170" width="110" height="119" />
    </svg>
  );
}

// The landing page in one language. Cloudflare adds the visitor's country; `?country=IN` overrides it locally.
export async function Landing({ lang, country }: { lang: Lang; country?: string }) {
  const h = await headers();
  const t = copy[lang];
  const price = priceFor(country ?? h.get('cf-ipcountry'));
  const checkout = checkoutUrl(href(lang, '/thanks'));
  const [fineBefore, fineAfter] = t.buy.fine.split('{download}');

  return (
    <>
      <SvgDefs />
      <Reveal />

      <nav className="y-nav">
        <div className="y-wrap">
          <a className="y-logo" href="#top"><img className="y-logo-mark" src="/logo.svg" alt="" />OurNotch</a>
          <div className="y-links">
            <a href="#fits">{t.nav.features}</a><a href="#buy">{t.nav.pricing}</a><a href="#faq">{t.nav.faq}</a>
            <a className="y-btn" href={checkout}>{t.nav.get}</a>
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
        <h1>{t.hero.h1a} <em>{t.hero.h1b}</em></h1>
        <p className="y-sub">{t.hero.sub}</p>
        <div className="y-show"><HeroDemo t={t.demo} tour={t.tour} /></div>
        <div className="y-ctas">
          <a className="y-btn" href={checkout}><Heart />{t.hero.cta}</a>
          <a className="y-link" href="#fits">{t.hero.how}</a>
        </div>
        <p className="y-under"><b>{t.hero.underB}</b> {fill(t.hero.under, { price })}</p>
      </header>

      <section className="y-sec y-wrap" id="fits">
        <div className="y-head y-head-split rv">
          <div><span className="y-kicker">{t.fits.kicker}</span><h2>{t.fits.h2}</h2></div>
          <p>{t.fits.p}</p>
        </div>
        <Bento t={t.bento} />
      </section>

      <section className="y-sec y-wrap">
        <div className="y-head rv">
          <span className="y-kicker">{t.two.kicker}</span>
          <h2>{t.two.h2}</h2>
          <p>{t.two.p}</p>
        </div>
        <div className="y-stage y-blk y-blush rv">
          <MadeForTwo t={t.two} />
          <p className="y-hint">{t.two.hint}</p>
        </div>
      </section>

      <section className="y-sec y-wrap">
        <div className="y-head rv"><span className="y-kicker">{t.details.kicker}</span><h2>{t.details.h2}</h2></div>
        <div className="y-grid">
          {t.details.items.map(([ic, hd, p]) => (
            <div key={hd} className="y-g rv"><div className="y-ic">{ic}</div><h3>{hd}</h3><p>{p}</p></div>
          ))}
        </div>
      </section>

      <section className="y-sec y-wrap" id="buy">
        <div className="y-calm rv">
          <div className="y-calm-art y-blk y-mint">
            <div className="y-lic-tag">{t.buy.tag}</div>
            <TwoMacs />
          </div>
          <div className="y-calm-copy y-blk y-mist">
            <span className="y-kicker">{t.buy.kicker}</span>
            <h2>{t.buy.h2}</h2>
            <p>{t.buy.p}</p>
            <div className="y-amt">{t.buy.free}<small>{t.buy.forDays}</small></div>
            <p className="y-then">{fill(t.buy.then, { price })}</p>
            <ul>{t.buy.points.map(p => <li key={p}>{p}</li>)}</ul>
            <a className="y-btn" href={checkout}><Heart />{t.buy.cta}</a>
            <p className="y-fine">{fineBefore}<a className="y-link" href="/download">{t.buy.downloadFree}</a>{fineAfter}</p>
          </div>
        </div>
      </section>

      <section className="y-sec y-wrap" id="faq">
        <div className="y-fgrid">
          <div className="rv"><span className="y-kicker">{t.faq.kicker}</span><h2>{t.faq.h2}</h2></div>
          <div className="y-qs">
            {/* one shared `name`: opening a question closes the others */}
            {t.faq.items.map(([q, a], i) => (
              <details key={q} name="faq" className="rv" open={i === 0}><summary>{q}</summary><p>{a}</p></details>
            ))}
          </div>
        </div>
      </section>

      <section className="y-end y-wrap">
        <div className="y-sleep">
          <Char kind="pip" className="is-sleep s1" /><Char kind="bun" className="is-sleep s2" />
          <span className="y-zz">z z</span>
        </div>
        <h2>{t.end.h2}</h2>
        <a className="y-btn" href={checkout}><Heart />{t.end.cta}</a>
        <p className="y-under"><b>{t.hero.underB}</b> {fill(t.hero.under, { price })}</p>
      </section>

      <SiteFooter lang={lang} />
    </>
  );
}
