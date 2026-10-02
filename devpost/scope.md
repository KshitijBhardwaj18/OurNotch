---
doc: scope
status: approved
---

# OurNotch — Milestone 1

A cute little shared space for couples that lives in the MacBook notch: tap to send your partner floating hearts, or send a message that scrolls across their notch.

**This is not a throwaway hackathon demo.** OurNotch is meant to become an end-to-end product sold to couples. This document scopes **Milestone 1**: the foundation that proves the two hardest unknowns (custom notch UI + two Macs syncing through CloudKit) with production-quality code that's kept. Later milestones repeat the scope → PRD → spec → build loop.

## The Unique Kernel
The notch is always on screen, so it becomes a soft, always-there presence of your partner, not another chat app that demands attention. A heart from your partner appears in *your* notch as a cute, pulsing animation; a message scrolls by like a banner ("hi babe how are you? love you").

## Who It's For
Couples who spend their day on their Macs apart: long-distance, or in the same city but at different offices and "meet less." Today they text on iMessage/WhatsApp, which lives in a separate app and competes with everything else for attention.

## The Core Loop
1. You click the heart in your notch → soft, cute hearts float/pulse out of the notch.
2. That heart arrives in your partner's notch on *their* Mac with the same animation.
3. You type a short message → it scrolls across your partner's notch as a banner.
They come back because the notch is always there: a small, low-effort way to say "thinking of you" during the workday.

## Inspiration & Identity
Soft, cute, affectionate. Hearts floating out of the notch, gentle pulsing.

**Reference app: Boring Notch** — https://github.com/TheBoredTeam/boring.notch. Study how it solves the notch (overlay window, positioning over the notch, expand/collapse, animations), then write OurNotch's own code inspired by those solutions.
**License caution:** Boring Notch is **GPL-3.0**. Copying its code into OurNotch would require releasing OurNotch under GPL-3.0 too, which conflicts with selling a closed $8 app. Learn the approach; don't copy code.

## Why This Matters to the Learner
They want to sell it as an $8 single-license app to other couples. This build is the "start small, get it working" step before a polished, good-looking version. Learning goal: get it working, then understand the architecture and the technical decisions behind it.

## What "Working" Looks Like
Two Macs interact through OurNotch over the internet. On Mac A, you click the heart → hearts animate out of Mac B's notch. On Mac A, you send "hi babe how are you? love you" → it scrolls across Mac B's notch. **That's the "oh, that's cool" moment**, filmable in under a minute.
Testing starts on the learner's own machine; the real proof is a second Mac.

## The POC Boundary (Milestone 1)
- A notch UI on macOS with a heart button and a way to type a short message. **Aesthetic matters from the start**: it should look cute and a little polished, not a bare prototype.
- Heart animation (floating/pulsing hearts out of the notch) when one arrives.
- Scrolling banner in the notch when a message arrives.
- **Pairing:** two partners connect their apps to each other.
- **CloudKit integration is required.** Real delivery between two Macs, near-real-time.
- **Data lives in CloudKit's public database, encrypted** so only the two partners can read it. Reason: many people's iCloud storage is full, and the app must not block them; the public database uses the app's quota, not the user's.
- **Tiny data per couple:** current state is small (e.g., a single number for hearts plus the latest message), so the app should stay **free to run up to ~1,000 users**. `4-spec` should estimate usage against CloudKit's limits.

**Account plan:** the learner has no personal paid Apple Developer account yet. For development and testing, they intend to use their **company's Apple Developer account** (with the company's OK) so CloudKit can carry hearts/messages between the two Macs with no self-run backend. Before selling, they'll move to their **own** account. CloudKit containers can't be transferred between accounts, so treat the company container as throwaway test data; `4-spec` should keep the container ID easy to swap.

## Later (product roadmap)
- Days-together counter.
- "What's happening in your partner's life" view.
- A shared pet that lives in the notch and both partners feed.
- Shared notes / a place to write things down.
- Full chat.
- Polished, good-looking version.
- Explore private notch APIs: CGSSpace (own always-on-top layer) and SkyLight (show on lock screen), as studied in Boring Notch.
- Either partner can edit the together-since date.
- Payload size optimizations (e.g., compact encoding) beyond keeping data tiny.
- Move to own Apple Developer account ($99/yr) and new CloudKit container before selling; Developer ID signing + notarization for website distribution.

## Explicitly Cut
- **Selling / $8 licensing / payments:** not needed to prove hearts and messages work between two Macs; comes with the polished product.
- **App Store distribution:** they'll sell from their own website, not the App Store.
