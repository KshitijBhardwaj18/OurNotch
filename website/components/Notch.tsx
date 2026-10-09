import type { CSSProperties, ReactNode } from 'react';
import { Char, Heart } from './Char';

// A small closed notch, as in the app: your person's face on the left, and on the right their mood
// (with its word) or a heartbeat.
export function MiniNotch({ mood, word, tall, ticker }: { mood?: ReactNode; word?: string; tall?: boolean; ticker?: string }) {
  return (
    <div className={`x-mini${tall ? ' x-tall' : ''}`}>
      <span className="x-who"><span className="x-av"><Char kind="bun" className="is-happy" /></span></span>
      {mood ? <span className="x-who">{typeof mood === 'string' ? <span className="x-mood">{mood}</span> : mood}{word && <span className="x-word">{word}</span>}</span>
            : <Heart className="x-heart" />}
      {ticker && <div className="x-tick"><span><b>bun</b>{ticker}</span></div>}
    </div>
  );
}

// Hearts dripping out of a notch.
const SPOT = [-1, .5, -.2, 1, -.6, .8], TILT = [14, -18, 8, -10, 16, -6];
export function Drips({ n = 4, spread = 40 }: { n?: number; spread?: number }) {
  return Array.from({ length: n }, (_, i) => (
    <svg key={i} className="x-drip" viewBox="-12 -12 24 21" aria-hidden="true"
      style={{ left: `calc(50% + ${SPOT[i % 6] * spread}px)`, animationDelay: `${i * .6}s`, '--r': `${TILT[i % 6]}deg` } as CSSProperties}>
      <use href="#hrt" />
    </svg>
  ));
}
