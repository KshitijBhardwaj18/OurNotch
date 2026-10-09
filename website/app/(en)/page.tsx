import { Landing } from '@/components/Landing';

export default async function Home({ searchParams }: { searchParams: Promise<{ country?: string }> }) {
  return <Landing lang="en" country={(await searchParams).country} />;
}
