import { LicenceHelp } from '@/components/LicenceHelp';
import { copy } from '@/lib/i18n';

export const metadata = { title: copy.en.licence.title };

export default function Page() {
  return <LicenceHelp lang="en" />;
}
