import type { SVGProps } from 'react';

// Pip (pink, sprout) and Bun (cream, round ears). Moods are classes: is-happy, is-love, is-sleep.
const COL = { pip: ['#FF8FAB', '#F06A8D'], bun: ['#FFE2B3', '#F0C487'] } as const;

type Props = { kind: 'pip' | 'bun'; delay?: number } & SVGProps<SVGSVGElement>;

export function Char({ kind, delay = kind === 'pip' ? 1.3 : 2.9, className = '', ...rest }: Props) {
  const [b, s] = COL[kind];
  const off = { animationDelay: `-${delay}s` };
  return (
    <svg className={`char char-${kind} ${className}`} viewBox="0 0 120 130" aria-hidden="true" {...rest}>
      <ellipse className="c-shadow" cx="60" cy="125" rx="36" ry="5" />
      <g className="c-bob" style={off}>
        <g filter="url(#boil)">
          {kind === 'bun' ? (
            <>
              <circle className="c-line" cx="33" cy="34" r="13" fill={b} /><circle cx="33" cy="34" r="6" fill="#FFB3C2" />
              <circle className="c-line" cx="87" cy="34" r="13" fill={b} /><circle cx="87" cy="34" r="6" fill="#FFB3C2" />
            </>
          ) : (
            <>
              <path className="c-line" d="M60 22 C 58 14 60 9 63 5" fill="none" />
              <path className="c-line" d="M62 8 C 69 0 80 4 77 11 C 73 15 65 13 62 8 Z" fill="#8BD3A8" />
              <path className="c-line" d="M61 10 C 54 4 46 8 49 13 C 52 16 58 14 61 10 Z" fill="#8BD3A8" />
            </>
          )}
          <ellipse className="c-line" cx="44" cy="119" rx="10" ry="6" fill={s} />
          <ellipse className="c-line" cx="76" cy="119" rx="10" ry="6" fill={s} />
          <path className="c-line" fill={b} d="M60 20 C 94 19 109 50 108 80 C 107 107 88 121 60 121 C 31 121 12 107 12 79 C 12 50 27 21 60 20 Z" />
          <path d="M29 54 C 32 43 40 35 50 31" stroke="#fff" strokeWidth="5" strokeLinecap="round" fill="none" opacity=".65" />
          <g className="c-arm-l"><ellipse className="c-line" cx="16" cy="90" rx="7.5" ry="11" transform="rotate(22 16 90)" fill={b} /></g>
          <g className="c-arm-r"><ellipse className="c-line" cx="104" cy="90" rx="7.5" ry="11" transform="rotate(-22 104 90)" fill={b} /></g>
          <ellipse cx="33" cy="83" rx="7.5" ry="4.2" fill="#FF4F78" opacity=".33" />
          <ellipse cx="87" cy="83" rx="7.5" ry="4.2" fill="#FF4F78" opacity=".33" />
          <g className="eyes-open" style={off}>
            <ellipse cx="45" cy="70" rx="5" ry="6.5" fill="#3A2430" /><ellipse cx="75" cy="70" rx="5" ry="6.5" fill="#3A2430" />
            <circle cx="46.8" cy="67.2" r="1.9" fill="#fff" /><circle cx="76.8" cy="67.2" r="1.9" fill="#fff" />
          </g>
          <g className="eyes-happy" fill="none" stroke="#3A2430" strokeWidth="3.2" strokeLinecap="round"><path d="M39 72 Q45 63 51 72" /><path d="M69 72 Q75 63 81 72" /></g>
          <g className="eyes-heart" fill="#FF375F" stroke="#3A2430" strokeWidth="2.2"><use href="#hrt" transform="translate(45 71) scale(.62)" /><use href="#hrt" transform="translate(75 71) scale(.62)" /></g>
          <g className="eyes-sleep" fill="none" stroke="#3A2430" strokeWidth="3" strokeLinecap="round"><path d="M39 70 Q45 75 51 70" /><path d="M69 70 Q75 75 81 70" /></g>
          <path className="mouth-smile" d="M54.5 81 Q60 87 65.5 81" fill="none" stroke="#3A2430" strokeWidth="2.8" strokeLinecap="round" />
          <ellipse className="mouth-o" cx="60" cy="84" rx="4" ry="4.6" fill="#8A2B44" stroke="#3A2430" strokeWidth="2" />
        </g>
      </g>
    </svg>
  );
}

export function Heart({ className }: { className?: string }) {
  return <svg className={className} viewBox="-11 -11 22 19" aria-hidden="true"><use href="#hrt" /></svg>;
}

// Shared SVG pieces: the hand-drawn line boil, the heart, the laptop wallpaper.
export function SvgDefs() {
  return (
    <svg width="0" height="0" style={{ position: 'absolute' }} aria-hidden="true" id="defs">
      <defs>
        <filter id="boil" x="-10%" y="-10%" width="120%" height="120%">
          <feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves={2} seed="1" result="n">
            <animate attributeName="seed" values="1;2;3;4" dur=".6s" repeatCount="indefinite" calcMode="discrete" />
          </feTurbulence>
          <feDisplacementMap in="SourceGraphic" in2="n" scale="2" xChannelSelector="R" yChannelSelector="G" />
        </filter>
        <path id="hrt" d="M0 7 C -11 -1 -11 -10 -4.5 -10 C -1.5 -10 0 -7.5 0 -6 C 0 -7.5 1.5 -10 4.5 -10 C 11 -10 11 -1 0 7 Z" />
        <linearGradient id="wall" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#FFF0E6" /><stop offset="1" stopColor="#FFD6DF" /></linearGradient>
      </defs>
    </svg>
  );
}
