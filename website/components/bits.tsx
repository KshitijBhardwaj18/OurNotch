'use client';

import { useEffect } from 'react';

const reduced = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

// Fades sections in as they scroll into view, and freezes the line boil for reduced motion.
export function Reveal() {
  useEffect(() => {
    if (reduced()) (document.getElementById('defs') as unknown as SVGSVGElement | null)?.pauseAnimations();
    const io = new IntersectionObserver(es => es.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    }), { threshold: .12 });
    document.querySelectorAll<HTMLElement>('.rv').forEach((el, i) => { el.style.transitionDelay = (i % 3) * 80 + 'ms'; io.observe(el); });
    return () => io.disconnect();
  }, []);
  return null;
}
