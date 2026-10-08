import { notFound } from 'next/navigation';
import { Char, Heart, SvgDefs } from '@/components/Char';
import { HeroDemo } from '@/components/HeroDemo';
import { MiniNotch } from '@/components/Notch';
import { copy } from '@/lib/i18n';

// Social media graphics, laid out with the site's own characters, notch and type, then captured to PNG/MP4
// by the agent. Dev server only: production answers 404. Open /social?card=<name>.
const t = copy.en;
const MOODS = ['🥰', '😊', '🥺', '🎉', '☕️', '🍕', '💻', '🎧', '🏃', '😴', '😔', '🤒'];

const SIZES = { square: [1080, 1080], feed: [1080, 1350], story: [1080, 1920] } as const;
type Size = keyof typeof SIZES;

function Frame({ size, bg, kicker, title, children, foot = 'ournotch.app' }: {
  size: Size; bg: string; kicker?: string; title: React.ReactNode; children: React.ReactNode; foot?: string;
}) {
  const [w, h] = SIZES[size];
  return (
    <div className={`s-frame ${bg}`} style={{ width: w, height: h }}>
      <div className="s-top">
        <span className="s-logo"><span className="y-logo-notch"><Heart /></span>OurNotch</span>
        {kicker && <span className="s-kicker">{kicker}</span>}
      </div>
      <h1 className="s-title">{title}</h1>
      <div className="s-art">{children}</div>
      <div className="s-foot">{foot}</div>
    </div>
  );
}

const Notch = ({ zoom, ...p }: { zoom: number; mood: string; ticker?: string; tall?: boolean }) =>
  <div className="s-notch" style={{ zoom }}><MiniNotch {...p} /></div>;

const CARDS: Record<string, () => React.ReactNode> = {
  hero: () => (
    <Frame size="square" bg="y-blush s-hero" title={<>Your notch was empty.<br /><em>Now it isn&apos;t ♡</em></>}>
      <Notch zoom={3.2} mood="🥰" tall ticker="miss you already ♡" />
      <div className="s-pals"><Char kind="pip" className="is-love" /><Char kind="bun" className="is-happy" /></div>
    </Frame>
  ),
  note: () => (
    <Frame size="feed" bg="y-butter" kicker="Notes" title={<>Ten words or fewer.<br /><em>Straight to their notch.</em></>}>
      <Notch zoom={3.4} mood="🥰" tall ticker={t.bento.ticker} />
      <p className="s-body">{t.bento.noteBody}</p>
      <div className="s-pals s-one"><Char kind="pip" className="is-happy" /></div>
    </Frame>
  ),
  emoji: () => (
    <Frame size="feed" bg="y-blush" kicker="Emoji" title={<>One tap.<br /><em>Hearts pour out.</em></>}>
      <div className="s-drips">
        <Notch zoom={3.4} mood="😘" />
        {/* Hearts pouring out, placed by hand so a still image catches them mid-fall. */}
        {[[-260, 150, 70, 0, -14], [-90, 230, 90, 1, 10], [70, 170, 64, 0, 18], [220, 270, 80, 1, -8], [-200, 360, 56, 1, 12], [130, 400, 74, 0, -16], [-20, 470, 50, 0, 6]]
          .map(([x, y, w, c, r], i) => (
            <svg key={i} className="s-heart" viewBox="-12 -12 24 21" width={w}
              style={{ left: `calc(50% + ${x}px)`, top: y, fill: c ? '#FFB3C2' : '#FF375F', transform: `rotate(${r}deg)` }}><use href="#hrt" /></svg>
          ))}
      </div>
      <p className="s-body">{t.bento.heartBody}</p>
      <div className="s-pals s-one s-right s-small"><Char kind="bun" className="is-love" /></div>
    </Frame>
  ),
  mood: () => (
    <Frame size="feed" bg="y-mint" kicker="Moods" title={<>How you are,<br /><em>at a glance.</em></>}>
      <div className="s-moods">{MOODS.map((e, i) => <span key={e} className={i === 2 ? 'on' : ''}><b>{e}</b>{t.bento.moods[i]}</span>)}</div>
      <p className="s-body">{t.bento.moodBody}</p>
    </Frame>
  ),
  photo: () => (
    <Frame size="feed" bg="y-sky" kicker="Photos" title={<>A photo that waits<br /><em>on their Home.</em></>}>
      <div className="s-polas">
        <div className="b-polaroid s-back"><div className="b-shot" /><b>us ♡</b></div>
        <div className="b-polaroid s-front"><div className="b-shot x-sun"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /></div><b>sunday ♡</b></div>
      </div>
      <p className="s-body">{t.bento.photoBody}</p>
    </Frame>
  ),
  private: () => (
    <Frame size="feed" bg="y-mist" kicker="Private" title={<>Only your two Macs<br /><em>can read it.</em></>}>
      <div className="s-list">{t.details.items.slice(0, 4).map(([ic, hd, p]) => <div key={hd}><span>{ic}</span><div><b>{hd}</b><p>{p}</p></div></div>)}</div>
    </Frame>
  ),
  price: () => (
    <Frame size="feed" bg="y-mint" kicker="Pricing" title={<>One purchase.<br /><em>Both Macs.</em></>}>
      <div className="s-prices"><span>$4.50</span><span>₹200</span><span>€3</span></div>
      <p className="s-body">One time, no subscription. Your love downloads it free and joins with your invite code.</p>
      <div className="s-pals"><Char kind="pip" className="is-happy" /><Char kind="bun" className="is-love" /></div>
    </Frame>
  ),
  story: () => (
    <Frame size="story" bg="y-blush s-story" kicker="Launching this week" title={<>Send love,<br /><em>notch to notch.</em></>}>
      <Notch zoom={4} mood="🥰" tall ticker="see you at 1 ♡" />
      <p className="s-body">Notes, emoji, moods and photos that appear in your person&apos;s MacBook notch.</p>
      <div className="s-pals s-big"><Char kind="pip" className="is-love" /><Char kind="bun" className="is-happy" /></div>
    </Frame>
  ),
  'demo-feed': () => (
    <Frame size="feed" bg="s-white" title={<>Send love,<br /><em>notch to notch.</em></>}>
      <div className="s-demo"><HeroDemo t={t.demo} tour={t.tour} /></div>
    </Frame>
  ),
  'demo-story': () => (
    <Frame size="story" bg="s-white" kicker="Launching this week" title={<>Send love,<br /><em>notch to notch.</em></>}>
      <div className="s-demo s-demo-story"><HeroDemo t={t.demo} tour={t.tour} /></div>
      <p className="s-body s-center">One purchase covers both your Macs.</p>
    </Frame>
  ),
};

