'use client';

import { useEffect, useState } from 'react';
import type { Copy } from '@/lib/i18n';

// The key as a backup, with Copy. Removes it from the address bar so it doesn't linger in history or shares.
export function KeyBox({ licenceKey, t }: { licenceKey: string; t: Copy['thanks'] }) {
  const [copied, setCopied] = useState(false);
  useEffect(() => { history.replaceState(null, '', location.pathname); }, []);
  const copy = async () => {
    await navigator.clipboard.writeText(licenceKey);
    setCopied(true);
    setTimeout(() => setCopied(false), 1600);
  };
  return (
    <div className="t-key y-blk y-mist">
      <span className="y-kicker">{t.keyKicker}</span>
      <div className="t-key-row">
        <code>{licenceKey}</code>
        <button type="button" className="y-btn t-copy" onClick={copy}>{copied ? t.copied : t.copy}</button>
      </div>
      <p>{t.keyNote}</p>
    </div>
  );
}
