import { copy, href, LANG_NAMES, LANGS, SUPPORT, type Lang } from '@/lib/i18n';

// On every page: help, legal and contact links (Dodo's review and the PRD ask for them everywhere) and the language switch.
export function SiteFooter({ lang, path = '/' }: { lang: Lang; path?: string }) {
  const t = copy[lang].footer;
  return (
    <footer className="y-wrap">
      <div className="y-foot">
        <div className="y-foot-top">
          <a className="y-foot-brand" href={href(lang)}><img src="/logo.svg" alt="" />OurNotch<small>{t.madeForTwo}</small></a>
          <nav className="y-foot-links" aria-label={t.legal}>
            <a href={href(lang, '/licence')}>{t.licence}</a>
            <a href={href(lang, '/privacy')}>{t.privacy}</a>
            <a href={href(lang, '/terms')}>{t.terms}</a>
            <a href={href(lang, '/refunds')}>{t.refunds}</a>
          </nav>
          <a className="y-foot-mail" href={`mailto:${SUPPORT}`}>{t.contact}: <b>{SUPPORT}</b></a>
        </div>
        <div className="y-foot-bottom">
          <span className="y-foot-links">
            {LANGS.map(l => l === lang
              ? <b key={l}>{LANG_NAMES[l]}</b>
              : <a key={l} href={href(l, path)} hrefLang={l} lang={l}>{LANG_NAMES[l]}</a>)}
          </span>
          <span>{t.apple}</span>
        </div>
      </div>
    </footer>
  );
}

// The small header on the inner pages: just the logo, home in the same language.
export function SimpleNav({ lang }: { lang: Lang }) {
  return (
    <nav className="y-nav">
      <div className="y-wrap">
        <a className="y-logo" href={href(lang)}><img className="y-logo-mark" src="/logo.svg" alt="" />OurNotch</a>
      </div>
    </nav>
  );
}
