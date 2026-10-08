import { DocPage } from '@/components/DocPage';
import { copy, href, type Lang } from '@/lib/i18n';

// Where /download sends people until the signed DMG is on downloads.ournotch.app (slice 11).
export function Launching({ lang }: { lang: Lang }) {
  const t = copy[lang].launching;
  return (
    <DocPage lang={lang} path="/launching" doc={t}>
      <p className="d-actions"><a className="y-btn" href={href(lang)}>{t.back}</a></p>
    </DocPage>
  );
}
