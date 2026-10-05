'use client';

import { useEffect, useState } from 'react';
import type { Copy } from '@/lib/i18n';
import { fmt, together } from '@/lib/motion';
import { Char } from './Char';
import { Drips, MiniNotch } from './Notch';

// The app's twelve moods, in the same order as their labels in lib/i18n.ts.
const MOODS = ['🥰', '😊', '🥺', '🎉', '☕️', '🍕', '💻', '🎧', '🏃', '😴', '😔', '🤒'];

// Time together, ticking live. Filled in after hydration so server and client agree.
function useTogether() {
  const [t, setT] = useState<ReturnType<typeof together> | null>(null);
  useEffect(() => {
    const tick = () => setT(together());
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);
  return t;
}

function Card({ color, wide, art, title, children }: { color: string; wide?: boolean; art: React.ReactNode; title: string; children: React.ReactNode }) {
  return (
    <div className={`b-card ${color} rv${wide ? ' b-wide' : ''}`}>
      {art}
      <div className="b-copy"><h3>{title}</h3><p>{children}</p></div>
    </div>
  );
}

// What fits in a notch: one card per thing you can send or see.
export function Bento({ t: c }: { t: Copy['bento'] }) {
  const [mood, setMood] = useState('🥰');
  const t = useTogether();
  const n = (k: keyof ReturnType<typeof together>) => (t ? fmt(t[k]) : '…');

  return (
    <div className="b-grid">
      <Card color="y-butter" title={c.noteTitle} art={
        <div className="b-art">
          <MiniNotch mood="🥰" tall ticker={c.ticker} />
          <div className="b-pal" style={{ left: 22 }}><Char kind="pip" className="is-happy" /></div>
        </div>
      }>{c.noteBody}</Card>

      <Card color="y-blush" title={c.heartTitle} art={
        <div className="b-art">
          <MiniNotch mood="😘" />
          <Drips />
          <div className="b-pal" style={{ right: 22 }}><Char kind="bun" className="is-love" /></div>
        </div>
      }>{c.heartBody}</Card>

      <Card color="y-mint" title={c.moodTitle} art={
        <div className="b-art b-moods" role="radiogroup" aria-label={c.moodsLabel}>
          {MOODS.map((e, i) => [e, c.moods[i]]).map(([e, l]) => (
            <button key={e} type="button" role="radio" aria-checked={mood === e} className={mood === e ? 'is-on' : ''} onClick={() => setMood(e)}>
              <span>{e}</span>{l}
            </button>
          ))}
        </div>
      }>{c.moodBody}</Card>

      <Card color="y-sky" wide title={c.photoTitle} art={
        <div className="b-art b-photos">
          <div className="b-polaroid b-back"><div className="b-shot" /><b>{c.us}</b></div>
          <div className="b-polaroid b-front">
            <div className="b-shot x-sun"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /></div>
            <b>{c.sunday}</b>
          </div>
        </div>
      }>{c.photoBody}</Card>

      <Card color="y-mist" wide title={c.countTitle} art={
        <div className="b-art b-count">
          <span className="y-kicker">{c.secondsTogether} <span style={{ color: 'var(--pink)' }}>♥</span></span>
          <span className="b-big">{n('secs')}</span>
          <div className="b-chips">
            <span className="y-butter"><b>{n('days')}</b> {c.days}</span>
            <span className="y-sky"><b>{n('hours')}</b> {c.hours}</span>
            <span className="y-mint"><b>{n('weekends')}</b> {c.weekends}</span>
          </div>
        </div>
      }>{c.countBody}</Card>
    </div>
  );
}
