'use client';

import { useEffect, useRef } from 'react';
import { act, rand } from '@/lib/motion';
import { Char } from './Char';

const NS = 'http://www.w3.org/2000/svg';

function Laptop({ x, id }: { x: number; id: string }) {
  return (
    <g transform={`translate(${x} 150)`} id={id}>
      <rect className="lap-lid" x="0" y="0" width="290" height="196" rx="16" />
      <rect className="lap-screen" x="11" y="11" width="268" height="172" rx="8" fill="url(#wall)" />
      <clipPath id={`${id}-clip`}><rect x="11" y="11" width="268" height="172" rx="8" /></clipPath>
      <g clipPath={`url(#${id}-clip)`}><g className="pour" /></g>
      <path className="mini-notch" d="M100 11 Q105 11 105 16 V20 Q105 27 112 27 H178 Q185 27 185 20 V16 Q185 11 190 11 Z" fill="#000" />
      <g transform="translate(173 19)"><g className="beat"><use href="#hrt" transform="scale(.42)" fill="#FF375F" /></g></g>
      <circle cx="117" cy="19" r="5" fill="#FF8FAB" /><text x="125" y="22.5" fontSize="9">🥰</text>
      <path className="lap-base" d="M-22 196 H312 Q316 210 300 212 H-10 Q-26 210 -22 196 Z" />
    </g>
  );
}

// Two Macs: you tap, a heart flies along the route and pours out of your person's notch.
export function MadeForTwo() {
  const ref = useRef<SVGSVGElement>(null);

  useEffect(() => {
    const scene = ref.current!;
    const q = <T extends Element>(s: string) => scene.querySelector(s) as T;
    const route = q<SVGPathElement>('.route'), routeLen = route.getTotalLength();
    const pip = q<SVGSVGElement>('.slot-pip .char'), bun = q<SVGSVGElement>('.slot-bun .char'), fly = q<SVGGElement>('.fly');
    let alive = true;

    const heartEl = (fill: string, stroke = true) => {
      const u = document.createElementNS(NS, 'use');
      u.setAttribute('href', '#hrt'); u.setAttribute('fill', fill);
      if (stroke) { u.setAttribute('stroke', 'var(--ink)'); u.setAttribute('stroke-width', '2.2'); }
      return u;
    };
    function pour(lap: string, n: number) {
      const g = q<SVGGElement>(`#${lap} .pour`);
      for (let i = 0; i < n; i++) {
        const h = heartEl(i % 2 ? '#FFB3C2' : '#FF375F', false); g.appendChild(h);
        const x = 145 + rand(-40, 40), sc = rand(1, 1.6), r = rand(-25, 25);
        h.animate([
          { transform: `translate(${x}px,24px) scale(0)`, opacity: 1 },
          { transform: `translate(${x + rand(-8, 8)}px,70px) scale(${sc}) rotate(${r / 2}deg)`, opacity: 1, offset: .35 },
          { transform: `translate(${x + rand(-14, 14)}px,170px) scale(${sc}) rotate(${r}deg)`, opacity: 0 },
        ], { duration: 1600, delay: i * 140, easing: 'ease-in', fill: 'backwards' }).onfinish = () => h.remove();
      }
    }
    function popAbove(cx: number, n: number) {
      for (let i = 0; i < n; i++) {
        const h = heartEl('#FF375F'); fly.appendChild(h);
        const dx = (i - (n - 1) / 2) * 26;
        h.animate([
          { transform: `translate(${cx}px,230px) scale(0)`, opacity: 1 },
          { transform: `translate(${cx + dx}px,196px) scale(1)`, opacity: 1, offset: .4 },
          { transform: `translate(${cx + dx * 1.3}px,176px) scale(.9)`, opacity: 0 },
        ], { duration: 1300, delay: i * 90, easing: 'cubic-bezier(.2,.8,.3,1)', fill: 'backwards' }).onfinish = () => h.remove();
      }
    }
    function sendHeart(dir: number) {
      const [from, to, lap, toX] = dir > 0 ? [pip, bun, 'lapR', 907] as const : [bun, pip, 'lapL', 93] as const;
      act(from, 'is-tap', 450); act(from, 'is-happy', 1700);
      const h = heartEl('#FF375F'); fly.appendChild(h);
      const t0 = performance.now() + 220, dur = 1150;
      let frame = 0;
      (function step(now: number) {
        if (!alive) return;
        const p = Math.min(1, Math.max(0, (now - t0) / dur));
        const e = p < .5 ? 2 * p * p : 1 - (-2 * p + 2) ** 2 / 2;
        const pt = route.getPointAtLength((dir > 0 ? e : 1 - e) * routeLen);
        const s = p === 0 ? 0 : 1.1 + Math.sin(p * Math.PI) * .5;
        h.setAttribute('transform', `translate(${pt.x} ${pt.y}) rotate(${Math.sin(p * 12) * 12}) scale(${s})`);
        if (p > 0 && p < 1 && frame++ % 3 === 0) {
          const c = document.createElementNS(NS, 'circle');
          c.setAttribute('r', String(rand(2, 4))); c.setAttribute('fill', Math.random() < .5 ? '#FF375F' : '#FFB3C2');
          fly.insertBefore(c, h);
          c.animate([{ transform: `translate(${pt.x}px,${pt.y}px)`, opacity: .9 }, { transform: `translate(${pt.x + rand(-10, 10)}px,${pt.y + rand(6, 18)}px) scale(.2)`, opacity: 0 }], { duration: 700 }).onfinish = () => c.remove();
        }
        if (p < 1) { requestAnimationFrame(step); return; }
        h.remove();
        q(`#${lap} .mini-notch`).animate([{ transform: 'scale(1)' }, { transform: 'scale(1.18,1.5)' }, { transform: 'scale(1)' }], { duration: 500, easing: 'cubic-bezier(.3,1.6,.5,1)' });
        pour(lap, 7);
        act(to, 'is-jump', 800); act(to, 'is-love', 2000);
        popAbove(toX, 3);
      })(performance.now());
    }

    const onClick = (e: MouseEvent) => sendHeart(e.clientX - scene.getBoundingClientRect().left < scene.clientWidth / 2 ? 1 : -1);
    scene.addEventListener('click', onClick);
    let dir = 1, loop = 0;
    if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
      const next = () => { sendHeart(dir); dir = -dir; loop = window.setTimeout(next, 3600); };
      next();
    }
    return () => { alive = false; clearTimeout(loop); scene.removeEventListener('click', onClick); fly.replaceChildren(); };
  }, []);

  return (
    <svg className="scene" ref={ref} viewBox="0 0 1000 400" role="img"
      aria-label="Pip, labelled you, taps their notch and a heart flies over to Bun, labelled your person, whose notch pours out hearts.">
      <path className="route" d="M320 172 C 380 0, 620 0, 680 172" />
      <Laptop x={175} id="lapL" /><Laptop x={535} id="lapR" />
      <g className="slot-pip"><Char kind="pip" x="18" y="206" width="150" height="162" /></g>
      <g className="slot-bun"><Char kind="bun" x="832" y="206" width="150" height="162" /></g>
      <text className="who" x="93" y="396">you</text>
      <text className="who" x="907" y="396">your person</text>
      <g className="fly" />
    </svg>
  );
}
