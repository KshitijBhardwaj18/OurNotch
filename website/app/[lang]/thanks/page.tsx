import { ThanksPage, thanksMetadata } from '@/components/ThanksPage';
import type { Lang } from '@/lib/i18n';

type Props = { params: Promise<{ lang: string }>; searchParams: Promise<{ license_key?: string }> };

export async function generateMetadata({ params }: Props) {
  return thanksMetadata((await params).lang as Lang);
}

export default async function Page({ params, searchParams }: Props) {
  return <ThanksPage lang={(await params).lang as Lang} licenceKey={(await searchParams).license_key} />;
}
