import type { Metadata } from 'next';
import { Bricolage_Grotesque, Inter_Tight } from 'next/font/google';
import { copy, type Lang } from '@/lib/i18n';
import '../app/globals.css';

const disp = Bricolage_Grotesque({ subsets: ['latin'], weight: ['700', '800'], variable: '--font-disp' });
const body = Inter_Tight({ subsets: ['latin'], weight: ['400', '500', '600'], variable: '--font-body' });

export function siteMetadata(lang: Lang): Metadata {
  const t = copy[lang].meta;
  return {
    title: t.title,
    description: t.description,
    openGraph: { title: t.title, description: t.ogDescription, type: 'website' },
    alternates: { languages: { en: '/', fr: '/fr', de: '/de' } },
  };
}

// The <html> of every page. English and French/German have separate root layouts so each page says its language.
export function Shell({ lang, children }: { lang: Lang; children: React.ReactNode }) {
  return (
    <html lang={lang} className={`${disp.variable} ${body.variable}`}>
      <body>{children}</body>
    </html>
  );
}
