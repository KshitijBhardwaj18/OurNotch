// Every word on the site, in English, French and German (devpost/spec-m2.md > Website Pages).
// English lives at /, French at /fr, German at /de. Placeholders look like {name}; fill() fills them.
// French and German use the informal tu / du, like the app. A native speaker checks them before launch.

export type Lang = 'en' | 'fr' | 'de';
export const LANGS: Lang[] = ['en', 'fr', 'de'];
export const LANG_NAMES: Record<Lang, string> = { en: 'English', fr: 'Français', de: 'Deutsch' };
export const SUPPORT = 'hello@ournotch.app';

// A path in a language: href('fr', '/thanks') → '/fr/thanks'.
export const href = (lang: Lang, path = '/') => (lang === 'en' ? path : `/${lang}${path === '/' ? '' : path}`);

export const fill = (text: string, values: Record<string, string | number>) =>
  text.replace(/\{(\w+)\}/g, (_, k) => String(values[k] ?? `{${k}}`));

type Section = { h: string; p: string[] };

const en = {
  meta: {
    title: 'OurNotch: send love, notch to notch',
    description: 'OurNotch puts your person in your MacBook notch: their face, their mood, their whispers, kisses and photos. One license works for you both.',
    ogDescription: 'Whispers, kisses and photos that appear in your person’s MacBook notch. One license works for you both.',
  },
  nav: { features: 'Features', pricing: 'Pricing', faq: 'FAQ', get: 'Get OurNotch' },
  hero: {
    h1a: 'Send love,', h1b: 'notch to notch.',
    sub: 'OurNotch keeps your person at the top of your MacBook screen. Send them a whisper, a kiss or a photo, and it appears in their notch.',
    cta: 'Get it for {price}', how: 'See how it works',
    underB: 'One-time purchase.', under: 'Works on both your Macs.',
  },
  fits: {
    kicker: 'What fits in a notch', h2: 'Tiny things. Big feelings.',
    p: "It's closed most of the day, and still shows you a little bit of them. Hover over it to send something back.",
  },
  bento: {
    noteTitle: 'Whispers, just between you.', noteBody: 'Say something sweet. It scrolls across their notch, and your last few stay as a tiny conversation.',
    ticker: "lunch at 1? i'll bring dumplings 🥟",
    heartTitle: 'One tap, many hearts.', heartBody: 'Tap a heart or a kiss, and it pours out of their notch, or floats up across their whole screen.',
    moodTitle: 'How you are, at a glance.', moodBody: 'Pick one of twelve moods. It shows in their notch all day, right beside your face.', moodsLabel: 'Moods',
    moods: ['In love', 'Happy', 'Missing you', 'Excited', 'On a break', 'Hungry', 'Busy', 'Focused', 'Out', 'Sleepy', 'Low', 'Unwell'],
    photoTitle: 'A photo for their Home.', photoBody: 'Send a favorite photo. It stays on their Home until you send the next one.',
    us: 'us ♡', sunday: 'sunday ♡',
    countTitle: 'Every second, counted.', countBody: 'Your days, weekends and seconds together, ticking up in their notch, and the countdown to your anniversary.',
    secondsTogether: 'Seconds of us', days: 'days', hours: 'hours', weekends: 'weekends', toAnniversary: 'to your anniversary',
  },
  two: {
    kicker: 'Made for two', h2: 'Built for exactly two Macs.',
    p: 'You pair once with a six-letter code. After that, whatever you send lands in their notch within seconds, and theirs lands in yours.',
    hint: 'Tap either side to send a heart.', you: 'you', person: 'your person',
    aria: 'Pip, labelled you, taps their notch and a heart flies over to Bun, labelled your person, whose notch pours out hearts.',
  },
  details: {
    kicker: 'The details', h2: 'Quiet, private, and always there.',
    items: [
      ['🔐', 'Private', 'Everything is end-to-end encrypted. Only your two Macs can read it.'],
      ['🗓️', 'Your anniversary, remembered', 'It counts down the days to your anniversary, so it never sneaks up on you.'],
      ['🔑', 'No account', 'No sign-up and no password. Just a six-letter pairing code.'],
      ['👀', 'On every screen', 'It stays in the notch in every app and desktop, even full-screen ones.'],
      ['🫧', 'No inbox', 'No unread badges and no endless chat. Just your last few whispers to each other.'],
      ['💻', 'No notch needed', 'On Macs without one, it lives in a small black pill at the top of the screen.'],
    ] as [string, string, string][],
  },
  buy: {
    tag: '1 license · 2 Macs', kicker: 'Pricing', h2: 'One license for both of you.',
    p: "Buy it once and install it on your Mac and your person's. No subscription.", once: 'one time',
    points: ["Your Mac and your person's", 'Whispers, kisses, moods and photos', 'Your time together, counted live'],
    cta: 'Get OurNotch',
    fine: 'Needs macOS 14 Sonoma or later on both Macs. Your love can {download} and join with your invite.',
    downloadFree: 'download it free',
  },
  faq: {
    kicker: 'FAQ', h2: 'Good questions.',
    items: [
      ['Do we both need to buy it?', "No. One license covers your Mac and your person's."],
      ['What do we need?', 'Two Macs with macOS 14 Sonoma or later, each signed in with an Apple Account.'],
      ['Can anyone else see what we send?', "No. It's end-to-end encrypted, so only your two Macs can read it."],
      ['Do we keep our whispers?', "Your last few stay as a tiny conversation in the notch. There's no endless history to scroll."],
      ['What if my Mac has no notch?', 'OurNotch shows a small black pill at the top of the screen instead, and works the same way.'],
      ['Is there an iPhone app?', 'Not yet. OurNotch is Mac-only for now.'],
    ] as [string, string][],
  },
  end: { h2: 'Give your notch someone to love.', cta: 'Get it for {price}' },
  footer: { made: 'OurNotch · made for two', apple: 'Not affiliated with Apple.', licence: 'My licence', privacy: 'Privacy', terms: 'Terms', refunds: 'Refunds', contact: 'Contact' },
  demo: {
    aria: 'Demo: Bun sends Pip a note, hearts and a photo through the MacBook notch, and Pip writes back',
    menus: ['File', 'Edit', 'View', 'Window'], event: 'Date night', eventWhen: '8:00 PM · our spot',
    tabs: ['Home', 'Together', 'Whispers', 'Emoji', 'Mood', 'Photo'],
    moodWords: { '🥰': 'in love', '☕️': 'on a break' } as Record<string, string>,
    secondsOfUs: 'seconds of us, and counting', theirMood: 'Their mood', daysTogether: 'Days together',
    emojisBetween: 'Emojis between you', toAnniversary: 'Days to your anniversary',
    justBetween: 'just between us ❤️', missYou: 'miss you already 🥺', scrollsLine: "Scrolls 3 times on bun's notch",
    you: 'you', hours: 'Hours', weekends: 'Weekends', seconds: 'Seconds',
    fromBun1h: 'from bun · 1h', bun2m: 'bun · 2m ago', favorite: "you're my favorite notification",
    from2m: 'From bun · 2m ago', placeholder: 'Say something sweet…', scroll: 'Scroll', three: '3 times', untilOpened: 'Until opened',
    upTo: 'Up to 10 words', sendEmoji: 'Send an emoji', popsUp: "Tap one, and it pops up on bun's screen ♡", tapToSend: 'Tap to send',
    appears: 'Appears', outOfNotch: 'Out of the notch', fullScreen: 'Full screen',
    us: 'us ♡', sunday: 'sunday ♡', ticker: "lunch at 1? i'll bring dumplings 🥟",
    photo: 'Photo', sendPhoto: 'Send bun a photo', showsUp: 'It shows up on their Home the next time they open their notch ♡', choose: 'Choose Photo…',
  },
  tour: {
    locale: 'en-US',
    ofWords: '{n} of 10 words', sending: 'Sending…', delivered: 'Delivered ♡', sent: 'Sent {e}', deliveredE: 'Delivered {e}',
    lastSent: 'Last sent to bun', staysHome: 'Shows on their Home until you send a new one ♡', sendNew: 'Send New Photo…',
    justSending: 'Just now · Sending…', justDelivered: 'Just now · Delivered ♡',
    fromBunNow: 'from bun · just now', bunNow: 'bun · just now',
    lines: [
      'meet bun, who lives in my notch ♡', 'brb, coffee ☕️', 'psst… read your notch 👀', 'dumplings?! marry me 🥟',
      'here, have a heart ♥', 'actually, have a hundred 🥰', 'wait, what else did you send? 👀', 'our sunday pic 📸',
      'aww, it counts our weekends too 🥹', 'my turn ✍️', 'see you at 1 ♡', '+ a kiss 😘', 'and one for your home 📸',
      'on my home now 😭',
    ],
  },
  thanks: {
    title: 'Thank you ♡ OurNotch', kicker: 'Thank you', h1: 'Your gift is ready.', p: 'Three little steps and the first heart is on its way.',
    s1: 'Download OurNotch', s1p: 'Open the download and drag OurNotch into Applications.', s1b: 'Download',
    s2: 'Open OurNotch', s2p: 'It switches itself on with your licence. Nothing to type.', s2b: 'Open OurNotch',
    s2note: 'Your licence key is in your receipt email. Paste it in OurNotch under {b}.', s2noteB: 'I Have a Licence Key',
    s3: 'Invite your love',
    s3p: "OurNotch writes a little surprise email with a six-letter code. They download it free, type the code, and you're together. The code lasts 24 hours.",
    keyKicker: 'Your licence key', copy: 'Copy', copied: 'Copied ♡', keyNote: 'Also in your receipt email. Keep it for a new Mac.',
    help: 'Something not working? Your key works on one Mac at a time: yours. {more} or write to us at {email}.', helpLink: 'Help with your licence',
  },
  licence: {
    title: 'My licence · OurNotch', kicker: 'Help', h1: 'Your licence',
    sections: [
      { h: 'Where is my key?', p: ['Your licence key is in the receipt email from Dodo Payments, sent right after you paid. It was also shown on the thank-you page.', "Can't find it? Use **Find my licence** below: enter the email you paid with, and Dodo sends you a sign-in link to see your key."] },
      { h: 'Who needs a key?', p: ['Only the person who bought OurNotch. Your love downloads OurNotch for free, chooses **I Have an Invite Code**, and types the six-letter code from your invite. Their Mac is covered by your licence while you are paired.'] },
      { h: 'Moving to a new Mac', p: ['Your key works on one Mac at a time: yours. On the old Mac, open the notch, tap the gear, and choose **Remove from This Mac**. Then install OurNotch on the new Mac and paste your key under **I Have a Licence Key**.', 'Lost or sold the old Mac? Write to us and we free it for you.'] },
      { h: 'Something went wrong', p: ['**"That key doesn\'t look right"**: check for missing characters; copying it from the email works best.', '**"Already in use on another Mac"**: remove it from your old Mac first, or write to us.', "**\"Can't reach the shop\"**: check your internet and try again. Once OurNotch is switched on, it keeps working offline."] },
    ] as Section[],
    find: 'Find my licence', write: 'Write to us',
  },
  refunds: {
    title: 'Refunds · OurNotch', kicker: 'Refund policy', h1: 'Refunds and cancellations.', updated: 'Last updated: October 2026',
    sections: [
      { h: 'Nothing to cancel', p: ['OurNotch is a one-time purchase, not a subscription. There is nothing to cancel, and you are never charged again.'] },
      { h: 'Refunds', p: ['Because OurNotch is a digital product you can use right away, sales are final and we don\'t offer refunds, except where the law where you live gives you a right to one (for example consumer rules in the EU or the UK).'] },
      { h: 'Something not working?', p: ['Write to us first. Most problems (activating, moving to a new Mac, pairing with your love) are quick to fix, and **My licence** covers the common ones.'] },
      { h: 'Asking for a refund', p: ['If the law gives you a right to a refund, write to us from the email you paid with and include your receipt. Refunds are made by Dodo Payments, our seller of record, to the payment method you used. A refunded licence stops working on both Macs of the pair.'] },
    ] as Section[],
    contact: 'Questions? Write to us at {email}.',
  },
  launching: {
    title: 'Almost ready · OurNotch', kicker: 'Download', h1: 'Launching this week.',
    sections: [
      { h: 'Almost there', p: ['OurNotch is in beta with its first couples and opens to everyone this week, as soon as the signed Mac app is ready.'] },
      { h: 'Bought it already?', p: ['Your licence key is safe in your receipt email. We email you the download link the moment it is live, and your love can download it free then too.'] },
    ] as Section[],
    contact: 'Questions? Write to us at {email}.', back: 'Back to OurNotch',
  },
  privacy: {
    title: 'Privacy · OurNotch', kicker: 'Privacy policy', h1: 'Your notes are yours.', updated: 'Last updated: October 2026',
    sections: [
      { h: 'What we can read', p: ['Nothing you send. Notes, emoji, moods and photos are end-to-end encrypted on your Mac with a key only your two Macs share. They travel through Apple\'s iCloud (CloudKit), where they are stored as unreadable bytes. We have no copy of the key.'] },
      { h: 'What is stored, and where', p: ['**In iCloud (Apple\'s CloudKit public database):** your encrypted outbox (your latest note, emoji count, mood, photo), the pairing records with the names you chose and your public keys, and short-lived invite codes.', '**On your Mac:** your private key and your licence key (in the Keychain), your settings, and a local log of app events, without any message content.', '**With Dodo Payments:** your purchase: name, email, country, payment details, receipt and licence key. Dodo is the seller of record and handles payment and tax. See Dodo Payments\' privacy policy.'] },
      { h: 'Licence checks', p: ['About once a day, OurNotch asks Dodo whether your licence key is still valid. The request carries the key and, for the buyer\'s Mac, the Mac\'s name. Nothing else.'] },
      { h: 'Diagnostics', p: ['Test builds given to beta testers upload an event log and performance measurements (no message content) so we can find bugs. The OurNotch you buy uploads nothing: its log stays on your Mac.'] },
      { h: 'This website', p: ['ournotch.app is hosted by Cloudflare, which sees your IP address and country to serve the page and show your local price. We use no analytics, ads or tracking cookies.'] },
      { h: 'Revoking a licence', p: ['If we notice a licence being abused (for example shared publicly or used with a cracked copy), we may revoke it. OurNotch then stops on both Macs of the pair.'] },
      { h: 'Your choices', p: ['Remove OurNotch from both Macs to stop syncing; your encrypted records stay unreadable. To have your purchase record or anything else deleted, write to us.'] },
    ] as Section[],
    contact: 'Questions? Write to us at {email}.',
  },
  terms: {
    title: 'Terms · OurNotch', kicker: 'Terms', h1: 'The short, fair version.', updated: 'Last updated: October 2026',
    sections: [
      { h: 'One licence per couple', p: ['One purchase covers two Macs: the buyer\'s, which holds the licence, and their partner\'s while the two are paired. The licence belongs to the buyer and can move to a new Mac (one Mac at a time).'] },
      { h: 'Paying', p: ['OurNotch is a one-time purchase, not a subscription. Dodo Payments is the seller of record: it takes the payment, charges any tax and sends your receipt.'] },
      { h: 'Refunds', p: ['Because OurNotch is a digital product you can use right away, sales are final and we don\'t offer refunds, except where the law where you live gives you a right to one (for example consumer rules in the EU). A refunded licence stops working.'] },
      { h: 'Fair use and revocation', p: ['Please don\'t share your key publicly, resell it, or use OurNotch with a modified copy. If we notice abuse, we may revoke the licence, which stops OurNotch on both Macs of the pair.'] },
      { h: 'What OurNotch needs', p: ['macOS 14 Sonoma or later and iCloud on both Macs. OurNotch relies on Apple\'s iCloud; we can\'t control outages there.'] },
      { h: 'No warranty', p: ['OurNotch is provided as is. We work hard to make it reliable, but we can\'t promise it will always be error-free, and to the extent the law allows we aren\'t liable for indirect losses.'] },
      { h: 'Changes', p: ['We may update these terms; the date above shows the latest version.'] },
    ] as Section[],
    contact: 'Questions? Write to us at {email}.',
  },
};

