import { DocPage } from '@/components/DocPage';
import { copy } from '@/lib/i18n';

export const metadata = { title: copy.en.refunds.title };

export default function Page() {
  return <DocPage lang="en" path="/refunds" doc={copy["en"].refunds} />;
}
