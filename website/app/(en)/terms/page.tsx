import { DocPage } from '@/components/DocPage';
import { copy } from '@/lib/i18n';

export const metadata = { title: copy.en.terms.title };

export default function Page() {
  return <DocPage lang="en" path="/terms" doc={copy["en"].terms} />;
}
