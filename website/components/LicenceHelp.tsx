import { DocPage } from '@/components/DocPage';
import { copy, SUPPORT, type Lang } from '@/lib/i18n';
import { portalUrl } from '@/lib/prices';

// "My licence": where the key is, moving Macs, and what to do when something goes wrong.
export function LicenceHelp({ lang }: { lang: Lang }) {
  const t = copy[lang].licence;
  return (
    <DocPage lang={lang} path="/licence" doc={t}>
      <p className="d-actions">
        <a className="y-btn" href={portalUrl}>{t.find}</a>
        <a className="y-link" href={`mailto:${SUPPORT}`}>{t.write}</a>
      </p>
    </DocPage>
  );
}
