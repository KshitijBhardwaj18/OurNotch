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
    metadataBase: new URL('https://ournotch.app'),
    icons: { icon: [{ url: '/logo.svg', type: 'image/svg+xml' }], apple: '/apple-touch-icon.png' },
    // The preview shown when a link to ournotch.app is shared (WhatsApp, X, LinkedIn...).
    openGraph: { title: t.title, description: t.ogDescription, type: 'website', images: [{ url: '/og.png', width: 1200, height: 630 }] },
    twitter: { card: 'summary_large_image', images: ['/og.png'] },
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
