'use client';

import { useEffect, useRef } from 'react';
import type { Copy } from '@/lib/i18n';
import { runHeroTour } from '@/lib/hero-tour';
import { Char, Heart } from './Char';

const TABS = [
  ['home', <path d="M2.5 7.5 8 3l5.5 4.5V13a.5.5 0 0 1-.5.5H10V10H6v3.5H3a.5.5 0 0 1-.5-.5z" />],
  ['note', <path d="M3 3h10a1 1 0 0 1 1 1v5.5a1 1 0 0 1-1 1H7.5L4.5 13v-2.5H3a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z" />],
  ['emoji', <><circle cx="8" cy="8" r="5.8" /><path d="M5.6 9.4c1.2 1.4 3.6 1.4 4.8 0M6 6.4h.01M10 6.4h.01" /></>],
  ['mood', <><path d="M5 13h6.5a2.5 2.5 0 0 0 .2-5A3.6 3.6 0 0 0 5.2 7 3 3 0 0 0 5 13z" /><path d="M11 2.2v1M13.8 3.4l-.7.7M15 6h-1" /></>],
  ['photo', <><rect x="2" y="3" width="12" height="10" rx="1.6" /><path d="m2.5 11.5 3.5-3.5 3 3 2-2 2.5 2.5" /><circle cx="10.5" cy="6" r="1" /></>],
] as const;

// The hero "video": the real notch UI, played by a script. Nothing in it reacts to the pointer.
export function HeroDemo({ t, tour }: { t: Copy['demo']; tour: Copy['tour'] }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => runHeroTour(ref.current!, t, tour), [t, tour]);

  return (
    <div className="x-stage" id="play" ref={ref} role="img"
      aria-label={t.aria}>
      <div className="x-cast">
        <div className="pal pal-pip"><Char kind="pip" /></div>
        <div className="pal pal-bun"><Char kind="bun" /></div>
        <div className="bubble bubble-pip" />
        <div className="bubble bubble-bun" />
      </div>

      <div className="x-video" inert>
        <div className="demo-shell">
          <div className="desk">
            <div className="screen">
              <div className="menubar">
                <span className="mbl"><span><b>Finder</b></span>{t.menus.map(m => <span key={m}>{m}</span>)}</span>
                <span className="clock" />
              </div>
              <div className="x-widget x-w-photo">
                <div className="x-pic"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /><span>{t.us}</span></div>
              </div>
              <div className="x-widget x-w-cal">
                <div className="x-day" /><div className="x-num" />
                <div className="x-ev">{t.event}<small>{t.eventWhen}</small></div>
              </div>
              <div className="fx" />
              <div className="camera" />

              <div className="notch">
                <div className="n-closed">
                  <span className="n-who"><span className="n-av"><Char kind="bun" className="is-happy" /></span><span className="n-mood">🥰</span></span>
                  <Heart className="n-heart" />
                  <div className="n-banner"><span /></div>
                </div>

                <div className="n-open">
                  <div className="n-top">
                    <span>{t.you}<span className="hr">♥</span>bun</span>
                    <svg viewBox="0 0 16 16"><circle cx="8" cy="8" r="2.2" strokeWidth="1.4" /><circle cx="8" cy="8" r="5.3" strokeWidth="2.6" strokeDasharray="2.1 2" /></svg>
                  </div>

                  <div className="pane on" data-pane="home">
                    <div className="ph">
                      <div className="chars"><Char kind="pip" className="is-happy" style={{ left: -6 }} /><Char kind="bun" className="is-love" style={{ right: -8 }} /></div>
                      <span className="cap">{t.fromBun1h}</span>
                    </div>
                    <div className="rcol">
                      <div className="tile notetile">
                        <span className="who sec"><Heart /><span className="when">{t.bun2m}</span></span>
                        <span className="txt">{t.favorite}</span>
                      </div>
                      <div className="stats">
                        <div className="tile stat"><span className="l">{t.hours}</span><span className="v s-hours">…</span></div>
                        <div className="tile stat"><span className="l">{t.weekends}</span><span className="v s-weekends">…</span></div>
                        <div className="tile stat"><span className="l">{t.seconds} <Heart /></span><span className="v pk s-secs">…</span></div>
                      </div>
                    </div>
                  </div>

                  <div className="pane" data-pane="note">
                    <div className="card">
                      <div className="their"><div className="l sec">{t.from2m}</div><div className="t">{t.ticker}</div></div>
                      <div>
                        <div className="composer">
                          <input readOnly placeholder={t.placeholder} aria-hidden="true" />
                          <span className="send"><svg viewBox="0 0 16 16"><path d="M8 13V3M3.5 7.5 8 3l4.5 4.5" /></svg></span>
                        </div>
                        <div className="foot" style={{ marginTop: 8 }}>
                          <span><span className="lbl sec">{t.scroll}</span><span className="seg"><span className="on">{t.three}</span><span>{t.untilOpened}</span></span></span>
                          <span className="note-status ter">{t.upTo}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="pane" data-pane="emoji">
                    <div className="card">
                      <div className="hrow">
                        <div><h4>{t.sendEmoji}</h4><p className="sec">{t.popsUp}</p></div>
                        <span className="st emoji-status ter">{t.tapToSend}</span>
                      </div>
                      <div className="emojis">{['❤️', '🥰', '😘', '🫶', '🤗', '🌹'].map(e => <button key={e} type="button">{e}</button>)}</div>
                      <div className="foot"><span><span className="lbl sec">{t.appears}</span><span className="seg"><span className="on">{t.outOfNotch}</span><span>{t.fullScreen}</span></span></span></div>
                    </div>
                  </div>

                  <div className="pane" data-pane="photo">
                    <div className="card prow">
                      <div className="ptile"><svg viewBox="0 0 24 24"><rect x="3" y="5" width="15" height="13" rx="2" /><path d="m3 15 4-4 4 4 3-3 4 4M19 3v6M16 6h6" /></svg></div>
                      <div className="pcol">
                        <span className="e sec p-eye">{t.photo}</span>
                        <span className="ti p-title">{t.sendPhoto}</span>
                        <span className="b sec p-body">{t.showsUp}</span>
                        <span className="pbtn">{t.choose}</span>
                      </div>
                    </div>
                  </div>

                  <div className="tabbar">
                    {TABS.map(([id, icon], i) => (
                      <button key={id} type="button" data-tab={id} className={id === 'home' ? 'on' : ''}><svg viewBox="0 0 16 16">{icon}</svg>{t.tabs[i]}</button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* the photo that gets sent, cloned in by the script */}
      <div className="x-tpl" hidden>
        <div className="x-pic x-sun"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /><span>{t.sunday}</span></div>
      </div>
    </div>
  );
}