export default async function Social({ searchParams }: { searchParams: Promise<{ card?: string }> }) {
  if (process.env.NODE_ENV !== 'development') notFound();
  const card = (await searchParams).card;
  if (!card || !CARDS[card]) {
    return <main style={{ padding: 40 }}>{Object.keys(CARDS).map(c => <p key={c}><a href={`?card=${c}`}>{c}</a></p>)}</main>;
  }
  return (
    <>
      <SvgDefs />
      <style>{`
        body{margin:0;background:#888}
        nextjs-portal{display:none!important}
        .s-frame{position:relative;overflow:hidden;display:flex;flex-direction:column;padding:72px 80px 64px;box-sizing:border-box}
        .s-white{background:#fff}
        .s-top{display:flex;justify-content:space-between;align-items:center}
        .s-logo{display:flex;align-items:center;gap:14px;font:800 38px var(--disp);letter-spacing:-.04em}
        .s-logo .y-logo-notch{width:56px;height:23px;top:-6px}.s-logo .y-logo-notch svg{width:13px}
        .s-kicker{font:600 22px var(--body);letter-spacing:.08em;text-transform:uppercase;background:#fff;border-radius:999px;padding:12px 22px}
        .s-title{margin-top:56px;font:800 104px/.95 var(--disp);letter-spacing:-.055em}
        .s-title em{font-style:normal;background:var(--butter);border-radius:.16em;padding:0 .1em;-webkit-box-decoration-break:clone;box-decoration-break:clone}
        .y-butter .s-title em,.y-mint .s-title em{background:#fff}
        .s-art{flex:1;position:relative;display:flex;flex-direction:column;justify-content:center;align-items:center;gap:44px}
        .s-notch{position:relative;width:250px;height:54px;flex:none}
        .s-notch .x-mini{width:230px}.s-notch .x-mini.x-tall{height:54px}.s-notch .x-tick{top:30px;-webkit-mask:none;mask:none}
        .s-notch .x-tick span{animation:none;position:static;display:block;text-align:center}
        .s-body{font:500 34px/1.35 var(--body);color:var(--ink3);text-align:center;max-width:860px;margin:0}
        .s-center{margin-top:40px}
        .s-pals{display:flex;gap:40px}.s-pals .char{width:220px}.s-big .char{width:300px}
        .s-one{position:absolute;bottom:-40px;left:0}.s-right{left:auto;right:0}
        .s-drips{position:relative;width:100%;height:500px;display:flex;justify-content:center}
        .s-heart{position:absolute;stroke:var(--ink);stroke-width:1.6;stroke-linejoin:round;overflow:visible}
        .s-moods{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;width:100%}
        .s-moods span{background:rgba(255,255,255,.6);border-radius:32px;padding:26px 8px;display:flex;flex-direction:column;align-items:center;gap:10px;font:500 25px var(--body);color:var(--ink3)}
        .s-moods span.on{background:#fff;box-shadow:inset 0 0 0 4px var(--ink)}.s-moods b{font-size:56px;font-weight:400;line-height:1}
        .s-polas{position:relative;width:640px;height:520px}.s-polas .b-polaroid{position:absolute;width:380px;zoom:1}
        .s-polas .b-polaroid b{font-size:32px;line-height:76px}.s-polas .b-shot{height:380px;border-radius:12px}
        .s-back{left:20px;top:30px;transform:rotate(-8deg)}.s-front{right:20px;top:0;transform:rotate(6deg)}
        .s-polas .b-shot .char{width:150px}
        .s-list{display:grid;gap:26px;width:100%}.s-list>div{display:flex;gap:26px;align-items:flex-start;background:#fff;border-radius:32px;padding:30px 34px}
        .s-list span{font-size:56px;line-height:1}.s-list b{font:800 38px var(--disp);letter-spacing:-.03em}.s-list p{margin:6px 0 0;font:500 26px/1.35 var(--body);color:var(--ink3)}
        .s-prices{display:flex;gap:22px}.s-prices span{background:#fff;border-radius:36px;padding:28px 40px;font:800 84px/1 var(--disp);letter-spacing:-.05em}
        .s-demo{width:100%;margin-top:120px}.s-demo-story{margin-top:200px}
        .s-hero .s-title{font-size:88px;margin-top:40px}.s-hero .s-art{gap:36px;padding-top:20px}
        .s-small{bottom:-60px}.s-small .char{width:170px}
        .s-story .s-title{font-size:132px;margin-top:90px}.s-story .s-body{font-size:42px}.s-story .s-kicker{font-size:26px}
        .s-foot{text-align:center;font:800 40px var(--disp);letter-spacing:-.03em;margin-top:28px}
      `}</style>
      {CARDS[card]()}
    </>
  );
}
