// The invite email a buyer sends their love from the app, in the landing page's look (Pip and Bun on blush,
// the code on butter, the pink button). Table layout and inline styles, so it holds up in Gmail and Outlook.

const SITE = 'https://ournotch.app';

const COPY = {
  en: {
    subject: (n) => `${n} planned a surprise for you ♡`,
    pre: (c) => `your invite code is ${c} ♡ it works for 24 hours`,
    kicker: 'a surprise for you',
    h1: (n) => `${n} made you a little place in your Mac's notch&nbsp;♡`,
    p: (n) => `Hearts, notes, moods and photos from ${n} will pop out of the top of your screen. Tap back and they land on theirs.`,
    codeLabel: 'your invite code', works: 'works for 24 hours',
    s1: "<b>Download OurNotch</b>, it's free for you",
    s2: 'Open it and choose <b>I Have an Invite Code</b>',
    s3: (c) => `Type <b>${c}</b> and say hi ♡`,
    button: 'Download OurNotch', needs: 'for Macs with macOS 14 Sonoma or later',
    love: 'love,', alt: 'Two little friends sharing a heart',
    footer: (a) => `Sent with ${a} · a notch made for two`,
  },
  fr: {
    subject: (n) => `${n} t'a préparé une surprise ♡`,
    pre: (c) => `ton code d'invitation est ${c} ♡ valable 24 heures`,
    kicker: 'une surprise pour toi',
    h1: (n) => `${n} t'a créé un petit coin dans l'encoche de ton&nbsp;Mac&nbsp;♡`,
    p: (n) => `Les cœurs, mots, humeurs et photos de ${n} sortiront du haut de ton écran. Réponds d'un geste et ils arrivent chez l'autre.`,
    codeLabel: "ton code d'invitation", works: 'valable 24 heures',
    s1: '<b>Télécharge OurNotch</b>, gratuit pour toi',
    s2: "Ouvre-le et choisis <b>J'ai un code d'invitation</b>",
    s3: (c) => `Tape <b>${c}</b> et dis coucou ♡`,
    button: 'Télécharger OurNotch', needs: 'pour les Mac sous macOS 14 Sonoma ou plus récent',
    love: 'bisous,', alt: 'Deux petits amis qui partagent un cœur',
    footer: (a) => `Envoyé avec ${a} · une encoche pour deux`,
  },
  de: {
    subject: (n) => `${n} hat eine Überraschung für dich ♡`,
    pre: (c) => `dein Einladungscode ist ${c} ♡ er gilt 24 Stunden`,
    kicker: 'eine Überraschung für dich',
    h1: (n) => `${n} hat dir ein kleines Plätzchen in der Notch deines Macs&nbsp;geschenkt&nbsp;♡`,
    p: (n) => `Herzen, Notizen, Stimmungen und Fotos von ${n} tauchen oben auf deinem Bildschirm auf. Tipp zurück, und sie landen beim anderen.`,
    codeLabel: 'dein Einladungscode', works: 'gilt 24 Stunden',
    s1: '<b>Lade OurNotch herunter</b>, für dich kostenlos',
    s2: 'Öffne es und wähle <b>Ich habe einen Einladungscode</b>',
    s3: (c) => `Gib <b>${c}</b> ein und sag hallo ♡`,
    button: 'OurNotch laden', needs: 'für Macs mit macOS 14 Sonoma oder neuer',
    love: 'in Liebe,', alt: 'Zwei kleine Freunde mit einem Herz',
    footer: (a) => `Gesendet mit ${a} · eine Notch für zwei`,
  },
};

const esc = (s) => s.replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch]);

const DISP = "'Bricolage Grotesque','Helvetica Neue',Helvetica,Arial,sans-serif";
const BODY = "'Inter Tight','Helvetica Neue',Helvetica,Arial,sans-serif";

function step(n, color, html) {
  return `<tr><td valign="top" style="padding:0 12px 14px 0"><span style="display:inline-block;width:28px;height:28px;border-radius:14px;background:${color};text-align:center;font:600 14px/28px ${BODY}">${n}</span></td>
<td valign="top" style="padding:3px 0 14px">${html}</td></tr>`;
}

