import { DocPage } from '@/components/DocPage';
import { copy } from '@/lib/i18n';

export const metadata = { title: copy.en.privacy.title };

export default function Page() {
  return <DocPage lang="en" path="/privacy" doc={copy["en"].privacy} />;
}
