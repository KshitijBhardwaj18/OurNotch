---
doc: prd
milestone: 2
status: approved
---

# OurNotch — Product Requirements (Milestone 2: Ready to Sell)

OurNotch, sold from our own website to couples who spend the day apart on their own Macs: one partner pays once, in their own currency, and both get a little place in the notch where things from each other arrive.
Source: `scope-m2.md` (approved). Milestone 1 behavior (`prd.md`) stays as is unless changed here.

## The Core Journey
Source: `scope-m2.md > The Core Loop`.

1. A visitor lands on the website and sees the gift story, a heart arriving in a notch, and the **launch price for their country**: $4.50, ₹200 or €3. No struck-through prices.
2. They click **Buy**, pay on Dodo's checkout (cards everywhere; UPI and RuPay in India), and land on our **thank-you page**.
3. The thank-you page offers **Download OurNotch**, then **Open OurNotch**. Opening activates the app automatically, so the buyer never types a key. Dodo also emails a receipt with the licence key as a backup.
4. *Alternative start:* someone downloads the free app first. On first open, the **licence gate** offers **Get OurNotch — [price]** (checkout in the browser, then back into the app, activated), **I have a licence key**, and **I have an invite code**.
5. The activated buyer goes through onboarding as in Milestone 1 and creates an invite. The Mail invite becomes a **surprise**: "[Name] planned a surprise for you, sweetheart", with the download link and the code.
6. The partner downloads the free app, chooses **I have an invite code** at the gate, and pairs. They're covered by the buyer's licence while paired.
7. The first heart arrives. From here the Milestone 1 loop runs: hearts, notes, moods, photos.
8. *Later:* the buyer sets up a new Mac by pasting the key from the receipt email, or from Dodo's customer portal via **Find my licence**.
9. *If a licence is revoked or refunded,* OurNotch blocks and says why, with a way forward.

## Screens and Layout
New or changed surfaces only. Everything else is as in Milestone 1.

- **Licence gate** (app, first open). It replaces the start of onboarding for anyone not yet activated or paired. Three choices: Get OurNotch, I have a licence key, I have an invite code. Activated buyers continue into the existing onboarding; partners go straight to joining.
- **Licence blocked screen** (app). Shown instead of the notch when the licence is revoked or refunded.
- **In-notch Settings** gains: **Hide OurNotch**, **Language**, and a **Licence** row (status, Find my licence, Remove from this Mac).
- **♡ menu bar** gains **Show OurNotch** (while hidden) and **Hide OurNotch**.
- **Website:** landing page, thank-you page, privacy policy, terms. See *The Landing Page*.
- **Admin page** (website, owner only).

## Look and Feel
- The app keeps the v3 design (`design_handoff/`); new screens (gate, blocked screen, Settings rows) follow it.
- The licence gate and the invite email should feel like opening a gift, not a software activation dialog.
- The website carries the same cute, warm, gift-like feel (the existing "pop" design in `website/`). Prices are shown plainly, with no fake discounts.
- Specific UI/UX changes come from the learner's own walk-through (see *UI/UX Pass*).

## Features and Behavior

### Buying and Prices
Source: `scope-m2.md > The Milestone 2 Boundary > 1`.
- One one-time purchase per couple, **no trial**. Prices are fixed per region, not converted:

  | Region | Launch price |
  |---|---|
  | US and every other country | $4.50 |
  | India | ₹200 |
  | Europe (euro countries) | €3 |
