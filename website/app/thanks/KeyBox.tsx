'use client';

import { useEffect, useState } from 'react';

// The key as a backup, with Copy. Removes it from the address bar so it doesn't linger in history or shares.
export function KeyBox({ licenceKey }: { licenceKey: string }) {
  const [copied, setCopied] = useState(false);
  useEffect(() => { history.replaceState(null, '', '/thanks'); }, []);
  const copy = async () => {
    await navigator.clipboard.writeText(licenceKey);
    setCopied(true);
    setTimeout(() => setCopied(false), 1600);
  };
  return (
    <div className="t-key y-blk y-mist">
      <span className="y-kicker">Your licence key</span>
      <div className="t-key-row">
        <code>{licenceKey}</code>
        <button type="button" className="y-btn t-copy" onClick={copy}>{copied ? 'Copied ♡' : 'Copy'}</button>
      </div>
      <p>Also in your receipt email. Keep it for a new Mac.</p>
    </div>
  );
}
