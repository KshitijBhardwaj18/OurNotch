import type { Viewport } from 'next';
import { Shell, siteMetadata } from '@/components/Shell';

export const metadata = siteMetadata('en');
export const viewport: Viewport = { themeColor: '#ffffff' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <Shell lang="en">{children}</Shell>;
}
