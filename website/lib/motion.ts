export const rand = (a: number, b: number) => a + Math.random() * (b - a);
export const fmt = (n: number) => n.toLocaleString('en-US');

// Add a class for a moment, restarting its animation if it's already running.
const timers = new WeakMap<Element, Record<string, number>>();
export function act(el: Element, cls: string, ms: number) {
  el.classList.remove(cls); el.getBoundingClientRect(); el.classList.add(cls);
  const t = timers.get(el) || {}; clearTimeout(t[cls]);
  t[cls] = window.setTimeout(() => el.classList.remove(cls), ms); timers.set(el, t);
}

// One shared "together since" date for every counter on the page.
const START = new Date(2022, 4, 21, 19, 30);
export function together(now = new Date()) {
  const ms = +now - +START, days = Math.floor(ms / 864e5);
  const firstSat = (6 - START.getDay() + 7) % 7;
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let next = new Date(now.getFullYear(), START.getMonth(), START.getDate());
  if (next < today) next = new Date(now.getFullYear() + 1, START.getMonth(), START.getDate());
  const toAnniversary = Math.round((+next - +today) / 864e5);
  return { days, hours: Math.floor(ms / 36e5), secs: Math.floor(ms / 1e3), weekends: days >= firstSat ? Math.floor((days - firstSat) / 7) + 1 : 0, toAnniversary };
}
