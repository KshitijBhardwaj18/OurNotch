import { Char, Heart, SvgDefs } from '@/components/Char';
import { KeyBox } from '@/components/KeyBox';
import { SimpleNav, SiteFooter } from '@/components/SiteFooter';
import { copy, href, SUPPORT, type Lang } from '@/lib/i18n';

// Where Dodo's checkout lands: three steps, one big button each (devpost/spec-m2.md > Website Pages).
export function ThanksPage({ lang, licenceKey }: { lang: Lang; licenceKey?: string }) {
  const t = copy[lang].thanks;
  const key = licenceKey?.split(',')[0]?.trim() || null;
  const [noteBefore, noteAfter] = t.s2note.split('{b}');
  const [helpBefore, rest] = t.help.split('{more}');
  const [helpMid, helpAfter] = rest.split('{email}');
  return (
    <>
      <SvgDefs />
      <SimpleNav lang={lang} />

      <main className="y-wrap t-page">
        <div className="t-head">
          <div className="t-chars" aria-hidden="true"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /></div>
          <span className="y-kicker">{t.kicker}</span>
          <h1>{t.h1}</h1>
          <p>{t.p}</p>
        </div>

        <ol className="t-steps">
          <li className="y-blk y-butter">
            <span className="t-n">1</span>
            <div><h2>{t.s1}</h2><p>{t.s1p}</p></div>
            <a className="y-btn" href="/download">{t.s1b}</a>
          </li>
          <li className="y-blk y-blush">
            <span className="t-n">2</span>
            <div><h2>{t.s2}</h2><p>{t.s2p}</p></div>
            {key
              ? <a className="y-btn" href={`ournotch://activate?key=${encodeURIComponent(key)}`}><Heart />{t.s2b}</a>
              : <p className="t-note">{noteBefore}<b>{t.s2noteB}</b>{noteAfter}</p>}
          </li>
          <li className="y-blk y-sky">
            <span className="t-n">3</span>
            <div><h2>{t.s3}</h2><p>{t.s3p}</p></div>
          </li>
        </ol>

        {key && <KeyBox licenceKey={key} t={t} />}
        <p className="t-help">
          {helpBefore}<a className="y-link" href={href(lang, '/licence')}>{t.helpLink}</a>{helpMid}
          <a className="y-link" href={`mailto:${SUPPORT}`}>{SUPPORT}</a>{helpAfter}
        </p>
      </main>
      <SiteFooter lang={lang} path="/thanks" />
    </>
  );
}

export const thanksMetadata = (lang: Lang) => ({ title: copy[lang].thanks.title, robots: { index: false } });
