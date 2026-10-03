# Handoff: OurNotch — notch UI (v3, macOS style)

## Overview
OurNotch is a tiny macOS app for couples that lives in the MacBook camera notch. A pure-black shape grows out of the physical notch. Closed, it shows days together + a heartbeat heart. On hover it opens into a small panel with 4 tabs: **Home** (a bento: latest photo from your partner, their latest note, hours · weekends · seconds together), **Note** (send a short note), **Emoji** (send an emoji, shown out of the notch or full screen), **Photo** (send a photo). Partners also receive hearts (pour / splash animations). A small onboarding window pairs the couple.

Tone: cute, calm, native. It should feel like it shipped with macOS — SF Pro, system pink, standard dark materials, native controls.

## About the Design Files
The files in this bundle are **design references created in HTML** — prototypes showing intended look and behavior, **not production code to copy**. Recreate them in **SwiftUI** (macOS 14+), using AppKit only where SwiftUI can't (borderless notch window, click-through overlay, NSOpenPanel, login item).

Open `OurNotch v3.dc.html` in a browser (needs `support.js` + `NotchMac.dc.html` beside it, and internet for fonts/photos). Hover the live prototype at the top to interact.

## Fidelity
**High-fidelity.** Colors, sizes, type, radii and copy are final. Recreate pixel-accurately in SwiftUI. Mocks are drawn at 2×; all numbers below are **points**.

---

## Window / shape (hard constraints)

- Borderless, non-activating `NSPanel`, level `.statusBar` (or above menu bar), `collectionBehavior: [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`, transparent background, positioned top-center of the screen with the notch (`NSScreen.safeAreaInsets` / `auxiliaryTopLeftArea` to locate the notch).
- **Fill is always `#000000`**, regardless of system appearance. Force `.preferredColorScheme(.dark)` inside.
- Shape = custom `Shape`: top edge flush with screen top; **top corners curve outward ("ears")** as concave quarter-circles into the menu bar; bottom corners rounded.
- **Camera dead zone:** 180 × 32 pt, centered at top. Never draw content there. In the open state the top 34 pt row is usable only at its left and right ends.

| State | Size (w × h) | Ear radius | Bottom radius |
|---|---|---|---|
| Closed | 270 × 34 | 6 | 12 |
| Closed + incoming note | 270 × 56 | 6 | 16 |
| Open | 520 × 272 | 14 | 24 |

Open/close: `spring(response: 0.45, dampingFraction: 0.7)` on width/height/radii. Open content fades in `.easeOut(0.22)` with `0.08 s` delay and scales `0.94 → 1` (anchor top). Close waits **0.35 s** after the pointer leaves (hover-intent).

---

## Screens

### 1. Closed (always visible) — 270 × 34
- Two 45-pt slots, at far left and far right; middle (camera) empty.
- **Left:** days count, e.g. `1,326` — SF Pro 12 semibold, `.monospacedDigit()`, white. If no date: `♡` in tertiaryLabel.
- **Right:** `heart.fill` 14 pt, `#FF375F`. Idle heartbeat: double beat every 2.6 s (scale 1 → 1.18 → 1 → 1.1 → 1 over the first ~0.85 s, then rest).

### 1b. Closed + incoming note — 270 × 56
- Shape grows 22 pt. A strip at y 34, height 20, horizontal inset 18, with 18-pt fade masks on both edges.
- Text scrolls **right → left** at ≈ 40 pt/s: partner name in `#FF375F` semibold, two spaces, then the note in white 12 medium. E.g. `nikki  hi babe how are you? love you`.
- Scroll mode set by the sender: **3 times** then collapse, or **until opened**.

### 2. Open — 520 × 272 (shared chrome)
- **Top row** (h 34, horizontal inset 22):
  - Left (max width 148): couple names only, `sam ♥ nikki` — SF Pro 13 semibold, white; `♥` 11 pt `#FF375F`; gap 4; truncate partner name if needed. No avatars.
  - Right: `gearshape` 16 pt, secondaryLabel → opens Settings.
