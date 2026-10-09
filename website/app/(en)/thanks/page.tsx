import { ThanksPage, thanksMetadata } from '@/components/ThanksPage';

export const metadata = thanksMetadata('en');

export default async function Page({ searchParams }: { searchParams: Promise<{ license_key?: string }> }) {
  return <ThanksPage lang="en" licenceKey={(await searchParams).license_key} />;
}