export type Copy = typeof en;

const fr: Copy = {
  meta: {
    title: 'OurNotch : de l’amour, d’encoche à encoche',
    description: 'OurNotch met ta personne dans l’encoche de ton MacBook : son visage, son humeur, ses murmures, bisous et photos. Une seule licence pour vous deux.',
    ogDescription: 'Des murmures, bisous et photos qui apparaissent dans l’encoche du MacBook de ta personne. Une seule licence pour vous deux.',
  },
  nav: { features: 'Fonctions', pricing: 'Prix', faq: 'FAQ', get: 'Obtenir OurNotch' },
  hero: {
    h1a: 'De l’amour,', h1b: 'd’encoche à encoche.',
    sub: 'OurNotch garde ta personne tout en haut de l’écran de ton MacBook. Envoie-lui un murmure, un bisou ou une photo, et ça apparaît dans son encoche.',
    cta: 'Obtenir pour {price}', how: 'Voir comment ça marche',
    underB: 'Achat unique.', under: 'Fonctionne sur vos deux Mac.',
  },
  fits: {
    kicker: 'Ce qui tient dans une encoche', h2: 'Petites choses. Grands sentiments.',
    p: 'Elle reste fermée presque toute la journée, et te montre quand même un peu de ta personne. Survole-la pour répondre.',
  },
  bento: {
    noteTitle: 'Des murmures, rien qu’entre vous.', noteBody: 'Dis-lui un mot doux. Il défile dans son encoche, et vos derniers restent comme une mini conversation.',
    ticker: 'déj à 13 h ? j’apporte des raviolis 🥟',
    heartTitle: 'Un clic, plein de cœurs.', heartBody: 'Touche un cœur ou un bisou : il coule de son encoche, ou s’envole sur tout son écran.',
    moodTitle: 'Comment tu vas, en un coup d’œil.', moodBody: 'Choisis une humeur parmi douze. Elle s’affiche toute la journée dans son encoche, à côté de ton visage.', moodsLabel: 'Humeurs',
    moods: ['Amour', 'Joie', 'Tu me manques', 'Hâte', 'En pause', 'Faim', 'Pas dispo', 'Concentration', 'Dehors', 'Sommeil', 'Bof', 'Malade'],
    photoTitle: 'Une photo pour son Accueil.', photoBody: 'Envoie une photo préférée. Elle reste dans son Accueil jusqu’à la suivante.',
    us: 'nous ♡', sunday: 'dimanche ♡',
    countTitle: 'Chaque seconde compte.', countBody: 'Vos jours, week-ends et secondes à deux, qui défilent dans son encoche, et le compte à rebours jusqu’à votre anniversaire.',
    secondsTogether: 'Secondes à nous deux', days: 'jours', hours: 'heures', weekends: 'week-ends', toAnniversary: 'avant l’anniversaire',
  },
  two: {
    kicker: 'Fait pour deux', h2: 'Conçu pour deux Mac, pas un de plus.',
    p: 'Vous vous associez une fois avec un code de six caractères. Ensuite, ce que tu envoies arrive dans son encoche en quelques secondes, et inversement.',
    hint: 'Clique d’un côté pour envoyer un cœur.', you: 'toi', person: 'ta personne',
    aria: 'Pip, toi, touche son encoche et un cœur s’envole vers Bun, ta personne, dont l’encoche déborde de cœurs.',
  },
  details: {
    kicker: 'Les détails', h2: 'Discret, privé, et toujours là.',
    items: [
      ['🔐', 'Privé', 'Tout est chiffré de bout en bout. Seuls vos deux Mac peuvent le lire.'],
      ['🗓️', 'Votre anniversaire, pas oublié', 'Il compte les jours jusqu’à votre anniversaire, pour qu’il ne vous prenne jamais par surprise.'],
      ['🔑', 'Pas de compte', 'Pas d’inscription, pas de mot de passe. Juste un code de six caractères.'],
      ['👀', 'Sur chaque écran', 'Elle reste dans l’encoche dans chaque app et bureau, même en plein écran.'],
      ['🫧', 'Pas de boîte de réception', 'Pas de pastilles non lues, pas de fil sans fin. Juste vos derniers murmures.'],
      ['💻', 'Pas besoin d’encoche', 'Sur les Mac sans encoche, elle vit dans une petite pilule noire en haut de l’écran.'],
    ],
  },
  buy: {
    tag: '1 licence · 2 Mac', kicker: 'Prix', h2: 'Une licence pour vous deux.',
    p: 'Achète-le une fois et installe-le sur ton Mac et celui de ta personne. Pas d’abonnement.', once: 'une fois',
    points: ['Ton Mac et celui de ta personne', 'Murmures, bisous, humeurs et photos', 'Votre temps ensemble, compté en direct'],
    cta: 'Obtenir OurNotch',
    fine: 'Nécessite macOS 14 Sonoma ou plus récent sur les deux Mac. Ton amour peut {download} et te rejoindre avec ton invitation.',
    downloadFree: 'le télécharger gratuitement',
  },
  faq: {
    kicker: 'FAQ', h2: 'Bonnes questions.',
    items: [
      ['Faut-il l’acheter tous les deux ?', 'Non. Une licence couvre ton Mac et celui de ta personne.'],
      ['De quoi avons-nous besoin ?', 'Deux Mac avec macOS 14 Sonoma ou plus récent, chacun connecté avec un compte Apple.'],
      ['Quelqu’un d’autre peut-il voir ce que nous envoyons ?', 'Non. C’est chiffré de bout en bout : seuls vos deux Mac peuvent le lire.'],
      ['Gardons-nous nos murmures ?', 'Vos derniers restent comme une mini conversation dans l’encoche. Pas d’historique sans fin à faire défiler.'],
      ['Et si mon Mac n’a pas d’encoche ?', 'OurNotch affiche une petite pilule noire en haut de l’écran, et fonctionne de la même façon.'],
      ['Y a-t-il une app iPhone ?', 'Pas encore. OurNotch est pour Mac uniquement pour l’instant.'],
    ],
  },
  end: { h2: 'Donne à ton encoche quelqu’un à aimer.', cta: 'Obtenir pour {price}' },
  footer: { made: 'OurNotch · fait pour deux', apple: 'Non affilié à Apple.', licence: 'Ma licence', privacy: 'Confidentialité', terms: 'Conditions', refunds: 'Remboursements', contact: 'Contact' },
  demo: {
    aria: 'Démo : Bun envoie à Pip un mot, des cœurs et une photo via l’encoche du MacBook, et Pip répond',
    menus: ['Fichier', 'Édition', 'Présentation', 'Fenêtre'], event: 'Soirée en amoureux', eventWhen: '20 h · notre resto',
    tabs: ['Accueil', 'Ensemble', 'Murmures', 'Emoji', 'Humeur', 'Photo'],
    moodWords: { '🥰': 'amour', '☕️': 'en pause' } as Record<string, string>,
    secondsOfUs: 'secondes à nous deux, et ça continue', theirMood: 'Son humeur', daysTogether: 'Jours ensemble',
    emojisBetween: 'Emojis entre vous', toAnniversary: 'Jours avant votre anniversaire',
    justBetween: 'rien qu’entre nous ❤️', missYou: 'tu me manques déjà 🥺', scrollsLine: 'Défile 3 fois dans l’encoche de bun',
    you: 'toi', hours: 'Heures', weekends: 'Week-ends', seconds: 'Secondes',
    fromBun1h: 'de bun · 1 h', bun2m: 'bun · il y a 2 min', favorite: 'tu es ma notification préférée',
    from2m: 'De bun · il y a 2 min', placeholder: 'Dis quelque chose de doux…', scroll: 'Défilement', three: '3 fois', untilOpened: 'Jusqu’à ouverture',
    upTo: 'Jusqu’à 10 mots', sendEmoji: 'Envoie un emoji', popsUp: 'Choisis-en un : il apparaît sur l’écran de bun ♡', tapToSend: 'Clique pour envoyer',
    appears: 'Apparaît', outOfNotch: 'Hors de l’encoche', fullScreen: 'Plein écran',
    us: 'nous ♡', sunday: 'dimanche ♡', ticker: 'déj à 13 h ? j’apporte des raviolis 🥟',
    photo: 'Photo', sendPhoto: 'Envoie une photo à bun', showsUp: 'Elle apparaîtra dans son Accueil à sa prochaine ouverture de l’encoche ♡', choose: 'Choisir une photo…',
  },
  tour: {
    locale: 'fr-FR',
    ofWords: '{n} mots sur 10', sending: 'Envoi…', delivered: 'Reçu ♡', sent: 'Envoyé {e}', deliveredE: 'Reçu {e}',
    lastSent: 'Dernière envoyée à bun', staysHome: 'Reste dans son Accueil jusqu’à ta prochaine photo ♡', sendNew: 'Envoyer une nouvelle photo…',
    justSending: 'À l’instant · Envoi…', justDelivered: 'À l’instant · Reçu ♡',
    fromBunNow: 'de bun · à l’instant', bunNow: 'bun · à l’instant',
    lines: [
      'voici bun, qui vit dans mon encoche ♡', 'je reviens, café ☕️', 'psst… lis ton encoche 👀', 'des raviolis ?! épouse-moi 🥟',
      'tiens, un cœur ♥', 'non, en fait, cent 🥰', 'attends, tu m’as envoyé quoi d’autre ? 👀', 'notre photo de dimanche 📸',
      'oh, ça compte même nos week-ends 🥹', 'à moi ✍️', 'à 13 h ♡', '+ un bisou 😘', 'et une pour ton accueil 📸',
      'sur mon accueil maintenant 😭',
    ],
  },
  thanks: {
    title: 'Merci ♡ OurNotch', kicker: 'Merci', h1: 'Ton cadeau est prêt.', p: 'Trois petites étapes, et le premier cœur est en route.',
    s1: 'Télécharge OurNotch', s1p: 'Ouvre le téléchargement et glisse OurNotch dans Applications.', s1b: 'Télécharger',
    s2: 'Ouvre OurNotch', s2p: 'Il s’active tout seul avec ta licence. Rien à taper.', s2b: 'Ouvrir OurNotch',
    s2note: 'Ta clé de licence est dans ton reçu par e-mail. Colle-la dans OurNotch sous {b}.', s2noteB: 'J’ai une clé de licence',
    s3: 'Invite ton amour',
    s3p: 'OurNotch écrit un petit e-mail surprise avec un code de six caractères. Ton amour le télécharge gratuitement, tape le code, et vous êtes réunis. Le code est valable 24 heures.',
    keyKicker: 'Ta clé de licence', copy: 'Copier', copied: 'Copiée ♡', keyNote: 'Aussi dans ton reçu par e-mail. Garde-la pour un nouveau Mac.',
    help: 'Un souci ? Ta clé fonctionne sur un Mac à la fois : le tien. {more} ou écris-nous à {email}.', helpLink: 'Aide pour ta licence',
  },
  licence: {
    title: 'Ma licence · OurNotch', kicker: 'Aide', h1: 'Ta licence',
    sections: [
      { h: 'Où est ma clé ?', p: ['Ta clé de licence est dans le reçu envoyé par Dodo Payments juste après le paiement. Elle était aussi affichée sur la page de remerciement.', 'Introuvable ? Utilise **Retrouver ma licence** ci-dessous : saisis l’e-mail utilisé pour payer, et Dodo t’envoie un lien de connexion pour voir ta clé.'] },
      { h: 'Qui a besoin d’une clé ?', p: ['Seulement la personne qui a acheté OurNotch. Ton amour télécharge OurNotch gratuitement, choisit **J’ai un code d’invitation** et tape le code de six caractères de ton invitation. Son Mac est couvert par ta licence tant que vous êtes associés.'] },
      { h: 'Passer à un nouveau Mac', p: ['Ta clé fonctionne sur un Mac à la fois : le tien. Sur l’ancien Mac, ouvre l’encoche, touche la roue dentée et choisis **Retirer de ce Mac**. Installe ensuite OurNotch sur le nouveau Mac et colle ta clé sous **J’ai une clé de licence**.', 'Ancien Mac perdu ou vendu ? Écris-nous et nous le libérons pour toi.'] },
      { h: 'Un problème ?', p: ['**« Cette clé ne semble pas correcte »** : vérifie qu’il ne manque rien ; le plus simple est de la copier depuis l’e-mail.', '**« Déjà utilisée sur un autre Mac »** : retire-la d’abord de ton ancien Mac, ou écris-nous.', '**« Impossible de joindre la boutique »** : vérifie ta connexion et réessaie. Une fois activé, OurNotch fonctionne aussi hors ligne.'] },
    ],
    find: 'Retrouver ma licence', write: 'Nous écrire',
  },
  refunds: {
    title: 'Remboursements · OurNotch', kicker: 'Politique de remboursement', h1: 'Remboursements et annulations.', updated: 'Dernière mise à jour : octobre 2026',
    sections: [
      { h: 'Rien à annuler', p: ['OurNotch est un achat unique, pas un abonnement. Il n’y a rien à annuler, et tu n’es jamais débité à nouveau.'] },
      { h: 'Remboursements', p: ['OurNotch étant un produit numérique utilisable immédiatement, les ventes sont définitives et nous ne remboursons pas, sauf lorsque la loi de ton pays te donne droit à un remboursement (par exemple les règles de consommation de l’UE ou du Royaume-Uni).'] },
      { h: 'Un problème ?', p: ['Écris-nous d’abord. La plupart des soucis (activation, passage à un nouveau Mac, association avec ton amour) se règlent vite, et **Ma licence** explique les plus courants.'] },
      { h: 'Demander un remboursement', p: ['Si la loi te donne droit à un remboursement, écris-nous depuis l’e-mail utilisé pour payer, avec ton reçu. Les remboursements sont effectués par Dodo Payments, notre vendeur officiel, sur le moyen de paiement utilisé. Une licence remboursée cesse de fonctionner sur les deux Mac du couple.'] },
    ],
    contact: 'Des questions ? Écris-nous à {email}.',
  },
  launching: {
    title: 'Presque prêt · OurNotch', kicker: 'Téléchargement', h1: 'Lancement cette semaine.',
    sections: [
      { h: 'Presque prêt', p: ['OurNotch est en bêta avec ses premiers couples et ouvre à tout le monde cette semaine, dès que l’app Mac signée est prête.'] },
      { h: 'Tu l’as déjà acheté ?', p: ['Ta clé de licence est bien au chaud dans ton reçu par e-mail. Nous t’envoyons le lien de téléchargement dès qu’il est en ligne, et ton amour pourra alors le télécharger gratuitement.'] },
    ],
    contact: 'Des questions ? Écris-nous à {email}.', back: 'Retour à OurNotch',
  },
  privacy: {
    title: 'Confidentialité · OurNotch', kicker: 'Politique de confidentialité', h1: 'Tes mots t’appartiennent.', updated: 'Dernière mise à jour : octobre 2026',
    sections: [
      { h: 'Ce que nous pouvons lire', p: ['Rien de ce que tu envoies. Mots, emojis, humeurs et photos sont chiffrés de bout en bout sur ton Mac avec une clé que seuls vos deux Mac partagent. Ils passent par iCloud d’Apple (CloudKit), où ils sont stockés sous forme d’octets illisibles. Nous n’avons aucune copie de la clé.'] },
      { h: 'Ce qui est stocké, et où', p: ['**Dans iCloud (base de données publique CloudKit d’Apple) :** ta boîte d’envoi chiffrée (ton dernier mot, le nombre d’emojis, ton humeur, ta photo), les enregistrements d’association avec les prénoms choisis et vos clés publiques, et des codes d’invitation de courte durée.', '**Sur ton Mac :** ta clé privée et ta clé de licence (dans le Trousseau), tes réglages et un journal local des événements de l’app, sans aucun contenu de message.', '**Chez Dodo Payments :** ton achat : nom, e-mail, pays, données de paiement, reçu et clé de licence. Dodo est le vendeur officiel et gère le paiement et les taxes. Voir la politique de confidentialité de Dodo Payments.'] },
      { h: 'Vérifications de licence', p: ['Environ une fois par jour, OurNotch demande à Dodo si ta clé de licence est toujours valide. La requête contient la clé et, pour le Mac de l’acheteur, le nom du Mac. Rien d’autre.'] },
      { h: 'Diagnostics', p: ['Les versions de test données aux bêta-testeurs envoient un journal d’événements et des mesures de performance (sans contenu de message) pour nous aider à trouver les bugs. L’OurNotch que tu achètes n’envoie rien : son journal reste sur ton Mac.'] },
      { h: 'Ce site', p: ['ournotch.app est hébergé par Cloudflare, qui voit ton adresse IP et ton pays pour servir la page et afficher ton prix local. Nous n’utilisons ni outil d’analyse, ni publicité, ni cookies de suivi.'] },
      { h: 'Révocation d’une licence', p: ['Si nous constatons un abus de licence (par exemple partagée publiquement ou utilisée avec une copie piratée), nous pouvons la révoquer. OurNotch s’arrête alors sur les deux Mac du couple.'] },
      { h: 'Tes choix', p: ['Supprime OurNotch des deux Mac pour arrêter la synchronisation ; tes enregistrements chiffrés restent illisibles. Pour faire supprimer ton achat ou toute autre donnée, écris-nous.'] },
    ],
    contact: 'Des questions ? Écris-nous à {email}.',
  },
  terms: {
    title: 'Conditions · OurNotch', kicker: 'Conditions', h1: 'La version courte et honnête.', updated: 'Dernière mise à jour : octobre 2026',
    sections: [
      { h: 'Une licence par couple', p: ['Un achat couvre deux Mac : celui de l’acheteur, qui détient la licence, et celui de son partenaire tant qu’ils sont associés. La licence appartient à l’acheteur et peut passer à un nouveau Mac (un Mac à la fois).'] },
      { h: 'Paiement', p: ['OurNotch est un achat unique, pas un abonnement. Dodo Payments est le vendeur officiel : il encaisse le paiement, applique les taxes et envoie ton reçu.'] },
      { h: 'Remboursements', p: ['OurNotch étant un produit numérique utilisable immédiatement, les ventes sont définitives et nous ne remboursons pas, sauf lorsque la loi de ton pays te donne droit à un remboursement (par exemple les règles de consommation de l’UE). Une licence remboursée cesse de fonctionner.'] },
      { h: 'Usage loyal et révocation', p: ['Merci de ne pas partager ta clé publiquement, de ne pas la revendre et de ne pas utiliser OurNotch avec une copie modifiée. En cas d’abus, nous pouvons révoquer la licence, ce qui arrête OurNotch sur les deux Mac du couple.'] },
      { h: 'Ce dont OurNotch a besoin', p: ['macOS 14 Sonoma ou plus récent et iCloud sur les deux Mac. OurNotch s’appuie sur iCloud d’Apple ; nous ne maîtrisons pas ses pannes.'] },
      { h: 'Aucune garantie', p: ['OurNotch est fourni tel quel. Nous travaillons dur pour le rendre fiable, mais ne pouvons promettre qu’il sera toujours sans erreur et, dans la mesure permise par la loi, nous ne sommes pas responsables des pertes indirectes.'] },
      { h: 'Modifications', p: ['Nous pouvons mettre à jour ces conditions ; la date ci-dessus indique la dernière version.'] },
    ],
    contact: 'Des questions ? Écris-nous à {email}.',
  },
};

