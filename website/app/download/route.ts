import { redirect } from 'next/navigation';

// ponytail: GitHub releases until slice 9 uploads signed DMGs to R2.
export function GET() {
  redirect('https://github.com/KshitijBhardwaj18/OurNotch/releases/latest');
}
