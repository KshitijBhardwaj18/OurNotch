import { Launching } from '@/components/Launching';
import { copy } from '@/lib/i18n';

export const metadata = { title: copy.en.launching.title, robots: { index: false } };

export default function Page() {
  return <Launching lang="en" />;
}
