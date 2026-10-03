---
doc: prd
status: approved
---

# OurNotch — Product Requirements (Milestone 1)

A cute, minimal shared space for couples that lives in the MacBook notch: see how long you've been together, send your partner hearts, and send a message that scrolls across their notch.
Source: `scope.md > The Unique Kernel`, `scope.md > The Core Loop`, `scope.md > The POC Boundary (Milestone 1)`.

## The Core Journey
1. **Welcome.** On first launch, OurNotch shows a few short onboarding screens explaining what it does.
2. **Sign in with Apple.**
3. **Pair with your love** (one of two paths):
   - **Invite:** tap *Invite your love* → OurNotch shows a short **invite code** → tap *Send email* → your own Mail app opens with a cute, pre-written OurNotch invite containing the code and a download link → you send it. While waiting, you see the code and a "waiting for your love to join" state.
   - **Join:** install OurNotch, sign in with Apple, choose *I have a code*, enter the code → a cute confirmation, e.g. "**Nikki ❤ invited you**" → paired.
4. **One relationship question:** "How long have you been together?" (the date you got together).
5. **Permissions:** OurNotch walks you through turning on any Mac settings it needs.
6. **Live in the notch.** The closed notch shows your days-together count and a heart.
7. **Send a heart:** open the notch, tap the heart → your partner's notch pours out hearts.
8. **Send a message:** open the notch, type a message, choose how it scrolls, send → it scrolls across your partner's closed notch. You see *Sent*, then *Delivered*.
9. **Success:** two Macs, two partners, hearts and messages arriving within seconds.

