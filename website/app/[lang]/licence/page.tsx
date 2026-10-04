import { LicenceHelp } from '@/components/LicenceHelp';
import { copy, type Lang } from '@/lib/i18n';

type Props = { params: Promise<{ lang: string }> };

export async function generateMetadata({ params }: Props) {
  return { title: copy[(await params).lang as Lang].licence.title };
}

export default async function Page({ params }: Props) {
  const lang = (await params).lang as Lang;
  return <LicenceHelp lang={lang} />;
}
