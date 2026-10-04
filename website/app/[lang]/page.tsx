import { Landing } from '@/components/Landing';
import type { Lang } from '@/lib/i18n';

export default async function Home({ params, searchParams }: { params: Promise<{ lang: string }>; searchParams: Promise<{ country?: string }> }) {
  return <Landing lang={(await params).lang as Lang} country={(await searchParams).country} />;
}
