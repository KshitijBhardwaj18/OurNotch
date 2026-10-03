# Prompt for Claude Code

Copy everything below the line into Claude Code, from the root of the OurNotch Xcode project, with this `design_handoff_ournotch/` folder inside the repo (or next to it).

---

We have a new design for OurNotch's notch UI. It's in `design_handoff_ournotch/`. Please implement it in our existing SwiftUI app.

## How to read the handoff
1. **Read `design_handoff_ournotch/README.md` first, all of it.** It is the source of truth: every size (in points), color (hex + opacity), font size/weight, radius, SF Symbol name, copy string, animation timing, validation rule and state transition.
2. The `.dc.html` files are **visual references only, not code to port**. To see them, open `OurNotch v3.dc.html` in a browser (keep `support.js` and `NotchMac.dc.html` beside it; needs internet for fonts/photos). The live prototype at the top responds to hover and clicks; every state is shown below it, and there's a spec sheet at the bottom.
3. If the README and the HTML disagree, follow the README. For timings, validation and the stat math, the logic class at the bottom of `NotchMac.dc.html` is a readable reference.
4. Icons in the HTML are Material Symbols stand-ins. Use the SF Symbols named in the README.

## What's new / changed (vs. our current build)
- **Open notch is bigger: 520 × 272 pt** (ears 14, bottom radius 24). Closed is still 270 × 34. Never draw inside the 180 × 32 camera dead zone.
- **Native macOS look:** SF Pro, systemPink `#FF375F`, `#1C1C1E` cards, standard semantic label colors, native-style small segmented controls and bordered/prominent buttons. Force dark inside the notch.
- **Top row:** couple names only, top-left: `sam ♥ nikki` (no avatars). Settings gear top-right.
- **4 tabs in a bottom segmented control (300 × 28):** Home · Note · Emoji · Photo.
- **Home = bento:**
  - square **184 × 184** tile with the latest photo your partner sent (with caption `from nikki · 1h`);
  - their latest note (2 lines max);
  - three stat tiles — **Hours, Weekends, Seconds** — ratio 1 : 1 : 2.1; seconds tick live every second in pink.
- **Note:** send a short note (max 10 words / 60 chars / 15 per word, with gentle hints) and choose how it scrolls on their notch: **3 times** or **Until opened**. Status: Sending… → Sent ♡ → Delivered ♡.
- **Emoji (new tab):** clearly titled "Send an emoji", subtitle "Tap one — it pops up on nikki's screen ♡". Six one-tap emoji (❤️ 🥰 😘 🫶 🤗 🌹), plus an **"Appears" option: Out of the notch | Full screen** (persisted, sent with each emoji). On the receiver's side, "out of the notch" uses the pour animation and "full screen" uses the click-through splash overlay.
- **Photo (now "send a photo"):** shows the last photo you sent (150 × 150 square) and its delivery status, with **Send New Photo…** (NSOpenPanel → crop square → upload).
- **Photo treatment:** every photo inside the notch gets a fixed filter so it blends with the black notch. Default **Soft**: saturation 0.75, brightness −0.06, contrast 1.05, systemPink soft-light overlay at 22 %, bottom fade. Also offer Mono and Original in Settings.
- **Incoming hearts:** 1–2 → pour from under the notch (1.5 s); 3+ → full-screen click-through splash (3 s).
- **Onboarding window (420 × 440):** Setup-Assistant style, follows light/dark — Welcome → name → invite code (K7QM3X) / I Have a Code → date → Open at Login → Done.

## How I'd like you to work
1. Explore our codebase first: notch window/shape, current views, models, sync layer. Summarize what exists and propose a plan mapped to the README sections before writing code.
2. Build in this order: notch shape and sizes → shared chrome (top row + tab bar) → Home bento → Note → Emoji → Photo → photo treatment → incoming animations → onboarding.
3. Reuse our existing models and networking; add only the fields the README's **State** section needs (e.g. `latestPhotoFromPartner`, `myLastSentPhoto`, `emojiMode`, `sendEmoji(char, mode)`).
4. Use `.monospacedDigit()` on every number, and a 1-second `TimelineView` for the live counters.
5. Match the README pixel-for-pixel. When something is ambiguous, ask me instead of guessing.
6. After each step, tell me how to run and check it.
