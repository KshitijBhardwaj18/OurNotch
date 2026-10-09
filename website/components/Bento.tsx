'use client';

import { useEffect, useState } from 'react';
import { fmt, together } from '@/lib/motion';
import { Char } from './Char';
import { Drips, MiniNotch } from './Notch';

const MOODS = [['🥰', 'In love'], ['😊', 'Happy'], ['🥺', 'Missing you'], ['🎉', 'Excited'], ['☕️', 'On a break'], ['🍕', 'Hungry'],
  ['💻', 'Busy'], ['🎧', 'Focused'], ['🏃', 'Out'], ['😴', 'Sleepy'], ['😔', 'Low'], ['🤒', 'Unwell']];

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
export function Bento() {
  const [mood, setMood] = useState('🥰');
  const t = useTogether();
  const n = (k: keyof ReturnType<typeof together>) => (t ? fmt(t[k]) : '—');

  return (
    <div className="b-grid">
      <Card color="y-butter" title="Ten words or fewer." art={
        <div className="b-art">
          <MiniNotch mood="🥰" tall ticker="lunch at 1? i'll bring dumplings 🥟" />
          <div className="b-pal" style={{ left: 22 }}><Char kind="pip" className="is-happy" /></div>
        </div>
      }>A short note scrolls across their notch three times, or until they open it.</Card>

      <Card color="y-blush" title="One tap, many hearts." art={
        <div className="b-art">
          <MiniNotch mood="😘" />
          <Drips />
          <div className="b-pal" style={{ right: 22 }}><Char kind="bun" className="is-love" /></div>
        </div>
      }>Tap an emoji and it pours out of their notch, or floats up across their whole screen.</Card>

      <Card color="y-mint" title="How you are, at a glance." art={
        <div className="b-art b-moods" role="radiogroup" aria-label="Moods">
          {MOODS.map(([e, l]) => (
            <button key={l} type="button" role="radio" aria-checked={mood === e} className={mood === e ? 'is-on' : ''} onClick={() => setMood(e)}>
              <span>{e}</span>{l}
            </button>
          ))}
        </div>
      }>Pick one of twelve moods. It sits next to your face in their notch.</Card>

      <Card color="y-sky" wide title="A photo for their Home." art={
        <div className="b-art b-photos">
          <div className="b-polaroid b-back"><div className="b-shot" /><b>us ♡</b></div>
          <div className="b-polaroid b-front">
            <div className="b-shot x-sun"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /></div>
            <b>sunday ♡</b>
          </div>
        </div>
      }>Send a favorite photo. It stays on their Home until you send the next one.</Card>

      <Card color="y-mist" wide title="Counted down to the second." art={
        <div className="b-art b-count">
          <span className="y-kicker">Seconds together <span style={{ color: 'var(--pink)' }}>♥</span></span>
          <span className="b-big">{n('secs')}</span>
          <div className="b-chips">
            <span className="y-butter"><b>{n('days')}</b> days</span>
            <span className="y-sky"><b>{n('hours')}</b> hours</span>
            <span className="y-mint"><b>{n('weekends')}</b> weekends</span>
          </div>
        </div>
      }>Open the notch to see their latest photo and note, and how long you&apos;ve been together.</Card>
    </div>
  );
}
