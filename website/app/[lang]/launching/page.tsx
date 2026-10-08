import { Launching } from '@/components/Launching';
import { copy, type Lang } from '@/lib/i18n';

type Props = { params: Promise<{ lang: string }> };

export async function generateMetadata({ params }: Props) {
  return { title: copy[(await params).lang as Lang].launching.title, robots: { index: false } };
}

export default async function Page({ params }: Props) {
  return <Launching lang={(await params).lang as Lang} />;
}
