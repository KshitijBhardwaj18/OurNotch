---
doc: scope
milestone: 2
status: approved
---

# OurNotch — Milestone 2: Ready to Sell

Turn the working notch app ("we are in half big product") into something a stranger can find, buy in their own currency, install, pair, and keep loving — sold from our own website to couples in India, the US and Europe.

## The Unique Kernel
A little place in the notch **where things from both of you arrive**, so you get reminded of each other in the middle of the day. Not a chat app, a fun, always-there presence of your partner. Milestone 1 proved it works between two Macs; Milestone 2 makes it sellable.

## Who It's For
Couples who spend the day apart, each on their own Mac:
- **long-distance** couples;
- couples living in the same city or even together, but at **different colleges, schools or workplaces** during the day;
- students in **hostels**: you in your room, your boyfriend or girlfriend in theirs.

They want something of their own to enjoy. One partner buys it as a **gift** for the two of them: Valentine's Day is the big moment ("something for the two of you").

## The Core Loop
Unchanged from Milestone 1: a heart, note, mood or photo arrives in your notch from your partner, and you send one back. New in this milestone is the loop that comes before it: **find OurNotch on the website → one partner pays → both install → pair → the first heart arrives.**

## Inspiration & Identity
Cute, warm, gift-like; the v3 design (`design_handoff/`) stays the visual base. Launch prices are shown plainly, with no fake discounts (decided in the PRD).

## Why This Matters to the Learner
OurNotch was always meant to be "a polish product for other couples," not a demo. Right now "everything can be better": the landing page, the performance, the onboarding. This milestone is where it becomes a real product people pay for.

## What "Working" Looks Like
- A stranger lands on the website (our own domain), sees the price for their country, pays through Dodo, installs the app and pairs with their partner **without help**.
- The buyer gets a new Mac and their licence follows them. (Changing partners is deferred; see `prd-m2.md`.)
- The app works in English, French and German, and fits the notch in all three.
- A week of daily test runs on real Macs: `metrics.csv` and logs show no hangs and fast delivery.
- The "oh, that's cool" beat: on Valentine's Day, someone buys it for ₹200 / $4.50 / €3 and minutes later a heart floats out of their partner's notch.

## The Milestone 2 Boundary
**Order (learner decision): licensing and payments first**, then UI/UX, then packaging, landing page, daily testing, launch.

1. **Licence and payments (Dodo Payments)**
   - One purchase unlocks the pair. The buyer owns the licence for good: it moves with them to a new Mac. The partner is covered only while paired with the buyer. (Moving to a new partner is deferred, decided in the PRD.)
   - One-time purchase, **no trial** ("trials don't work").
   - Launch prices (can change later; no struck-through prices, decided in the PRD):

     | Region | Launch price |
     |---|---|
     | US and everywhere else | $4.50 |
     | India | ₹200 |
     | Europe | €3 |
   - **Tracking lives with the landing page:** an owner-only admin page in the Next.js app reads purchases, keys and activations straight from Dodo's API. Dodo is the database: no database or customer accounts of our own (PRD decision B). Customers find their key in Dodo's customer portal.
   - **Kill switch:** if a licence is abused or a hacked copy shows up in the tracking, we can **revoke** that licence. The privacy policy and terms say so ("if we notice abuse, we can revoke your licence").
   - **If the server dies, licences keep working.** The app never depends on it to run; only an explicit "revoked" turns a licence off.
   - Cracking the app binary is accepted. The protection stops casual key sharing, not determined crackers.
2. **UI/UX pass**
   - Better onboarding, and polish everywhere.
   - **Hide / pause OurNotch** for a while, and bring it back.
   - All text in Apple's String Catalog as we go.
3. **Languages**: English, French, German.
4. **Packaging**: own Apple Developer account and a new CloudKit container, Developer ID signing and notarization, an installer, auto-updates, CloudKit Production.
5. **Landing page**: a Next.js site on our own domain with regional prices, the Dodo checkout, the licence server, and a privacy policy and terms (including licence revocation and refunds). Being started in parallel in `website/`.
6. **Performance audit and monitoring**: daily test runs using the Milestone 1 metrics (`metrics.csv`), fixing what fails before launch.

**Must fix before real users** (carried from Milestone 1): protection against pairing with the wrong person; unpairing and re-pairing; diagnostics and metrics no longer readable by every install.

## Later
- Stricter limits on how often a licence can move, if sharing shows up in the tracking data.
- More languages after French and German.
- Changing prices after the launch offer.
- Product features from the roadmap: shared pet, chat, gallery, "what's happening in your partner's life."

## Explicitly Cut
- **Free trial**: the learner's call; "trials never work," and paying first fits the gift.
- **Subscription**: a one-time licence is simpler, and CloudKit's free tier means no running cost forces recurring billing.
- **Fighting app cracking**: no small Mac app can stop it, and at $4.50 most people simply pay.
- **Dodo compliance pre-clearance**: the learner reads Dodo's "real-time person-to-person" ban as aimed at chat and dating, not a playful notch for an existing couple. Risk accepted; see `research-dodo.md`.
- **Mac App Store**: sold from our own website.

## Open Questions
Say "ask me" any time; answered ones move into the sections above.
- Refund policy (Dodo's default window is 30 days)?
- Should other countries (UK, Canada, Australia…) pay in USD, or get their own price?
- How long should the app keep working offline before it must re-check the licence?
- Hide/pause: from where (♡ menu, in-notch Settings, keyboard shortcut), for how long, and do hearts and notes queue up while hidden?
- A walk-through of what feels wrong on each screen today (onboarding, closed notch, Home, Note, Emoji, Mood, Photo, Settings), plus the edge cases from the two-Mac test.
- From Milestone 1: bring "Days" back? Numbers in the Mac's grouping or always US style? A "Quit OurNotch" button in Settings? How does the no-notch pill look on your partner's M1?
- Who checks the French and German translations?
- The domain name, and when your own Apple Developer account will be ready.
- Hosting the website and licence server for free: which host allows a commercial site on its free plan, and does the free database stay awake (some pause after a week without use)?
- What counts as "good data" to launch? For example, 7 days on 3 pairs with no hangs and 95 % of deliveries under 15 s.