- **No struck-through prices at launch.** A struck-through price must be one we actually charged for a while first (US FTC pricing guides, California §17501, EU 30-day rule). Higher prices and a real sale (e.g. Valentine's) come later.
- Dodo is the seller of record: it charges tax and sends the receipt.
- **No refunds** (learner). The terms say so, except where the law requires one (e.g. EU consumer rules); Dodo applies those.

- [ ] A visitor from India sees ₹200, one from Germany sees €3, and one from the US sees $4.50, on the website and at checkout.
- [ ] A test purchase in Dodo's test mode ends on the thank-you page, and a receipt email with a licence key arrives.

### Activation
- **Invisible when possible.** Open OurNotch on the thank-you page, or Get OurNotch inside the app, activates without typing a key.
- **Pasting the key always works** (I have a licence key), for reinstalls, new Macs, or a button that didn't work.
- **Find my licence** opens Dodo's customer portal: the buyer enters their purchase email, gets a sign-in link, and sees their key.
- A key works on **one Mac at a time: the buyer's.** The partner's Mac uses no slot; it's covered through the pairing (learner). Two slots would let a second couple share one purchase.
- **Remove from this Mac** (Settings → Licence, only there) frees this Mac's slot. If a Mac is lost or sold, the buyer writes to us and we free the slot from the admin page.
- **The app keeps working without the internet or our server, for as long as it takes.** It trusts its last good check and checks again whenever it's online; only an explicit "revoked" or "refunded" answer blocks it (learner).

- [ ] After a test purchase, clicking Open OurNotch opens the app already activated, with no key typed.
- [ ] Pasting the key from the receipt email activates a fresh install.
- [ ] A wrong or made-up key shows a kind error and stays on the gate.
- [ ] With Wi-Fi off, an activated OurNotch still opens and works.
- [ ] A second Mac trying the same key is told it's already in use on another Mac, and how to free it (Remove from this Mac, or write to us).

### Invite as a Surprise
- After activating, the buyer invites their partner from their own Mail app, as in Milestone 1. The email reads as a gift: "[Name] planned a surprise for you, sweetheart", with the download link and the invite code.
- **Only an activated buyer can create an invite.** The gate gives a partner only the invite-code path.

- [ ] The invite email opens in Mail with the surprise wording, the download link and the code filled in.
- [ ] A partner who enters the code at the gate pairs and reaches the notch without any licence step.

### Pairing With the Right Person
Source: `scope-m2.md > The Milestone 2 Boundary` (must fix before real users).
- **Both sides confirm before pairing.** The partner enters the code and sees "**[Buyer]** invited you, is that right?" Nothing happens until they say yes. The buyer's Mac then asks "**[Partner]** wants to join, is this your love?" They're paired only when both say yes.
- **No means no pairing.** If the buyer declines, the joiner is told gently that it didn't work. The code stays open for the right person until it expires.
- **Codes expire after 24 hours** (learner considered 8–24 hours) and work only once. The buyer can make a new code any time.

- [ ] Entering a code shows the buyer's name with a confirm step; declining there leaves both Macs unpaired.
- [ ] After the partner confirms, the buyer's Mac asks to approve by the partner's name; only Yes pairs both Macs.
- [ ] Buyer declines: the joiner sees a gentle "that didn't work" message, and the code still works for the right person.
- [ ] A code older than 24 hours shows "this code has expired, ask your love for a new one."

### Revoked or Refunded Licence
Source: `scope-m2.md > The Milestone 2 Boundary > 1` (kill switch).
- We can revoke a licence from the admin page if we notice abuse. A refund through Dodo disables the key too.
- OurNotch then blocks and shows: **"Your licence has been revoked. Get a new one, or write to us at [support email] if you think this is a mistake."** It offers buttons for Get OurNotch and the email. A refund gets similar, gentler wording.
- **Revoking the buyer's licence blocks both Macs in the pair** (learner).
- The privacy policy and terms say we may revoke a licence for abuse.

- [ ] Revoking a test key on the admin page blocks that Mac within one licence check, showing the message and both buttons.
- [ ] Refunding a test purchase in Dodo blocks the app the same way.

### Hide and Pause
- **Settings → Hide OurNotch** asks for how long: for 1 hour, until tomorrow, or until I bring it back.
- While hidden, nothing shows in the notch. The ♡ menu offers **Show OurNotch**, and an optional keyboard shortcut toggles it. *(Shortcut proposed, not yet confirmed.)*
- Hearts, notes and other arrivals **wait**. When OurNotch comes back, they play **once**.
- **Your partner sees that you're away** (e.g. "away" where your mood shows in their closed notch) until you're back.

- [ ] Hiding "for 1 hour" removes the notch; it returns by itself after an hour, or earlier via ♡ → Show OurNotch.
- [ ] A heart sent while hidden plays once when OurNotch comes back, not before.
- [ ] The partner's closed notch shows "away" while hidden and clears when shown again.

### Languages
Source: `scope-m2.md > The Milestone 2 Boundary > 3`.
- English, French and German. OurNotch **follows the Mac's language**, and **Settings → Language** can override it.
- Every screen fits the notch in all three languages; longer German words don't wrap or clip.
- Translations are checked by a native speaker before launch.

- [ ] On a Mac set to French, every screen (gate, onboarding, notch tabs, Settings, blocked screen) shows French, with nothing clipped or wrapped.
- [ ] Choosing Deutsch in Settings switches OurNotch to German without changing the Mac's language.

### UI/UX Pass
Source: `scope-m2.md > The Milestone 2 Boundary > 2`.
- Better onboarding and polish everywhere, driven by the learner's own walk-through of each screen (still to come; see Open Questions).
- Carried from Milestone 1 for a decision: bring back "Days"? Number grouping style? A Quit button in Settings? The no-notch pill on the partner's M1. Edge cases from the two-Mac test.

### The Landing Page
Being built in parallel with another agent in `website/` (a Next.js app on **ournotch.app**). Details get finalised there; this is what it must contain for selling to work, from what we found:
- **The story:** a gift for couples who spend the day apart (long-distance, different colleges, schools or workplaces, hostels), with a heart arriving in a notch shown in motion.
- **Prices by country:** the visitor's regional price (no strikethrough) and a **Buy** button that opens Dodo's checkout (static checkout link, country decides the price).
- **Download** for the free app (the partner needs it too).
- **Thank-you page, as a 3-step guide:** ① Download OurNotch → ② Open OurNotch (activates the app with the key Dodo passes back) → ③ Invite your love (the surprise email). The key is shown underneath as a backup.
- **"My licence" help page:** where to find your key (receipt email or Dodo's portal), moving to a new Mac, and what to do if something goes wrong.
- **Find my licence:** a link to Dodo's customer portal.
- **Privacy policy:** what's stored (encrypted pairs in iCloud, no message content readable by us, purchase data held by Dodo), diagnostics, and the right to revoke for abuse.
- **Terms:** one licence per couple, owned by the buyer; revocation for abuse; **no refunds** except where the law requires; contact email.
- **French and German versions** of the page.
- **Admin page** in the same app (below).

- [ ] Each acceptance criterion under *Buying and Prices* and *Activation* passes from the live site.
- [ ] Privacy policy and terms are linked from every page and mention revocation and refunds.

### Admin Page
Source: learner decision B (Dodo is the database; no customer accounts).
- A private page in the Next.js app, **only for the owner**, pulling live from Dodo.
- Shows **sales** (date, country, price, refunds) and **licence keys** (status, how many Macs use each).
- Actions: **revoke / restore** a key (kill switch), and **free a slot** for a lost Mac.
- No database of our own and no customer accounts; customers use Dodo's portal.

- [ ] The admin page lists a test purchase with its country and price, and its key with 1 Mac in use after activation.
- [ ] Revoke on the admin page makes the app's next licence check block (see *Revoked or Refunded Licence*); restore unblocks it.
- [ ] Someone who isn't the owner can't open the admin page.

### Packaging and Updates
Source: `scope-m2.md > The Milestone 2 Boundary > 4`.
- The download opens on a fresh Mac **without warnings** about an unidentified developer.
- OurNotch **updates itself** when a new version is out. *(How it asks is to be decided; assumption: it offers the update and installs on approval.)*
- Runs on our own Apple Developer account and a new iCloud container. Couples from testing pair again.

- [ ] On a Mac that never ran OurNotch, the downloaded app opens with no Gatekeeper warning.
- [ ] Publishing a newer version makes an installed copy offer and install the update.

### Performance and Monitoring
Source: `scope-m2.md > The Milestone 2 Boundary > 6`.
- Daily test runs on real Macs before launch, reviewed with `metrics.csv` and the logs: animation frames, hangs, delivery times on both sides, CloudKit request times, pings.
- Real users' diagnostics are **not readable by other installs**; they're private, trimmed, or off at launch.

- [ ] A week of daily runs meets the launch bar (to be set; see Open Questions).

## States and Boundaries
- **First open, not paid or paired:** the licence gate; the notch isn't shown.
- **Activated buyer, not paired:** Milestone 1 onboarding and invite; a join request asks for approval.
- **Invite code expired:** the joiner is asked to get a new code; the buyer can make one any time.
- **Paired partner:** full notch, no licence prompts.
- **Offline / Dodo or our server unreachable:** keeps working on the last good check.
- **Key in use on another Mac:** the activation is refused with how to free it.
- **Revoked or refunded:** blocked screen with Get OurNotch and the support email.
- **Hidden:** no notch; the ♡ menu shows Show OurNotch; arrivals wait and play once on return; the partner sees "away".
- **Language:** the Mac's language unless overridden in Settings; persists.

## Product Decisions
- **One purchase per couple, owned by the buyer.** It fits the gift and keeps checkout to one step.
- **One-time, no trial.** "Trials don't work."
- **Launch at the lower prices, $4.50 / ₹200 / €3, with no strikethrough** (learner, after learning fake "was" prices break US, EU and Indian pricing rules). Higher prices and a real sale later.
- **Activation should feel invisible, with the key as a backup.** "Less" for the buyer; the key covers anything going wrong.
- **The invite is a surprise gift email** from the buyer's own Mail.
- **Option B: our own admin page on Dodo's API, no customer accounts.** Tracking and a kill switch in our own app at near-zero cost; customer logins and personal data would add hosting, email and upkeep. Customers use Dodo's portal.
- **Free tier of everything, or the lowest possible paid tier,** because there's no subscription revenue.
- **Revoked users are blocked, on both Macs of the pair**, with a way to buy again or write to us.
- **Hide lives in Settings and comes back from the ♡ menu;** arrivals wait and play once; the partner sees you're away.
- **Languages follow the Mac, with a Settings override.**
- **Pairing needs a yes from both sides, and codes expire after 24 hours.** No typing to get wrong; the buyer decides who joins; old codes in emails stop working.
- **One licence slot, the buyer's Mac; the partner uses none.** Harder to share with a second couple; moving Macs is Remove, then paste.
- **Offline forever is fine.** Licences never die because something is unreachable; checks run whenever the Mac is online.
- **No refunds**, except where the law requires.
- **Domain: ournotch.app.**
- **Changing partners is deferred.**
- **Dodo compliance pre-clearance skipped** (risk accepted; see `research-dodo.md`).

## What We're Building
Buying with regional launch prices through Dodo; the licence gate; two-sided pairing confirmation with 24-hour codes; invisible activation with a pasteable key as backup; Find my licence; Remove from this Mac; the surprise invite email; revoked/refunded blocking; Hide and pause with timed options and an "away" status; English, French and German with a Settings override; a UI/UX pass from the learner's walk-through; the landing page, thank-you page, privacy policy and terms; the owner-only admin page; signed, notarized, self-updating packaging on our own account; daily test runs to a launch bar; private diagnostics for real users.

## Deferred From Milestone 2
- **Changing partners and unpairing:** learner's call for now. Known gap: a couple who breaks up stays paired. It was a Milestone 1 "must fix before real users" item.
- **Customer accounts on our website** ("My Macs", automatic restore): Dodo's portal covers restore with one copy-paste. Add if that annoys people.
- **Stricter limits on moving a licence:** add if the admin page shows sharing.
- **More languages** after French and German.
- **Partner offline sign** (a subtle dot when your partner's Mac is offline): learner's idea, out of scope for now. It needs every Mac to keep saying "I'm here", which costs CloudKit requests.

## Possible Later Enhancements
- Raise to regular prices (e.g. $8 / ₹1,000 / €10), sell at them for real for about a month, then run a Valentine's sale with the old price struck through; more regional prices (UK, Canada, Australia).
- Product features from the roadmap: shared pet, chat, gallery, "what's happening in your partner's life."

## Non-Goals
- **A free trial:** paying first fits the gift.
- **Subscriptions.**
- **Stopping app cracking:** casual sharing is stopped; determined crackers aren't worth fighting at $4.50.
- **Mac App Store.**
- **Our own database or customer data** at launch.

## Open Questions
| Question | Needed before |
|---|---|
| Support email address? | Landing page |
| The ♡ menu icon: keep the outlined heart, or change it (a cute emoji, a logo)? | UI/UX pass |
| The learner's walk-through of what feels wrong on each screen today, plus the two-Mac edge cases. | UI/UX pass |
| Days, number grouping, Quit button, no-notch pill (from Milestone 1). | UI/UX pass |
| Who checks the French and German translations? | Languages |
| When your own Apple Developer account is ready. | Packaging |
| Hosting the Next.js app (landing + admin) free or cheapest, allowing commercial use. | `4-spec` |
| The launch bar: e.g. 7 days on 3 pairs, no hangs, 95 % of deliveries under 15 s? | Before launch |
