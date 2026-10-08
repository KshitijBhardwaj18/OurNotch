import { copy, href, LANG_NAMES, LANGS, SUPPORT, type Lang } from '@/lib/i18n';
import { Heart } from './Char';

// On every page: help, legal and contact links (Dodo's review and the PRD ask for them everywhere) and the language switch.
export function SiteFooter({ lang, path = '/' }: { lang: Lang; path?: string }) {
  const t = copy[lang].footer;
  return (
    <footer className="y-wrap">
      <div className="y-small">
        <span>{t.made}</span>
        <span className="y-foot-links">
          <a href={href(lang, '/licence')}>{t.licence}</a>
          <a href={href(lang, '/privacy')}>{t.privacy}</a>
          <a href={href(lang, '/terms')}>{t.terms}</a>
          <a href={href(lang, '/refunds')}>{t.refunds}</a>
          <a href={`mailto:${SUPPORT}`}>{t.contact}: {SUPPORT}</a>
        </span>
        <span className="y-foot-links">
          {LANGS.map(l => l === lang
            ? <b key={l}>{LANG_NAMES[l]}</b>
            : <a key={l} href={href(l, path)} hrefLang={l} lang={l}>{LANG_NAMES[l]}</a>)}
        </span>
        <span>{t.apple}</span>
      </div>
    </footer>
  );
}

// The small header on the inner pages: just the logo, home in the same language.
export function SimpleNav({ lang }: { lang: Lang }) {
  return (
    <nav className="y-nav">
      <div className="y-wrap">
        <a className="y-logo" href={href(lang)}><span className="y-logo-notch"><Heart /></span>OurNotch</a>
      </div>
    </nav>
  );
}
