import { SvgDefs } from '@/components/Char';
import { SimpleNav, SiteFooter } from '@/components/SiteFooter';
import { fill, SUPPORT, type Lang } from '@/lib/i18n';

type Doc = { kicker: string; h1: string; updated?: string; sections: { h: string; p: string[] }[]; contact?: string };

// **bold** inside a paragraph; nothing else is parsed.
const rich = (text: string) => text.split(/\*\*(.+?)\*\*/g).map((part, i) => (i % 2 ? <b key={i}>{part}</b> : part));

// A plain reading page: the help page, the privacy policy and the terms.
export function DocPage({ lang, path, doc, children }: { lang: Lang; path: string; doc: Doc; children?: React.ReactNode }) {
  return (
    <>
      <SvgDefs />
      <SimpleNav lang={lang} />
      <main className="y-wrap d-page">
        <span className="y-kicker">{doc.kicker}</span>
        <h1>{doc.h1}</h1>
        {doc.updated && <p className="d-updated">{doc.updated}</p>}
        {doc.sections.map(s => (
          <section key={s.h}>
            <h2>{s.h}</h2>
            {s.p.map((p, i) => <p key={i}>{rich(p)}</p>)}
          </section>
        ))}
        {children}
        {doc.contact && <p className="d-contact">{fill(doc.contact, { email: SUPPORT })}</p>}
      </main>
      <SiteFooter lang={lang} path={path} />
    </>
  );
}