- **Content area:** x 16, y 40, 488 × 184. For Note/Emoji/Photo it's one card: `#1C1C1E`, radius 12, padding 12. For Home it's transparent (the bento tiles are the cards).
- **Tab bar:** native-looking segmented control, 300 × 28, centered, 10 from bottom. Track `#767680` @ 24 %, radius 8, padding 2. 4 equal items (h 24, radius 6): icon 14 + label 12 medium, gap 5.
  - Selected: fill `#636366`, shadow `0 1 2 rgba(0,0,0,.3)`, label white, icon `#FF375F` (filled symbol).
  - Unselected: transparent, label + icon secondaryLabel (outline symbol).
  - Tabs: **Home** `house`, **Note** `bubble.left`, **Emoji** `face.smiling`, **Photo** `photo` (`.fill` variants when selected).

### 2a. Home — bento
Purpose: everything from your love at a glance.
- Row, gap 8, fills 488 × 184. Text tiles `#1C1C1E`, radius 12.
- **Photo tile** (left, **square 184 × 184**, radius 14): latest photo your partner sent, aspect-fill, photo treatment applied (see below) + bottom gradient clear → black @ 55 % (from 50 % down) + inner stroke white @ 8 % 0.5 pt. Caption bottom-left (inset 12/10): `from nikki · 1h` 11.5 medium, white @ 90 %.
  - Empty: `#1C1C1E` tile, `photo` symbol 30 pt tertiaryLabel + `No photo from nikki yet` 12 secondaryLabel, centered.
- **Right column** (flex, gap 8), two equal-height rows:
  - **Note tile** (padding 12/14, centered vertically, gap 4): `bubble.left.fill` 12 pt `#FF375F` + `nikki · 2m ago` 11 medium secondaryLabel; note 15 medium, tracking −0.1, line-height 1.3, **max 2 lines**, white.
    - Empty: `No notes from nikki yet ♡` 13 regular secondaryLabel.
  - **Stats row** (gap 8), three tiles with width ratio **1 : 1 : 2.1** (padding 12/11, space-between): label 11 medium secondaryLabel on top, value 16 semibold (tracking −0.3), no wrap, at the bottom.
    - `Hours` — total hours, e.g. `31,840`
    - `Weekends` — Saturdays since start, e.g. `189`
    - `Seconds` + tiny `heart.fill` 10 pt pink with the heartbeat pulse — total seconds, e.g. `114,625,201`, **ticks every second, value in `#FF375F`**
    - No date: all values `—` (white).
- All numbers `.monospacedDigit()` with grouping separators.

### 2c. Note — write a note
- Column `space-between`.
- **Their latest:** `From nikki · 2m ago` 11 medium secondaryLabel; note 16 regular, 2 lines max.
- **Composer row** (top separator 1 pt white 8 %, padding-top 10, gap 8):
  - TextField h 34, radius 9, fill `#2C2C2E`, border 1 pt white @ 8 %, padding-x 10, 13 regular, placeholder `Say something sweet…`.
  - Focus: border `#FF375F` + 3-pt ring `#FF375F` @ 35 %.
  - Send: 32-pt circle `arrow.up` 17 semibold. Enabled: `#FF375F` / white. Disabled: white @ 10 % / tertiaryLabel. Return key sends.
- **Footer row:** left `Scroll` 12 secondaryLabel + small segmented (track `#767680` @ 24 %, r 7, pad 2; items h 20, r 5, 11.5 medium): `3 times` | `Until opened`. Right: status 11.5 medium.
- **Validation** (send disabled when any fails, hint shown in `#FF375F` in the status slot, field gets the pink ring):
  - > 60 characters → `A little shorter ♡`
  - > 10 words → `10 words max ♡`
  - any word > 15 chars → `One word is too long ♡`
  - otherwise status shows `N of 10 words` (tertiaryLabel), or `Up to 10 words` when empty.
- **Send flow:** field locks + dims → `Sending…` (secondaryLabel) → `Sent ♡` (white) → `Delivered ♡` (`#FF375F`) → field clears after ~2 s.

