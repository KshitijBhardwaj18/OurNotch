import type { Metadata, Viewport } from 'next';
import { Bricolage_Grotesque, Inter_Tight } from 'next/font/google';
import './globals.css';

const disp = Bricolage_Grotesque({ subsets: ['latin'], weight: ['700', '800'], variable: '--font-disp' });
const body = Inter_Tight({ subsets: ['latin'], weight: ['400', '500', '600'], variable: '--font-body' });

export const metadata: Metadata = {
  title: 'OurNotch — send love, notch to notch',
  description: 'OurNotch puts your person in your MacBook notch: their face, their mood, their notes, emoji and photos. One license works for you both.',
  openGraph: {
    title: 'OurNotch — send love, notch to notch',
    description: 'Notes, emoji and photos that appear in your person’s MacBook notch. One license works for you both.',
    type: 'website',
  },
};

export const viewport: Viewport = { themeColor: '#ffffff' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${disp.variable} ${body.variable}`}>
      <body>{children}</body>
    </html>
  );
}
