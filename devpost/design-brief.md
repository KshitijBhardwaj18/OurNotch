# OurNotch — Design Brief (paste this into any design agent)

Design the UI for **OurNotch**, a tiny macOS app for couples that lives in the MacBook's camera notch. Partners send each other hearts and short notes, and each sees a photo the other chose. It should feel **cute, soft, affectionate, and calm** — a quiet presence of your partner during the workday, not a chat app. Think "a love note tucked into the top of your screen."

## How the notch works (hard constraints)

- The app draws a **pure black shape (#000000) that grows out of the real camera notch** at the top-center of the screen, so it looks like the notch itself expands. The top edge is flush with the top of the screen; the top corners curve outward into the menu bar like small concave "ears" (~6 pt closed, ~14 pt open); the bottom corners are rounded (~12 pt closed, ~24 pt open).
- **The camera area is a dead zone.** The physical notch is about **180 × 32 pt** in the top-center. Anything drawn there is hidden by the camera housing. In the open state, the top ~34 pt row has this dead zone in its center; only its left and right ends are usable.
- **Always dark** (the shape must blend with the black notch), regardless of the user's light/dark mode. Text and accents sit on pure black.
- Sizes are in **points** (render mockups at 2× on a MacBook screen, showing a bit of menu bar and wallpaper around the notch for context).
- It's built in **SwiftUI**: use SF Pro / SF Pro Rounded and SF Symbols (no custom font files), simple shapes, and system controls styled to fit. No web-only effects.

## States to design

### 1. Closed notch (always visible)
- About **270 × 34 pt**: the days-together number on the **left** of the camera, a small heart on the **right**. The middle (camera) stays empty.
- **Closed + incoming message:** the shape grows ~22 pt taller and the partner's message **scrolls right-to-left** in a strip under the camera (marquee), e.g. "hi babe how are you? love you".
- Optional: suggest a subtle idle detail (a tiny heartbeat pulse) — keep it restrained.

### 2. Open notch (on hover) — the main redesign
The current open notch crams everything into one screen and feels cluttered. Reorganize it like **NotchBuddy** (https://notchbuddy.app): **one job per tab, with a tab bar at the bottom**, content in soft rounded cards with generous spacing, a short title per tab. Target size **about 460–560 pt wide × 220–280 pt tall** (propose the best size; smaller is better if it stays uncluttered).

Tabs (icon + short label):

**Home** — the heart of the app
- **Your love's photo**: one image your partner chose to represent them. Make it the emotional center (e.g. a rounded or circular photo with a soft rose ring). Empty state when they haven't picked one yet (e.g. "your love hasn't picked a photo yet ♡").
- **Time together**: big days count + a live counter ticking up (e.g. "1,326 days · 16h 33m 21s"). Empty state when the date isn't known yet.
- **The heart button**: big, tactile, the most tappable thing on the screen. Tapping sends one heart. Small status under it: "sent ♡" → "delivered ♡".
- Optionally a one-line peek at the last message received.

**Message**
- Last message from your love (only the latest; no history), e.g. "hi babe how are you? love you".
- A text field ("say something sweet…"). Limits: **max 10 words, 60 characters, 15 characters per word**; when over, the send button is disabled and a gentle hint shows ("a little shorter ♡", "10 words max ♡", "one word is too long ♡").
- A choice of how it scrolls on your love's notch: **"scroll 3×"** or **"until opened"**.
- Send button, then status "sending…" → "sent ♡" → "delivered ♡".

**Photo**
- "your photo on their notch": preview of the image you've chosen for your partner to see, with a **change photo** button (opens the Mac's file picker). Empty state before one is chosen.

Show each tab in its normal state plus its key states: Home with/without photo; Message empty, typing (valid), over the limit (hint), and sent/delivered; Photo empty and set. Show the tab bar's selected/unselected states and the heart button's pressed state.

### 3. Incoming hearts (effects, optional restyle)
- 1–2 new hearts: soft hearts **pour out from under the notch**, drifting down with a gentle sway and fading (~1.5 s).
- 3+ hearts (e.g. missed while asleep): a **full-screen, click-through splash** of hearts floating up (~3 s).
- Suggest heart shapes/colors/sizes for these.

### 4. Onboarding window (secondary, optional)
A small normal window (~420 × 440 pt, follows light/dark mode), one thing per screen: welcome → "what should your love call you?" → "invite your love" (shows a 6-letter code like **K7QM3X** and a "send email" button, then "waiting for your love to join…") or "I have a code" (enter code → "nikki ❤ invited you") → "how long have you been together?" (date) → "keep your love close" (open at login toggle) → done.

## Visual direction

- Current colors (feel free to propose a cuter palette that still works on pure black): rose **#FF7AA2** (hearts, primary buttons), blush **#FFC2D4** (highlights), white text, secondary text white at 60%.
- Type: **SF Pro Rounded**; numbers with fixed-width digits so counters don't jiggle.
- Copy tone: short, soft, **lowercase-cute** ("sent ♡", "delivered ♡", "waiting for your love…").
- Motion: springy open/close with a slight bounce, gentle fades; nothing harsh or flashy.
- **Avoid:** clutter, generic glassy dashboards, gradients everywhere, emoji overload, tiny unreadable text, anything placed behind the camera.

## Deliverables

1. Mockups of every state above (closed, closed + banner, each open tab and its key states, effects, optional onboarding).
2. A **spec sheet** a developer can build from: exact sizes and spacing in points, corner radii, colors as hex (with opacity), font sizes and weights, SF Symbol names for icons, and the tab bar's dimensions.
3. One sentence per tab explaining why it's laid out that way.