## Screens and Layout
- **Onboarding window** (first launch only): welcome screens → Sign in with Apple → Invite / I have a code → "How long have you been together?" → permissions → done.
- **Closed notch** (always visible): days-together number + a heart. This is also where incoming hearts pour out and incoming messages scroll.
- **Open notch** (expands like Boring Notch), organized into **tabs** like NotchBuddy (https://notchbuddy.app): a **Home** tab (your love's photo, time together counting up live, the heart button) and tabs for the other things (messages; the photo you show on your love's notch). One job per tab, so the small space never feels cluttered.
- Everything inside the notch must be arranged carefully. It's a small space, and great UX is a requirement, not polish for later.

## Look and Feel
- **Cute, minimalistic, modern.**
- Soft, gentle animations: hearts pulse and float out of the notch rather than popping harshly.
- Reference for notch behavior (closed shows a little, open shows more): Boring Notch, https://github.com/TheBoredTeam/boring.notch. Learn from its approach; don't copy code (GPL-3.0, see `scope.md > Inspiration & Identity`).
- Not established yet: specific colors and fonts. `4-spec` proposes concrete styling that matches "cute, minimal, modern" for the learner to agree to.

## Features and Behavior

### Onboarding and Sign In
- As a new user, I want a short welcome and Sign in with Apple so I can get started without making an account.
  - [ ] First launch shows onboarding screens, then a Sign in with Apple button.
  - [ ] After signing in, I can choose *Invite your love* or *I have a code*.
  - [ ] Onboarding asks only one relationship question: the date we got together.

### Pairing
Source: `scope.md > The POC Boundary (Milestone 1)` (pairing).
- As someone inviting my partner, I want to send them a code from my own email so pairing doesn't need anyone's email address to match.
  - [ ] *Invite your love* shows a short invite code.
  - [ ] *Send email* opens my default Mail app with a pre-written OurNotch invite including the code and a download link.
  - [ ] Until my partner joins, I see a waiting state showing the code.
- As the invited partner, I want to enter the code and see who invited me.
  - [ ] Entering a valid code shows "[Partner name] ❤ invited you" and completes pairing on both Macs.
  - [ ] Entering an invalid or used code shows a gentle error and lets me try again.

### Days Together
- [ ] The closed notch shows the number of days together, next to a heart.
- [ ] The open notch shows the time together counting up live (days down to seconds).

### Sending Hearts
- As a partner, I want to tap a heart so my love sees hearts come out of their notch.
  - [ ] Tapping the heart in the open notch sends one heart.
  - [ ] On my partner's Mac, hearts gently pour out of the closed notch within seconds.
  - [ ] I see *Sent*, then *Delivered* once it reaches their Mac.

### Missed Hearts
- [ ] If hearts arrive while my partner's Mac is asleep or offline, they aren't lost. When the Mac comes back, OurNotch knows how many hearts arrived while it was away.
- [ ] **Fewer than 3** missed hearts → hearts pour out of the notch.
- [ ] **3 or more** missed hearts → a **full-screen splash of hearts**.

### Sending Messages
Source: `scope.md > The Core Loop`.
- As a partner, I want to send a short message that scrolls across my love's notch.
  - [ ] The open notch has a message box and a send button.
  - [ ] **Message validation:** at most **10 words**, with a total character cap and a per-word length cap so a single very long "word" can't overflow the banner (starting values: 60 characters total, 15 per word; tune during build). Send is disabled with a gentle hint when over the limit; empty or whitespace-only messages can't be sent.
  - [ ] Before sending, I choose how it scrolls: **3 times then disappears**, or **until they open the notch**.
  - [ ] On my partner's Mac, the message scrolls across the closed notch as a banner, following my choice.
  - [ ] I see *Sent*, then *Delivered*.
  - [ ] My partner can see **the last message** in the open notch. Only the last one; there's no history.

### Your Love's Photo
Added after the slice 2 checkpoint (learner: the open notch felt cluttered; a photo that represents your partner "sounds cute").
- As a partner, I want to choose one image that shows on my love's open notch, so it feels like me.
  - [ ] I can pick an image from my Mac; it shows on my partner's open notch (Home tab), and stays there permanently.
  - [ ] I can change it anytime; the new one replaces the old one. Only one image, no gallery.
  - [ ] Before my love has chosen one, my notch shows a gentle empty state.
  - [ ] Only the two of us can see it (encrypted like everything else).

### Your Mood
Added at the slice 5 review (learner: the closed notch should feel like your partner, not a counter).
- As a partner, I want to set my mood so my love sees how I'm doing at a glance.
  - [ ] The open notch has a **Mood** tab with a set of moods, each an emoji with a label (e.g. 😴 Sleepy, 💻 Busy, 🥺 Missing you). Tapping one sets it; tapping it again clears it.
  - [ ] My love's **closed notch** shows a small round avatar of me (from the photo I sent) and my mood emoji to the left of the camera; the ❤️ heartbeat stays on the right. The days count moves off the closed notch.

## States and Boundaries
- **First use / not signed in:** onboarding window; the notch isn't active yet.
- **Signed in, not paired:** invite or enter-code options; the inviter sees a waiting state with the code.
- **Paired, nothing new:** closed notch shows days together + heart.
- **Partner's Mac asleep or offline:** hearts and the latest message wait; they're shown when the Mac comes back (see Missed Hearts). Status stays *Sent* until it arrives, then *Delivered*.
- **Invalid code:** gentle error, try again.
- **Message over the limit or empty:** send is disabled with a gentle hint.
- **What persists:** pairing, together-since date, the last message, the count of hearts not yet seen, and your love's photo.
- **Privacy:** only the two partners can read their hearts and messages (`scope.md > The POC Boundary (Milestone 1)`: encrypted).
- **iCloud storage full:** OurNotch still works (`scope.md > The POC Boundary (Milestone 1)`).

## Product Decisions
- **Pair by invite code, not email matching.** This avoids needing a server and works even if someone signs in with Apple's "Hide My Email."
- **The invite email is sent from the user's own Mail app.** It feels personal and needs no email server.
- **Only one onboarding question** (together-since date), because Milestone 1 only shows the days-together count.
- **The sender chooses the banner behavior** (3 scrolls, or until opened).
- **Missed hearts are celebrated:** 3+ becomes a full-screen splash; fewer pour from the notch.
- **Only the last message is kept**, so there's no chat history.
- **The animated character is not in Milestone 1.** A heart is used instead.
- **Assumption:** the partner name shown in "[Name] ❤ invited you" comes from the name given at Sign in with Apple.
- **Messages are limited to ~10 words**, plus a character cap and a per-word cap, so they fit the notch banner and can't be broken by one long word.

## What We're Building
Onboarding with Sign in with Apple; a tabbed open notch with your love's photo; pairing by invite code with a Mail-app invite; the together-since question; a permissions step; a closed notch with days together + heart; an open notch with a live counter, heart button, message box with scroll option, last message, and sent/delivered; incoming hearts (pour or full-screen splash for 3+ missed); an incoming scrolling message banner; delivery between two real Macs through CloudKit, encrypted, working even when iCloud storage is full.

## Deferred From the POC
- **Animated character you choose:** the product's signature later; a heart is enough to prove the loop.
- **Gallery, favorite place:** these need their own screens and storage. (One partner photo moved into Milestone 1 after the slice 2 checkpoint.)
- **Message history / full chat:** the last message proves messaging.
- **Automatic invite emails sent by OurNotch:** these need an email server.
- **Unpairing, re-pairing, signing out:** not needed to prove the loop.
- **Protection against pairing with the wrong person** (a mistyped or guessed code connecting strangers): a real risk the learner raised; deliberately deferred to focus on building. Must be addressed before real users.

## Possible Later Enhancements
- A shared pet that lives in the notch and both partners feed.
- "What's happening in your partner's life."
- Shared notes.
- Payload optimizations.
- A polished visual pass, more animations, and sounds.

## Non-Goals
- **Selling, licensing, payments:** these come with the polished product (`scope.md > Explicitly Cut`).
- **App Store distribution:** it will be sold from their own website.
- **Being a chat app:** OurNotch is a quiet presence, not a messenger.

## Open Questions
- **Macs without a notch** (older MacBooks, external monitors): does OurNotch show a notch-shaped pill at the top center like Boring Notch? It can wait for `4-spec`, but testing on the partner's Mac depends on the answer.
- **Which Mac permissions** are actually needed. This is decided in `4-spec`; the onboarding step only shows what's needed.
- **How the app knows which hearts were missed.** This is how it works behind the scenes, decided in `4-spec`.
