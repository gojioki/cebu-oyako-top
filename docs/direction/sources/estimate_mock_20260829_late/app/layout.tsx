import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL('http://localhost:3000'),
  title: 'セブ島親子留学 簡単見積り｜改善モック',
  description: '親1人＋子ども1人を基準に、期間と親の受講有無から親子留学の総額と3つの内訳を確認する改善モックです。',
  openGraph: {
    title: 'セブ島親子留学 簡単見積り｜改善モック',
    description: '3つ選ぶだけで、親子留学の総額と内訳がわかる。',
    images: [{ url: '/og.png', width: 1731, height: 909, alt: 'セブ島親子留学 簡単見積り' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'セブ島親子留学 簡単見積り｜改善モック',
    description: '3つ選ぶだけで、親子留学の総額と内訳がわかる。',
    images: ['/og.png'],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  );
}