### 2e. Emoji — send an emoji
Purpose: one-tap affection, with a clear explanation of what happens.
- Inside the `#1C1C1E` card (padding 12), column `space-between`:
  - **Header row:** left title `Send an emoji` 15 semibold + subtitle `Tap one — it pops up on nikki's screen ♡` 11.5 secondaryLabel (gap 2). Right status 11.5 medium: `Tap to send` (tertiaryLabel) → `Sent 😘` (white) → after ~1.2 s `Delivered 😘` (`#FF375F`) → clears after ~3 s.
  - **Emoji row:** 6 equal buttons, gap 6, h 54, radius 12, fill `#2C2C2E`, emoji 27 pt: ❤️ 🥰 😘 🫶 🤗 🌹
    - Pressed: fill `#3A3A3C`, scale 0.9, spring back. Last sent: fill `#FF375F` @ 16 % + inner stroke 1 pt `#FF375F` @ 60 % until status clears.
    - On tap: 3 small copies float up ~40 pt (dx −10/0/+10, 0.9 s, 70 ms stagger).
  - **Mode row:** `Appears` 12 secondaryLabel + small segmented (same style as Note's): `Out of the notch` (`chevron.down`) | `Full screen` (`arrow.up.left.and.arrow.down.right`). Persist the choice; it's sent with each emoji.
- **On the receiver's screen:** *Out of the notch* → the emoji uses the hearts "pour" animation (2–3 copies, 17–25 pt, 1.5 s). *Full screen* → the "splash" overlay (18 copies float up, 3 s, click-through).

### 2d. Photo — send a photo
- Row, gap 16, vertically centered, inside the `#1C1C1E` card.
- Square tile 150 × 150, radius 12, photo treatment applied: the **last photo you sent**. Empty: dashed 1-pt border tertiaryLabel + `photo.badge.plus` 26 pt.
- Text column (gap 3):
  - Eyebrow 11 medium secondaryLabel: sent → `Yesterday · Delivered ♡`; empty → `Photo`.
  - Title 15 semibold: sent → `Last sent to nikki`; empty → `Send nikki a photo`.
  - Body 12 secondaryLabel: sent → `Shows on their Home until you send a new one ♡`; empty → `It shows up on their Home the next time they open their notch ♡`.
- Button (margin-top 10, h 24, r 6, 12 medium): sent → `Send New Photo…` bordered (white @ 14 %); empty → `Choose Photo…` prominent `#FF375F`. Opens `NSOpenPanel` (images), crops to square, uploads, then shows sending → delivered in the eyebrow.

### Photo treatment (applies to every partner/your photo inside the notch)
Makes any photo (the one you receive on Home, the one you sent on Photo) sit calmly on black. Setting with 3 options, default **Soft**:
1. **Soft:** `.saturation(0.75)`, `.brightness(-0.06)`, `.contrast(1.05)`; overlay `#FF375F` @ 22 % with `.blendMode(.softLight)`; bottom fade `LinearGradient(clear → #1C1C1E @ 55 %)` over the bottom 45 %; inner stroke white @ 8 %, 0.5 pt.
2. **Mono:** `.grayscale(1)`, `.contrast(1.08)`, `.brightness(-0.05)`; pink soft-light @ 35 %; fade @ 50 %.
3. **Original:** no filter.

### 3. Incoming hearts
- **1–2 hearts — pour:** 2 (or 3) `heart.fill` (14–20 pt, `#FF375F` / `#FFB3C2`) emerge just below the notch, drift ~116 pt down with ±6–8 pt sway + slight rotation, fade out. 1.5 s, 0.25 s stagger.
- **3+ hearts — splash:** separate full-screen, transparent, **click-through** window (`ignoresMouseEvents = true`). 18 hearts (14–32 pt; pink / blush / white) start below the bottom edge and float up ~360 pt with sway, fading. 3 s each, 80 ms stagger. Window closes when done.

### 4. Onboarding window — 420 × 440 pt
Standard titled window (traffic lights), **follows system light/dark**. Setup-Assistant layout: centered content (icon 44 pt `#FF2D55` or app icon, title 20–22 bold −0.3, body 13 secondaryLabel), footer h 56 with page dots left (6 pt, current = label color) and `Back` (bordered) + `Continue` (prominent pink, h 28 r 6) right.
Screens:
1. **Welcome** — app icon (72 pt, r 17, pink gradient `#FF5C7A → #FF2D55`, white heart 38), `Welcome to OurNotch`, `A little love note that lives in the top of your screen.`, `Get Started`.
2. **Name** — `What should your love call you?` / `Shown next to your hearts and notes.` / text field 240 wide.
3. **Invite** — `Invite your love` / `Share this code — it's just for the two of you.` / code `K7QM3X` in SF Mono 26 semibold, tracking 6, white box r 8 / `Copy Code` + `Send Email…` / spinner + `Waiting for your love to join…` / footer-left link `I Have a Code`.
4. **Have a code** — partner avatar 64 + `nikki ♥ invited you` / `Code K7QM3X · joined today` / `Join nikki`.
5. **Date** — `When did you get together?` / `DatePicker(.stepperField)` / `That's 1,326 days ♡` (pink 13 medium) / footer-left `Skip for Now`.
6. **Login** — `Keep your love close` / `Your notch will be there every time you open your Mac.` / grouped row `Open at Login` + Toggle (`SMAppService.mainApp`).
7. **Done** — `You're all set ♡` / `Hover the notch anytime to send nikki a little love.` / `Done`.

---

## State

```swift
// Couple / sync
myName: String; partnerName: String
latestPhotoFromPartner: (image: Image, sentAt: Date)?
myLastSentPhoto: (image: Image, sentAt: Date, delivered: Bool)?
togetherSince: Date?                         // nil → empty states
latestNote: (text: String, sentAt: Date)?    // only the latest; no history
incoming: (note: String, mode: .threeTimes | .untilOpened)?

// UI
isOpen: Bool                                 // hover-intent, 0.35 s close delay
tab: .home | .note | .emoji | .photo
photoStyle: .soft | .mono | .original        // Settings
draft: String; scrollMode: .threeTimes | .untilOpened
emoji: (sent: String?, status: .idle | .sent | .delivered); emojiMode: .notch | .fullScreen   // persisted
noteStatus: .idle | .sending | .sent | .delivered
now: Date                                    // 1 s TimelineView for counters
```

Derived (from `togetherSince` and `now`): days (closed notch), weekends (Saturdays since start), total hours, total seconds.

Backend events: `sendNote(text, mode)`, `sendEmoji(char, mode)` / `receiveEmoji(char, mode)`, `sendPhoto(image)`, `receivePhoto`, `receiveNote`, delivery receipts, `receiveHearts(count)` → pour if ≤ 2, splash if ≥ 3.

## Design tokens

**Colors (inside notch, dark)**
- Notch fill `#000000`
- Accent systemPink (dark) `#FF375F` · pressed `#D92D50` · blush `#FFB3C2`
- Card / bento tile `#1C1C1E` · field / emoji button `#2C2C2E` · pressed `#3A3A3C`
- Segment track `#767680` @ 24 % · selected segment `#636366`
- Separator white @ 8 % · bordered button white @ 14 %
- label `#FFFFFF` · secondaryLabel `#EBEBF5` @ 60 % · tertiaryLabel `#EBEBF5` @ 30 %

**Onboarding (light):** window `#F6F6F6`, accent `#FF2D55`, text `#1D1D1F`, secondary `#6E6E73`. Dark: window `#262626`, accent `#FF375F`.

**Type (SF Pro, system):** 26/22/20 bold (onboarding titles) · 16 semibold (bento stats) · 15 semibold · 14 medium (home note) / regular · 13 semibold/regular · 12 medium · 11.5 medium · 11 medium/regular · 10.5 medium (photo caption). `.monospacedDigit()` on every number.

**Radii:** 24 (open notch bottom) · 16 · 12 (cards, bento tiles, closed notch) · 10 (window) · 8 (tab track, field, photo tile) · 7 · 6 (segments, buttons) · 5.

**Spacing:** 2 · 3 · 4 · 5 · 6 · 7 · 8 · 10 · 12 · 14 · 16 · 22.

## Assets
- Icons: **SF Symbols** (the HTML uses Material Symbols as stand-ins): `heart.fill`, `house(.fill)`, `face.smiling(.fill)`, `chevron.down`, `arrow.up.left.and.arrow.down.right`, `bubble.left(.fill)`, `photo(.fill)`, `gearshape`, `arrow.up`, `photo.badge.plus`, `calendar`, `person`, `envelope`, `laptopcomputer`.
- Emoji: native Apple Color Emoji.
- Photos in the mocks are stock placeholders from picsum.photos — real photos are user-chosen.

## Files
- `OurNotch v3.dc.html` — full design doc: live prototype, every state, onboarding, spec sheet.
- `NotchMac.dc.html` — the notch component (all states + interaction logic). The logic class at the bottom is a readable reference for validation rules, status timings and stat calculations.
- `support.js` — runtime needed to open the HTML files locally.