/** `name` is the sender's name as typed in the app; it is escaped here. Returns { subject, html, text }. */
export function inviteEmail({ name, code, lang, download }) {
  const t = COPY[lang] ?? COPY.en;
  const n = esc(name);
  const html = `<!doctype html>
<html lang="${lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light only"><title>${esc(t.subject(name))}</title>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@800&family=Inter+Tight:wght@400;600&display=swap" rel="stylesheet"></head>
<body style="margin:0;padding:0;background:#F5F4F1;-webkit-text-size-adjust:100%">
<div style="display:none;max-height:0;overflow:hidden">${t.pre(code)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F5F4F1"><tr><td align="center" style="padding:32px 16px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px">
<tr><td align="center" style="padding-bottom:20px"><img src="${SITE}/apple-touch-icon.png" width="32" height="32" alt="" style="vertical-align:middle;border-radius:8px"><span style="vertical-align:middle;font:800 22px/1 ${DISP};letter-spacing:-.04em;color:#16141A;padding-left:8px">OurNotch</span></td></tr>
<tr><td style="background:#ffffff;border-radius:32px;overflow:hidden">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0">
<tr><td style="background:#FFD3DC;border-radius:32px 32px 0 0"><img src="${SITE}/email/pair.png" width="560" alt="${t.alt}" style="display:block;width:100%;max-width:560px;height:auto;border-radius:32px 32px 0 0"></td></tr>
<tr><td style="padding:36px 36px 8px;font-family:${BODY};color:#16141A">
<p style="margin:0 0 12px;font:600 13px/1 ${BODY};letter-spacing:.08em;text-transform:uppercase;color:#FF375F">${t.kicker}</p>
<h1 style="margin:0 0 16px;font:800 40px/1 ${DISP};letter-spacing:-.045em;color:#16141A">${t.h1(n)}</h1>
<p style="margin:0;font-size:17px;line-height:1.55;color:#5E5A66">${t.p(n)}</p></td></tr>
<tr><td style="padding:28px 36px 8px"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FFE9A6;border-radius:24px"><tr><td align="center" style="padding:24px 16px">
<p style="margin:0 0 10px;font:600 13px/1 ${BODY};letter-spacing:.08em;text-transform:uppercase;color:#5E5A66">${t.codeLabel}</p>
<p style="margin:0;font:800 44px/1 ${DISP};letter-spacing:.14em;color:#16141A">${code}</p>
<p style="margin:12px 0 0;font:400 14px/1.4 ${BODY};color:#5E5A66">${t.works}</p></td></tr></table></td></tr>
<tr><td style="padding:24px 36px 0;font-family:${BODY};font-size:16px;line-height:1.5;color:#16141A"><table role="presentation" cellpadding="0" cellspacing="0">
${step(1, '#CFE3FF', t.s1)}${step(2, '#CFEFDF', t.s2)}${step(3, '#FFD3DC', t.s3(code))}</table></td></tr>
<tr><td align="center" style="padding:32px 36px 12px"><a href="${download}" style="display:inline-block;background:#FF375F;color:#ffffff;text-decoration:none;font:600 17px/1 ${BODY};padding:18px 30px;border-radius:999px">♥&nbsp; ${t.button}</a></td></tr>
<tr><td align="center" style="padding:0 36px 36px;font:400 13px/1.5 ${BODY};color:#5E5A66">${t.needs}</td></tr>
<tr><td style="padding:24px 36px 32px;border-top:1px solid #F0EEEA;font:400 17px/1.5 ${BODY};color:#16141A">${t.love}<br><span style="font:800 26px/1.3 ${DISP};letter-spacing:-.03em">${n}</span></td></tr>
</table></td></tr>
<tr><td align="center" style="padding:24px 16px 8px;font:400 13px/1.5 ${BODY};color:#8A8690">${t.footer(`<a href="${SITE}" style="color:#5E5A66;font-weight:600;text-decoration:none">OurNotch</a>`)}</td></tr>
</table></td></tr></table></body></html>`;
  const strip = (s) => s.replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ');
  const text = [strip(t.h1(name)), '', strip(t.p(name)), '', `${t.codeLabel}: ${code} (${t.works})`, '',
    `1. ${strip(t.s1)}: ${download}`, `2. ${strip(t.s2)}`, `3. ${strip(t.s3(code))}`, '', `${t.love} ${name}`].join('\n');
  return { subject: t.subject(name), html, text };
}
