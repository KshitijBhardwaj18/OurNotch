import { redirect } from 'next/navigation';

// The newest DMG, uploaded by scripts/release.sh. DOWNLOAD_URL overrides it until the R2 bucket is live (slice 12).
export function GET() {
  redirect(process.env.DOWNLOAD_URL ?? 'https://downloads.ournotch.app/OurNotch.dmg');
}