const de: Copy = {
  meta: {
    title: 'OurNotch: Liebe, von Notch zu Notch',
    description: 'OurNotch holt deinen Menschen in die Notch deines MacBooks: Gesicht, Stimmung, Flüstern, Küsse und Fotos. Eine Lizenz für euch beide.',
    ogDescription: 'Flüstern, Küsse und Fotos, die in der MacBook-Notch deines Menschen erscheinen. Eine Lizenz für euch beide.',
  },
  nav: { features: 'Funktionen', pricing: 'Preis', faq: 'FAQ', get: 'OurNotch holen' },
  hero: {
    h1a: 'Liebe senden,', h1b: 'von Notch zu Notch.',
    sub: 'OurNotch hält deinen Menschen ganz oben auf deinem MacBook-Bildschirm. Schick ein Flüstern, einen Kuss oder ein Foto – und es erscheint in der Notch.',
    cta: 'Für {price} holen', how: 'So funktioniert’s',
    underB: 'Einmaliger Kauf.', under: 'Läuft auf euren beiden Macs.',
  },
  fits: {
    kicker: 'Was in eine Notch passt', h2: 'Kleine Dinge. Große Gefühle.',
    p: 'Die meiste Zeit ist sie zu und zeigt dir trotzdem ein bisschen von deinem Menschen. Fahr darüber, um etwas zurückzuschicken.',
  },
  bento: {
    noteTitle: 'Flüstern, nur zwischen euch.', noteBody: 'Schreib etwas Süßes. Es läuft durch die Notch, und eure letzten bleiben als kleine Unterhaltung.',
    ticker: 'mittag um 1? ich bring dumplings mit 🥟',
    heartTitle: 'Ein Klick, viele Herzen.', heartBody: 'Tipp ein Herz oder einen Kuss an: Es fließt aus der Notch oder schwebt über den ganzen Bildschirm.',
    moodTitle: 'Wie’s dir geht, auf einen Blick.', moodBody: 'Wähl eine von zwölf Launen. Sie steht den ganzen Tag in der Notch, direkt neben deinem Gesicht.', moodsLabel: 'Launen',
    moods: ['Verliebt', 'Glücklich', 'Vermisse dich', 'Aufgeregt', 'Pause', 'Hungrig', 'Beschäftigt', 'Konzentriert', 'Unterwegs', 'Müde', 'Down', 'Krank'],
    photoTitle: 'Ein Foto für den Start-Tab.', photoBody: 'Schick ein Lieblingsfoto. Es bleibt auf dem Start-Tab, bis du das nächste schickst.',
    us: 'wir ♡', sunday: 'sonntag ♡',
    countTitle: 'Jede Sekunde zählt.', countBody: 'Eure Tage, Wochenenden und Sekunden zu zweit, tickend in der Notch, und der Countdown bis zu eurem Jahrestag.',
    secondsTogether: 'Sekunden zu zweit', days: 'Tage', hours: 'Stunden', weekends: 'Wochenenden', toAnniversary: 'bis zum Jahrestag',
  },
  two: {
    kicker: 'Für zwei gemacht', h2: 'Gebaut für genau zwei Macs.',
    p: 'Ihr verbindet euch einmal mit einem Code aus sechs Zeichen. Danach landet alles, was du schickst, in Sekunden in der anderen Notch – und umgekehrt.',
    hint: 'Klick auf eine Seite, um ein Herz zu schicken.', you: 'du', person: 'dein Mensch',
    aria: 'Pip, das bist du, tippt auf die Notch und ein Herz fliegt zu Bun, deinem Menschen, aus dessen Notch Herzen fließen.',
  },
  details: {
    kicker: 'Die Details', h2: 'Leise, privat und immer da.',
    items: [
      ['🔐', 'Privat', 'Alles ist Ende-zu-Ende-verschlüsselt. Nur eure zwei Macs können es lesen.'],
      ['🗓️', 'Euer Jahrestag, nie vergessen', 'Es zählt die Tage bis zu eurem Jahrestag, damit er euch nie überrascht.'],
      ['🔑', 'Kein Konto', 'Keine Anmeldung, kein Passwort. Nur ein Code aus sechs Zeichen.'],
      ['👀', 'Auf jedem Bildschirm', 'Sie bleibt in der Notch, in jeder App und auf jedem Schreibtisch, auch im Vollbild.'],
      ['🫧', 'Kein Posteingang', 'Keine ungelesenen Badges, kein endloser Chat. Nur euer letztes Flüstern.'],
      ['💻', 'Keine Notch nötig', 'Auf Macs ohne Notch lebt sie in einer kleinen schwarzen Pille oben am Bildschirm.'],
    ],
  },
  buy: {
    tag: '1 Lizenz · 2 Macs', kicker: 'Preis', h2: 'Eine Lizenz für euch beide.',
    p: 'Einmal kaufen und auf deinem Mac und dem deines Menschen installieren. Kein Abo.', once: 'einmalig',
    points: ['Dein Mac und der deines Menschen', 'Flüstern, Küsse, Launen und Fotos', 'Eure gemeinsame Zeit, live gezählt'],
    cta: 'OurNotch holen',
    fine: 'Benötigt macOS 14 Sonoma oder neuer auf beiden Macs. Deine Liebe kann {download} und mit deiner Einladung beitreten.',
    downloadFree: 'es kostenlos laden',
  },
  faq: {
    kicker: 'FAQ', h2: 'Gute Fragen.',
    items: [
      ['Müssen wir es beide kaufen?', 'Nein. Eine Lizenz gilt für deinen Mac und den deines Menschen.'],
      ['Was brauchen wir?', 'Zwei Macs mit macOS 14 Sonoma oder neuer, beide mit einem Apple Account angemeldet.'],
      ['Kann sonst jemand sehen, was wir schicken?', 'Nein. Es ist Ende-zu-Ende-verschlüsselt, nur eure zwei Macs können es lesen.'],
      ['Behalten wir unser Flüstern?', 'Eure letzten bleiben als kleine Unterhaltung in der Notch. Kein endloser Verlauf zum Scrollen.'],
      ['Und wenn mein Mac keine Notch hat?', 'Dann zeigt OurNotch eine kleine schwarze Pille oben am Bildschirm und funktioniert genauso.'],
      ['Gibt es eine iPhone-App?', 'Noch nicht. OurNotch gibt es vorerst nur für den Mac.'],
    ],
  },
  end: { h2: 'Gib deiner Notch jemanden zum Liebhaben.', cta: 'Für {price} holen' },
  footer: { made: 'OurNotch · für zwei gemacht', apple: 'Nicht mit Apple verbunden.', licence: 'Meine Lizenz', privacy: 'Datenschutz', terms: 'AGB', refunds: 'Erstattungen', contact: 'Kontakt' },
  demo: {
    aria: 'Demo: Bun schickt Pip über die MacBook-Notch eine Notiz, Herzen und ein Foto, und Pip schreibt zurück',
    menus: ['Ablage', 'Bearbeiten', 'Darstellung', 'Fenster'], event: 'Date-Abend', eventWhen: '20:00 · unser Platz',
    tabs: ['Start', 'Zusammen', 'Flüstern', 'Emoji', 'Laune', 'Foto'],
    moodWords: { '🥰': 'verliebt', '☕️': 'pause' } as Record<string, string>,
    secondsOfUs: 'Sekunden zu zweit, und es werden mehr', theirMood: 'Ihre Laune', daysTogether: 'Tage zusammen',
    emojisBetween: 'Emojis zwischen euch', toAnniversary: 'Tage bis zum Jahrestag',
    justBetween: 'nur zwischen uns ❤️', missYou: 'vermisse dich schon 🥺', scrollsLine: 'Läuft 3-mal durch buns Notch',
    you: 'du', hours: 'Stunden', weekends: 'Wochenenden', seconds: 'Sekunden',
    fromBun1h: 'von bun · 1 Std.', bun2m: 'bun · vor 2 Min.', favorite: 'du bist meine liebste mitteilung',
    from2m: 'Von bun · vor 2 Min.', placeholder: 'Sag etwas Süßes …', scroll: 'Laufschrift', three: '3-mal', untilOpened: 'Bis geöffnet',
    upTo: 'Bis zu 10 Wörter', sendEmoji: 'Schick ein Emoji', popsUp: 'Wähl eins – es erscheint auf buns Bildschirm ♡', tapToSend: 'Zum Senden klicken',
    appears: 'Erscheint', outOfNotch: 'Aus der Notch', fullScreen: 'Vollbild',
    us: 'wir ♡', sunday: 'sonntag ♡', ticker: 'mittag um 1? ich bring dumplings mit 🥟',
    photo: 'Foto', sendPhoto: 'Schick bun ein Foto', showsUp: 'Es erscheint auf dem Start-Tab, sobald die Notch das nächste Mal geöffnet wird ♡', choose: 'Foto auswählen …',
  },
  tour: {
    locale: 'de-DE',
    ofWords: '{n} von 10 Wörtern', sending: 'Wird gesendet …', delivered: 'Zugestellt ♡', sent: 'Gesendet {e}', deliveredE: 'Zugestellt {e}',
    lastSent: 'Zuletzt an bun gesendet', staysHome: 'Bleibt auf dem Start-Tab, bis du ein neues schickst ♡', sendNew: 'Neues Foto senden …',
    justSending: 'Gerade eben · Wird gesendet …', justDelivered: 'Gerade eben · Zugestellt ♡',
    fromBunNow: 'von bun · gerade eben', bunNow: 'bun · gerade eben',
    lines: [
      'das ist bun, wohnt in meiner notch ♡', 'bin kurz kaffee holen ☕️', 'psst… schau in deine notch 👀', 'dumplings?! heirate mich 🥟',
      'hier, ein herz ♥', 'nee, nimm gleich hundert 🥰', 'warte, was hast du noch geschickt? 👀', 'unser sonntagsfoto 📸',
      'oh, es zählt sogar unsere wochenenden 🥹', 'jetzt ich ✍️', 'bis um 1 ♡', '+ ein kuss 😘', 'und eins für deinen start-tab 📸',
      'jetzt auf meinem start-tab 😭',
    ],
  },
  thanks: {
    title: 'Danke ♡ OurNotch', kicker: 'Danke', h1: 'Dein Geschenk ist bereit.', p: 'Drei kleine Schritte, und das erste Herz ist unterwegs.',
    s1: 'OurNotch laden', s1p: 'Öffne den Download und zieh OurNotch in den Ordner „Programme“.', s1b: 'Laden',
    s2: 'OurNotch öffnen', s2p: 'Es aktiviert sich mit deiner Lizenz von selbst. Nichts zu tippen.', s2b: 'OurNotch öffnen',
    s2note: 'Dein Lizenzschlüssel steht in deiner Beleg-E-Mail. Füg ihn in OurNotch unter {b} ein.', s2noteB: 'Ich habe einen Schlüssel',
    s3: 'Lade deine Liebe ein',
    s3p: 'OurNotch schreibt eine kleine Überraschungs-E-Mail mit einem Code aus sechs Zeichen. Deine Liebe lädt es kostenlos, gibt den Code ein, und ihr seid verbunden. Der Code gilt 24 Stunden.',
    keyKicker: 'Dein Lizenzschlüssel', copy: 'Kopieren', copied: 'Kopiert ♡', keyNote: 'Steht auch in deiner Beleg-E-Mail. Heb ihn für einen neuen Mac auf.',
    help: 'Klappt etwas nicht? Dein Schlüssel funktioniert auf einem Mac gleichzeitig: deinem. {more} oder schreib uns an {email}.', helpLink: 'Hilfe zu deiner Lizenz',
  },
  licence: {
    title: 'Meine Lizenz · OurNotch', kicker: 'Hilfe', h1: 'Deine Lizenz',
    sections: [
      { h: 'Wo ist mein Schlüssel?', p: ['Dein Lizenzschlüssel steht in der Beleg-E-Mail von Dodo Payments, die du direkt nach dem Kauf bekommen hast. Er wurde auch auf der Danke-Seite angezeigt.', 'Nicht gefunden? Nutze unten **Meine Lizenz finden**: Gib die E-Mail-Adresse ein, mit der du bezahlt hast, und Dodo schickt dir einen Anmeldelink, unter dem du deinen Schlüssel siehst.'] },
      { h: 'Wer braucht einen Schlüssel?', p: ['Nur wer OurNotch gekauft hat. Deine Liebe lädt OurNotch kostenlos, wählt **Ich habe einen Einladungscode** und gibt den Code aus sechs Zeichen aus deiner Einladung ein. Solange ihr verbunden seid, deckt deine Lizenz ihren Mac ab.'] },
      { h: 'Umzug auf einen neuen Mac', p: ['Dein Schlüssel funktioniert auf einem Mac gleichzeitig: deinem. Öffne auf dem alten Mac die Notch, tippe auf das Zahnrad und wähle **Von diesem Mac entfernen**. Installiere dann OurNotch auf dem neuen Mac und füge deinen Schlüssel unter **Ich habe einen Schlüssel** ein.', 'Alten Mac verloren oder verkauft? Schreib uns, dann geben wir ihn für dich frei.'] },
      { h: 'Etwas ist schiefgelaufen', p: ['**„Dieser Schlüssel scheint nicht zu stimmen“** – prüf, ob Zeichen fehlen; am besten kopierst du ihn aus der E-Mail.', '**„Schon auf einem anderen Mac genutzt“** – entferne ihn zuerst von deinem alten Mac oder schreib uns.', '**„Der Shop ist gerade nicht erreichbar“** – prüf deine Internetverbindung und versuch es noch mal. Einmal aktiviert, funktioniert OurNotch auch offline.'] },
    ],
    find: 'Meine Lizenz finden', write: 'Schreib uns',
  },
  refunds: {
    title: 'Erstattungen · OurNotch', kicker: 'Erstattungsrichtlinie', h1: 'Erstattungen und Kündigungen.', updated: 'Zuletzt aktualisiert: Oktober 2026',
    sections: [
      { h: 'Nichts zu kündigen', p: ['OurNotch ist ein einmaliger Kauf, kein Abo. Es gibt nichts zu kündigen, und es wird nie wieder etwas abgebucht.'] },
      { h: 'Erstattungen', p: ['Da OurNotch ein digitales Produkt ist, das du sofort nutzen kannst, sind Käufe endgültig und wir erstatten nicht, außer wenn dir das Recht deines Landes einen Anspruch gibt (zum Beispiel Verbraucherregeln in der EU oder im Vereinigten Königreich).'] },
      { h: 'Klappt etwas nicht?', p: ['Schreib uns zuerst. Die meisten Probleme (Aktivieren, Umzug auf einen neuen Mac, Verbinden mit deiner Liebe) sind schnell gelöst, und **Meine Lizenz** erklärt die häufigsten.'] },
      { h: 'Eine Erstattung anfragen', p: ['Wenn dir das Gesetz eine Erstattung zusteht, schreib uns von der E-Mail-Adresse, mit der du bezahlt hast, und schick deinen Beleg mit. Erstattungen macht Dodo Payments, unser Verkäufer (Merchant of Record), auf die Zahlungsart, die du genutzt hast. Eine erstattete Lizenz funktioniert auf beiden Macs des Paares nicht mehr.'] },
    ],
    contact: 'Fragen? Schreib uns an {email}.',
  },
  launching: {
    title: 'Fast fertig · OurNotch', kicker: 'Download', h1: 'Start diese Woche.',
    sections: [
      { h: 'Fast geschafft', p: ['OurNotch ist in der Beta mit den ersten Paaren und öffnet diese Woche für alle, sobald die signierte Mac-App fertig ist.'] },
      { h: 'Schon gekauft?', p: ['Dein Lizenzschlüssel ist sicher in deiner Beleg-E-Mail. Wir schicken dir den Download-Link, sobald er live ist, und deine Liebe kann es dann kostenlos laden.'] },
    ],
    contact: 'Fragen? Schreib uns an {email}.', back: 'Zurück zu OurNotch',
  },
  privacy: {
    title: 'Datenschutz · OurNotch', kicker: 'Datenschutzerklärung', h1: 'Deine Notizen gehören dir.', updated: 'Zuletzt aktualisiert: Oktober 2026',
    sections: [
      { h: 'Was wir lesen können', p: ['Nichts von dem, was du schickst. Notizen, Emojis, Launen und Fotos werden auf deinem Mac Ende-zu-Ende verschlüsselt, mit einem Schlüssel, den nur eure zwei Macs teilen. Sie reisen über Apples iCloud (CloudKit) und liegen dort als unlesbare Bytes. Wir haben keine Kopie des Schlüssels.'] },
      { h: 'Was wo gespeichert wird', p: ['**In iCloud (Apples öffentliche CloudKit-Datenbank):** dein verschlüsselter Postausgang (deine letzte Notiz, die Zahl der Emojis, deine Laune, dein Foto), die Verbindungsdaten mit den gewählten Namen und euren öffentlichen Schlüsseln sowie kurzlebige Einladungscodes.', '**Auf deinem Mac:** dein privater Schlüssel und dein Lizenzschlüssel (im Schlüsselbund), deine Einstellungen und ein lokales Protokoll der App-Ereignisse, ohne Nachrichteninhalte.', '**Bei Dodo Payments:** dein Kauf – Name, E-Mail, Land, Zahlungsdaten, Beleg und Lizenzschlüssel. Dodo ist der Verkäufer (Merchant of Record) und kümmert sich um Zahlung und Steuern. Siehe die Datenschutzerklärung von Dodo Payments.'] },
      { h: 'Lizenzprüfungen', p: ['Etwa einmal am Tag fragt OurNotch bei Dodo nach, ob dein Lizenzschlüssel noch gültig ist. Die Anfrage enthält den Schlüssel und beim Mac des Käufers den Namen des Macs. Sonst nichts.'] },
      { h: 'Diagnose', p: ['Testversionen für Beta-Tester laden ein Ereignisprotokoll und Leistungsmessungen hoch (ohne Nachrichteninhalte), damit wir Fehler finden. Das OurNotch, das du kaufst, lädt nichts hoch: Sein Protokoll bleibt auf deinem Mac.'] },
      { h: 'Diese Website', p: ['ournotch.app wird von Cloudflare gehostet, das deine IP-Adresse und dein Land sieht, um die Seite auszuliefern und deinen lokalen Preis zu zeigen. Wir nutzen keine Analyse-Tools, keine Werbung und keine Tracking-Cookies.'] },
      { h: 'Entzug einer Lizenz', p: ['Wenn wir Missbrauch einer Lizenz bemerken (zum Beispiel öffentlich geteilt oder mit einer gecrackten Kopie genutzt), können wir sie entziehen. OurNotch stoppt dann auf beiden Macs des Paares.'] },
      { h: 'Deine Möglichkeiten', p: ['Entferne OurNotch von beiden Macs, um die Synchronisierung zu beenden; deine verschlüsselten Daten bleiben unlesbar. Wenn wir deinen Kauf oder andere Daten löschen sollen, schreib uns.'] },
    ],
    contact: 'Fragen? Schreib uns an {email}.',
  },
  terms: {
    title: 'AGB · OurNotch', kicker: 'Nutzungsbedingungen', h1: 'Die kurze, faire Fassung.', updated: 'Zuletzt aktualisiert: Oktober 2026',
    sections: [
      { h: 'Eine Lizenz pro Paar', p: ['Ein Kauf gilt für zwei Macs: den des Käufers, der die Lizenz hält, und den seines Partners, solange beide verbunden sind. Die Lizenz gehört dem Käufer und kann auf einen neuen Mac umziehen (ein Mac gleichzeitig).'] },
      { h: 'Bezahlung', p: ['OurNotch ist ein einmaliger Kauf, kein Abo. Dodo Payments ist der Verkäufer (Merchant of Record): Es nimmt die Zahlung entgegen, berechnet Steuern und schickt deinen Beleg.'] },
      { h: 'Erstattungen', p: ['Da OurNotch ein digitales Produkt ist, das du sofort nutzen kannst, sind Käufe endgültig und wir erstatten nicht – außer wenn dir das Recht deines Landes einen Anspruch gibt (zum Beispiel Verbraucherregeln in der EU). Eine erstattete Lizenz funktioniert nicht mehr.'] },
      { h: 'Faire Nutzung und Entzug', p: ['Bitte teile deinen Schlüssel nicht öffentlich, verkaufe ihn nicht weiter und nutze OurNotch nicht mit einer veränderten Kopie. Bei Missbrauch können wir die Lizenz entziehen; dann stoppt OurNotch auf beiden Macs des Paares.'] },
      { h: 'Was OurNotch braucht', p: ['macOS 14 Sonoma oder neuer und iCloud auf beiden Macs. OurNotch baut auf Apples iCloud; Ausfälle dort liegen nicht in unserer Hand.'] },
      { h: 'Keine Gewährleistung', p: ['OurNotch wird so bereitgestellt, wie es ist. Wir arbeiten hart an der Zuverlässigkeit, können aber nicht versprechen, dass es immer fehlerfrei ist, und haften, soweit gesetzlich zulässig, nicht für mittelbare Schäden.'] },
      { h: 'Änderungen', p: ['Wir können diese Bedingungen aktualisieren; das Datum oben zeigt die neueste Fassung.'] },
    ],
    contact: 'Fragen? Schreib uns an {email}.',
  },
};

export const copy: Record<Lang, Copy> = { en, fr, de };
export const isLang = (x: string): x is Lang => (LANGS as string[]).includes(x);
