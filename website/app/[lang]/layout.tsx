import type { Viewport } from 'next';
import { notFound } from 'next/navigation';
import { Shell, siteMetadata } from '@/components/Shell';
import { isLang } from '@/lib/i18n';

// French and German live under /fr and /de; English is at the root (app/(en)).
export const dynamicParams = false;
export const generateStaticParams = () => [{ lang: 'fr' }, { lang: 'de' }];
export const viewport: Viewport = { themeColor: '#ffffff' };

export async function generateMetadata({ params }: { params: Promise<{ lang: string }> }) {
  const { lang } = await params;
  return isLang(lang) ? siteMetadata(lang) : {};
}

export default async function LangLayout({ children, params }: { children: React.ReactNode; params: Promise<{ lang: string }> }) {
  const { lang } = await params;
  if (!isLang(lang) || lang === 'en') notFound();
  return <Shell lang={lang}>{children}</Shell>;
}
