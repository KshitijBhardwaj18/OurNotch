import type { Copy } from './i18n';
import { fill } from './i18n';
import { act, fmt, rand, together } from './motion';

type Who = 'pip' | 'bun';
// [step length, who talks, their line, what happens, how long the line stays up (default: the step minus a beat)]
type Step = [ms: number, who: Who, line: string, run: () => void, up?: number];
type Shot = 'wide' | 'mid' | 'close';

// Desk coordinates: the screen spans x 70..1094, so the notch is centred at x 582.
const CX = 582;
// [visible width, top margin] in desk px. Phones get tighter shots so the notch stays readable.
const SHOTS: Record<'desktop' | 'phone', Record<Shot, [number, number]>> = {
  desktop: { wide: [1084, 0], mid: [820, 0], close: [520, 0] },
  phone: { wide: [800, 0], mid: [640, 0], close: [380, 0] },
};
const PHONE = '(max-width: 599px)'; // keep in step with .demo-shell's aspect-ratio in globals.css

// Plays the notch like a short looping video: Pip (you) and Bun (your person in the notch) narrate.
// `d` is the demo's static text, `t` the script's lines and statuses, both in the page's language.
export function runHeroTour(root: HTMLElement, d: Copy['demo'], t: Copy['tour']) {
  const q = <T extends HTMLElement = HTMLElement>(s: string) => root.querySelector(s) as T;
  const qa = (s: string) => [...root.querySelectorAll<HTMLElement>(s)];
  const timers = new Set<number>();
  const later = (fn: () => void, ms: number) => {
    const id = window.setTimeout(() => { timers.delete(id); fn(); }, ms);
    timers.add(id);
  };
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const phone = matchMedia(PHONE);

  const shell = q('.demo-shell'), desk = q('.desk'), notch = q('.notch'), fx = q('.fx');
  const banner = q('.n-banner span');
  const pip = q('.pal-pip .char'), bun = q('.pal-bun .char');
  const noteIn = q<HTMLInputElement>('.composer input'), noteStatus = q('.note-status');
  const selfie = q('.ph .chars'), selfieHTML = selfie.innerHTML;
  const sunday = q('.x-tpl .x-pic');

  /* ---------- live bits: clock, calendar, time together ---------- */
  const today = new Date();
  const locale = t.locale;
  q('.x-day').textContent = today.toLocaleDateString(t.locale, { weekday: 'long' });
  q('.x-num').textContent = String(today.getDate());
  function tick() {
    const t = together(), now = new Date();
    const set = (s: string, v: number) => qa(s).forEach(e => { e.textContent = fmt(v); });
    set('.s-hours', t.hours); set('.s-weekends', t.weekends); set('.s-secs', t.secs); set('.s-days', t.days); set('.s-anniv', t.toAnniversary);
    q('.clock').textContent = now.toLocaleDateString(locale, { weekday: 'short' }) + ' ' + now.toLocaleTimeString(locale, { hour: 'numeric', minute: '2-digit' });
  }
  tick();
  const clock = setInterval(tick, 1000);

  /* ---------- camera: wide on the whole screen, close on the notch ---------- */
  let shot: Shot = 'wide';
  function applyCam() {
    const [zw, oy] = SHOTS[phone.matches ? 'phone' : 'desktop'][shot], w = shell.clientWidth, k = w / zw;
    desk.style.transform = `translate(${w / 2 - CX * k}px, ${oy * k}px) scale(${k})`;
  }
  const camera = (s: Shot) => { shot = s; applyCam(); };
  // Sizing (first paint, resize) jumps straight to the shot; only camera moves glide.
  const ro = new ResizeObserver(() => {
    desk.style.transition = 'none'; applyCam(); void desk.offsetWidth; desk.style.transition = '';
    shell.classList.add('ready');
  });
  ro.observe(shell);

  /* ---------- the notch ---------- */
  let bannerAnim: Animation | null = null;
  const isOpen = () => notch.classList.contains('open');
  function endBanner() { notch.classList.remove('banner'); bannerAnim = null; }
  // Jump to the end rather than cancel, so the text stays off-strip instead of snapping back into view.
  function stopBanner() { if (!bannerAnim) return; bannerAnim.onfinish = null; bannerAnim.finish(); endBanner(); }
  const open = () => { if (!isOpen()) { stopBanner(); notch.classList.add('open'); } };
  const close = () => notch.classList.remove('open');
  function showBanner(text: string, speed = 85) {
    banner.innerHTML = `<b>bun</b>&nbsp;&nbsp;${text}`;
    notch.classList.add('banner');
    const w = banner.offsetWidth, strip = 234;
    bannerAnim = banner.animate([{ transform: `translateX(${strip}px)` }, { transform: `translateX(${-w}px)` }],
      { duration: (strip + w) / speed * 1000, delay: 300, fill: 'both' });
    bannerAnim.onfinish = endBanner;
  }
  // Their mood, as in the app: on the right of the closed notch with its word, and in Home's mood widget.
  function setMood(e: string) {
    qa('.n-mood, .n-mood2').forEach(m => { m.textContent = e; });
    qa('.n-word, .n-word2').forEach(w => { w.textContent = d.moodWords[e] ?? ''; });
    q('.n-right').animate([{ transform: 'scale(0)' }, { transform: 'scale(1.3)' }, { transform: 'scale(1)' }], { duration: 450, easing: 'cubic-bezier(.3,1.6,.5,1)' });
  }
  const tab = (t: string) => {
    qa('.tabbar button').forEach(b => b.classList.toggle('on', b.dataset.tab === t));
    qa('.pane').forEach(p => p.classList.toggle('on', p.dataset.pane === t));
  };
  // A soft pink glow on whatever the characters are talking about.
  const glow = (el: Element) => act(el, 'x-glow', 1800);

  /* ---------- the cast ---------- */
  const say = (who: Who, text: string, ms = 2600) => { const b = q(`.bubble-${who}`); b.textContent = text; act(b, 'show', ms); };
  function bunLoves(text: string) { act(pip, 'is-tap', 450); act(bun, 'is-jump', 800); act(bun, 'is-love', 2200); say('bun', text, 2000); }

  /* ---------- effects out of the notch ---------- */
  const heart = '<svg viewBox="-11 -11 22 19" width="100%"><use href="#hrt"/></svg>';
  function fxPour(n = 3) {
    for (let i = 0; i < n; i++) {
      const el = document.createElement('div'); el.innerHTML = heart; fx.appendChild(el);
      const size = rand(17, 25), x = fx.clientWidth / 2 + rand(-50, 50) - size / 2, sway = rand(6, 8) * (i % 2 ? 1 : -1);
      el.style.width = size + 'px';
      el.animate([
        { transform: `translate(${x}px,20px) scale(.2)`, opacity: 0 },
        { transform: `translate(${x + sway}px,60px) rotate(${sway}deg) scale(1)`, opacity: 1, offset: .3 },
        { transform: `translate(${x - sway}px,152px) rotate(${-sway}deg)`, opacity: 0 },
      ], { duration: 1500, delay: i * 250, easing: 'ease-out', fill: 'backwards' }).onfinish = () => el.remove();
    }
  }
  function fxSplash(emoji: string) {
    for (let i = 0; i < 18; i++) {
      const el = document.createElement('div'); el.textContent = emoji; fx.appendChild(el);
      const size = rand(14, 32), x = rand(20, fx.clientWidth - 40), h = fx.clientHeight;
      el.style.fontSize = size + 'px';
      el.animate([
        { transform: `translate(${x}px,${h + 10}px)`, opacity: 0 },
        { transform: `translate(${x + rand(-14, 14)}px,${h - 80}px) rotate(${rand(-15, 15)}deg)`, opacity: 1, offset: .2 },
        { transform: `translate(${x + rand(-30, 30)}px,${h - 350}px) rotate(${rand(-20, 20)}deg)`, opacity: 0 },
      ], { duration: 3000, delay: i * 80, easing: 'ease-out', fill: 'backwards' }).onfinish = () => el.remove();
    }
  }

  /* ---------- the open notch's tabs ---------- */
  const noteState = (text: string, cls: string) => { noteStatus.textContent = text; noteStatus.className = 'note-status ' + cls; };
  function typeNote(text: string) {
    [...text].forEach((_, i) => later(() => {
      noteIn.value = text.slice(0, i + 1);
      noteState(fill(t.ofWords, { n: noteIn.value.trim().split(/\s+/).length }), 'ter');
    }, i * 70));
    const done = text.length * 70;
    later(() => noteState(t.sending, 'sec'), done + 250);
    later(() => { noteState(t.delivered, 'pk'); addMine(text); bunLoves('🥹'); }, done + 850);
  }
  // The whisper joins the conversation as your pink bubble, and the field clears.
  function addMine(text: string) {
    const b = document.createElement('span'); b.className = 'bub mine new'; b.textContent = text;
    q('.conv').appendChild(b); pop(b); noteIn.value = '';
  }
  function sendEmoji(i: number) {
    const buttons = qa('.emojis button'), b = buttons[i], e = b.textContent!, st = q('.emoji-status');
    buttons.forEach(x => x.classList.toggle('last', x === b));
    for (let j = 0; j < 3; j++) {
      const s = document.createElement('span'); s.className = 'pop'; s.textContent = e; b.appendChild(s);
      s.animate([{ transform: 'translate(0,0)', opacity: 1 }, { transform: `translate(${(j - 1) * 10}px,-40px)`, opacity: 0 }],
        { duration: 900, delay: j * 70, fill: 'backwards' }).onfinish = () => s.remove();
    }
    st.textContent = fill(t.sent, { e }); st.className = 'st emoji-status';
    later(() => { st.textContent = fill(t.deliveredE, { e }); st.className = 'st emoji-status pk'; bunLoves(e + '!!'); }, 1200);
    later(() => { st.textContent = d.tapToSend; st.className = 'st emoji-status ter'; b.classList.remove('last'); }, 4200);
  }
  const PHOTO_TEXT = ['.p-eye', '.p-title', '.p-body', '.pbtn'].map(s => [s, q(s).textContent] as const);
  function resetPhoto() {
    const tile = q('.ptile'); tile.classList.remove('has'); tile.querySelector('.x-pic')?.remove();
    q('.pbtn').classList.remove('bordered');
    PHOTO_TEXT.forEach(([s, t]) => { q(s).textContent = t; });
  }
  const pop = (el: Element) => el.animate([{ transform: 'scale(.55)', opacity: 0 }, { transform: 'none', opacity: 1 }], { duration: 520, easing: 'cubic-bezier(.3,1.4,.5,1)' });
  function sendPhoto() {
    const tile = q('.ptile'), pic = sunday.cloneNode(true) as HTMLElement;
    tile.classList.add('has'); tile.prepend(pic); pop(pic);
    q('.p-title').textContent = t.lastSent; q('.p-body').textContent = t.staysHome;
    q('.pbtn').textContent = t.sendNew; q('.pbtn').classList.add('bordered');
    q('.p-eye').textContent = t.justSending;
    later(() => { q('.p-eye').textContent = t.justDelivered; bunLoves(L[13]); }, 1400);
  }
  // What bun sent lands on Pip's Home: the new photo pops in, and the note tile shows the latest note.
  function homeArrives() {
    const pic = sunday.cloneNode(true) as HTMLElement;
    pic.querySelector('span')?.remove();
    selfie.replaceChildren(pic); pop(pic);
    q('.ph .cap').textContent = t.fromBunNow;
    q('.notetile .when').textContent = t.bunNow;
    q('.notetile .txt').textContent = d.ticker;
    glow(q('.ph'));
  }
  function reset() {
    stopBanner(); close(); tab('home'); setMood('🥰'); qa('.conv .new').forEach(b => b.remove());
    noteIn.value = ''; noteState(d.upTo, 'ter');
    resetPhoto();
    selfie.innerHTML = selfieHTML; q('.ph .cap').textContent = d.fromBun1h;
    q('.notetile .when').textContent = d.bun2m; q('.notetile .txt').textContent = d.favorite;
  }

  /* ---------- the script ---------- */
  // A real back-and-forth: one line at a time with a beat between, and the last shot (wide, notch closed)
  // is where the first one starts, so the loop has no seam.
  const L = t.lines;
  const STEPS: Step[] = [
    [2800, 'pip', L[0], () => { reset(); camera('close'); later(() => glow(q('.n-av')), 1000); }],
    [3000, 'bun', L[1], () => { close(); setMood('☕️'); glow(q('.n-right')); act(bun, 'is-happy', 1600); }],
    [3000, 'bun', L[2], () => { close(); act(bun, 'is-tap', 450); showBanner(d.ticker); }],
    [3200, 'pip', L[3], () => act(pip, 'is-love', 2200)],
    [3000, 'bun', L[4], () => { close(); act(bun, 'is-tap', 450); fxPour(); act(pip, 'is-love', 2000); glow(q('.n-right')); }],
    [3400, 'bun', L[5], () => {
      close(); camera('wide'); act(bun, 'is-jump', 800);
      later(() => { fxSplash('🥰'); act(pip, 'is-love', 2400); }, 700);
    }],
    [3800, 'pip', L[6], () => {
      camera('mid'); tab('home');
      later(open, 600); later(homeArrives, 1300); later(() => say('bun', L[7], 1900), 1700);
    }, 1600],
    [3000, 'pip', L[8], () => { open(); tab('together'); glow(q('.tg-grid')); }],
    [4400, 'pip', L[9], () => { open(); tab('note'); typeNote(L[10]); }, 1600],
    [3800, 'pip', L[11], () => { open(); tab('emoji'); later(() => sendEmoji(2), 500); }, 1500],
    [4400, 'pip', L[12], () => { open(); tab('photo'); later(sendPhoto, 600); }, 1700],
    [3000, 'bun', L[10], () => { close(); camera('wide'); act(bun, 'is-happy', 1800); }],
  ];
  function play() {
    let t = 0;
    for (const [ms, who, line, run, up = ms - 500] of STEPS) {
      later(() => { run(); say(who, line, up); }, t);
      t += ms;
    }
    later(play, t);
  }

  if (reduce) { camera('mid'); open(); homeArrives(); } // a still frame
  else later(play, 700); // hold the wide shot for a moment, then glide in

  return () => { timers.forEach(clearTimeout); clearInterval(clock); ro.disconnect(); };
}
