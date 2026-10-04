---
doc: spec
milestone: 2
status: approved
---

# OurNotch — Technical Spec (Milestone 2: Ready to Sell)

Builds on `spec.md` (Milestone 1). Everything there stays unless changed here. Implements `prd-m2.md`.

## How This Works, In Plain Language
Milestone 2 adds three pieces around the existing notch app:

1. **Dodo, the shop and the licence book.** Dodo sells OurNotch (prices per country, taxes, receipts) and keeps the list of licence keys: who bought, which key, which Mac switched it on. The Mac app talks to Dodo directly over the internet for three things: **activate** (switch this key on for this Mac), **validate** (is this key still good?), and **deactivate** (free this Mac's slot). Those three need no secret password, so the app can call them safely.
2. **ournotch.app, the shop window.** A Next.js website hosted free on **Cloudflare**. It shows the gift story and the visitor's price, sends buyers to Dodo's checkout, and after paying shows a thank-you page whose **Open OurNotch** button hands the key to the app. It also holds your private **admin page**, locked to your email by Cloudflare's free login gate, which reads sales and keys from Dodo and can revoke a key. The website has **no database of its own**: Dodo is the database.
3. **The licence inside the app.** The buyer's Mac stores the key in the **Keychain** (macOS's secure password store) and holds the key's **one slot**. It passes the key to the partner's Mac through the **existing encrypted pairing**, the same way notes travel. The partner's Mac never activates; it only asks Dodo "still valid?", which uses no slot. Both Macs check about once a day when online. If Dodo says "not valid" (revoked or refunded), both Macs block. If Dodo or the internet is unreachable, nothing changes: OurNotch keeps working on its last good answer.

Around those: pairing now needs **a yes from both sides** and codes expire after 24 hours; **Hide** removes the notch for a while; text moves into Apple's **String Catalog** so French and German are translations, not code changes; and the app ships **signed by Apple, notarized, and self-updating** (with Sparkle) from our own Apple account.

**Why this shape:** the only running costs are the ones that can't be avoided (Apple's $99/year account and the domain); everything else is a free tier. There is no server we must keep alive for OurNotch to work, so if the website goes down, couples don't notice.

## The Core Journey Through the System
PRD ref: `prd-m2.md > The Core Journey`.

1. **Visitor arrives** → Cloudflare serves ournotch.app and adds the visitor's country (`CF-IPCountry`) → the page shows ₹200 / €3 / $4.50, no strikethrough (`Website Pages`).
2. **Buy** → a link to Dodo's hosted checkout, `checkout.dodopayments.com/buy/<product>?redirect_url=https://ournotch.app/thanks`. Dodo picks the price from the buyer's country (Localized Pricing) and takes the payment.
3. **Thank-you page** → Dodo sends the buyer to `/thanks?license_key=…`. A 3-step guide: ① **Download** (the DMG) → ② **Open OurNotch** (`ournotch://activate?key=…`) → ③ **Invite your love**. The key sits underneath as a backup, and the page removes it from the browser's address bar. Dodo emails the receipt with the key.
4. **The app opens** → macOS hands `ournotch://activate` to OurNotch → `Licence Service` calls Dodo `activate` with this Mac's name → stores key + activation id in the Keychain → the gate gives way to onboarding.
   *Alternative:* first open → `Licence Gate` → **Get OurNotch** opens the same checkout in the browser → step 3 brings the buyer back. **I have a licence key** → paste → `activate`.
5. **Onboarding + invite** (Milestone 1 flow) → the buyer creates an invite; the Mail draft uses the surprise wording.
6. **Partner joins** → gate → **I have an invite code** → `Pairing Service` looks up the invite (refused if over 24 hours old) → "**Kshitij** invited you, is that right?" → yes → a join request is saved → the buyer's Mac shows "**Manya** wants to join, is this your love?" → yes → an approval record is saved → both Macs pair.
7. **Licence reaches the partner** → the buyer's outbox now carries the key (encrypted) → the partner's Mac stores it in its Keychain and validates it with Dodo (no slot used).
8. **First heart** → Milestone 1 loop.
9. **Daily** → each Mac validates when online, at most once a day. `valid: false` → `Licence Blocked` screen on both Macs. Network or Dodo error → keep the last answer.
10. **Revoke** → admin page → Dodo disables the key → the next check on each Mac blocks.

```
 Visitor ──▶ ournotch.app (Cloudflare) ──Buy──▶ Dodo checkout ──paid──▶ /thanks?license_key=…
                     │ admin page (Access-locked) ◀── Dodo API (secret key)        │ ournotch://activate
                     ▼                                                              ▼
              revoke / free slot ──▶ Dodo licence book ◀── activate / validate ── Buyer's Mac
                                                     ▲                               │ key, encrypted,
                                                     └────── validate (no slot) ── Partner's Mac ◀─ via CloudKit outbox
```

## Stack
- **Mac app:** unchanged (Swift, SwiftUI + AppKit, CloudKit, CryptoKit, macOS 14+, Xcode 27). New Apple frameworks only, plus one exception:
  - **Sparkle 2** (Swift Package) for auto-updates: the standard for Mac apps sold outside the App Store; Apple has no equivalent for them. Docs: https://sparkle-project.org/documentation/. The first third-party dependency; **learner agreed** (Milestone 1 was Apple-only).
  - **URLSession** for Dodo's licence calls (Dodo's Swift SDK is iOS-only and only opens checkout).
  - **String Catalog** (`Localizable.xcstrings`) for languages. Docs: https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
- **Website:** Next.js 16 (already in `website/`), on **Cloudflare Workers** via Cloudflare's recommended Next.js path (vinext). Learner chose Cloudflare: its free plan allows commercial sites (Vercel's free plan forbids taking payments: https://vercel.com/docs/limits/fair-use-guidelines). Tradeoff accepted: Next.js on Cloudflare needs an adapter and may need setup fixes. Docs: https://developers.cloudflare.com/workers/framework-guides/web-apps/nextjs/
- **Cloudflare Access** (free) locks `/admin` to the owner's email. Docs: https://developers.cloudflare.com/cloudflare-one/policies/access/
- **Cloudflare R2** (free tier) hosts the DMGs and Sparkle's update feed. Docs: https://developers.cloudflare.com/r2/
- **Dodo Payments**: checkout, Localized Pricing, licence keys, customer portal. Docs: https://docs.dodopayments.com/features/license-keys, https://docs.dodopayments.com/features/localized-pricing
- **Verify early in the build** (each one gets a check before the work that depends on it):
  1. `validate` with only the key (no activation id) returns `valid: true` for an activated key **and doesn't use a slot** (a second Mac's `activate` is still refused).
  2. Dodo's redirect really adds `license_key` to the thank-you URL, and test mode issues keys (one Dodo FAQ line says it doesn't).
  3. Which Dodo API lists a key's activations (for "free a slot"); fallback: raise the key's activation limit by one.
  4. Next.js 16 + route handlers deploy to Cloudflare Workers.
  5. CloudKit silent pings arrive in a Developer ID (Production) build.

## Where It Runs and How Someone Tries It
- **Mac app, development:** as Milestone 1 (Xcode, ⌘R). Licence calls go to Dodo's **test mode** (`https://test.dodopayments.com`) in Debug and Beta builds, and to live (`https://live.dodopayments.com`) in the sold build.
- **Three build kinds:**
  - **Debug:** Partner Simulator, 3 s checks, test-mode Dodo, diagnostics on.
  - **Beta** (new configuration: Release + `BETA` flag): for your test couples; diagnostics and metrics upload on; test-mode Dodo so testers pay with test cards.
  - **Release (sold):** live Dodo, **diagnostics off**, no simulator.
- **Website, local:** `npm --prefix website run dev` → http://localhost:3000 (already in `.claude/launch.json`). Dodo test-mode product and links in `.dev.vars`.
- **Website, live:** `npx wrangler deploy` from `website/` → ournotch.app on Cloudflare. Secrets (`DODO_API_KEY`) set with `wrangler secret put`.
- **Release a version:** `scripts/release.sh` → archive with Developer ID → notarize (`xcrun notarytool`) → staple → build DMG → sign the update for Sparkle → upload DMG + `appcast.xml` to R2 → the website's Download points at the newest DMG.
- **Try the whole journey:** in test mode, buy on `localhost:3000` with card 4242 4242 4242 4242 → thank-you page → Open OurNotch → activated → invite → a second Mac (or the Partner Simulator) joins → both approve → first heart.
- **Repo:** public until the hackathon ends, then **private** (learner); the sold app is built from the private repo.

## Look and Feel
Implements `prd-m2.md > Look and Feel`.
- New app screens (Licence Gate, Licence Blocked, join approval, Settings rows) use the v3 design tokens already in `Config.swift` (notch black, `notchPink`, cards `#1C1C1E`, SF Rounded) and the onboarding window's style.
- **Gift, not software:** the gate leads with "Get OurNotch", a heart, and the price; the key field is secondary ("I have a licence key"). The blocked screen is kind, not alarming.
- Copy stays short and soft ("is this your love?", "that didn't work ♡").
- **Fits in German:** labels in the notch use one line with `minimumScaleFactor` or `ViewThatFits` alternatives; checked with Xcode's double-length pseudo-language.
- **Website:** keeps the approved "pop" design the other agent ported (`website/drafts/7-pop.html` → Next.js): Bricolage Grotesque (display) + Inter Tight (body) via `next/font`, plain global CSS with section prefixes (`y-*` sections, `b-*` bento, `x-*` hero), Pip and Bun characters. New pages (thank-you, My licence, privacy, terms) reuse these styles and components. **Mobile first:** check every page at 375 px and 320 px with no horizontal scroll, and at 1280 px. **Easy to operate:** one clear action per step, big buttons, short warm copy.

## Components

### Licence Service
Activation, checks, and the licence state machine on each Mac.
- **Buyer:** `activate(key, name: "<user's name>'s <Mac model>")` → store key + activation id in the Keychain; state `active`.
- **Partner:** receives the key from the buyer's outbox → stores it → `validate(key)` (no activation id).
- **Checks:** on launch and then every 24 h while running, only when online. `valid: true` → keep `active`, save the time. `valid: false` (or 403/404 from Dodo) → `revoked`. Network error, timeout, or 5xx → no change (works offline forever, learner).
- **Remove from this Mac** (buyer only) → `deactivate` → clear the Keychain → back to the gate.
- **Errors at the gate:** 404 → "that key doesn't look right"; 422 → "this key is in use on another Mac: choose Remove from this Mac there, or write to us"; 403 → blocked screen.
- Calls Dodo's live or test base URL by build kind (`Config.Licence`).
PRD ref: `prd-m2.md > Activation`, `> Revoked or Refunded Licence`.

### Activation Link
- Registers the `ournotch` URL scheme (Info.plist `CFBundleURLTypes`). `AppDelegate.application(_:open:)` handles `ournotch://activate?key=…` → `Licence Service.activate`.
- If OurNotch is already active, the link is ignored. If it's paired as a partner, it's ignored too.
PRD ref: `prd-m2.md > Activation` (invisible when possible).

### Licence Gate
The first onboarding screen for anyone not activated or paired: **Get OurNotch — [price]** (opens checkout in the browser), **I have a licence key** (paste field), **I have an invite code** (the joining flow). The price label is the US price with a small "price shown at checkout"; the browser checkout shows the local price.
PRD ref: `prd-m2.md > Screens and Layout`, `> Activation`.

### Licence Blocked
A small window shown instead of the notch when the state is `revoked`: "Your licence is no longer active. Get a new one, or write to us at [support email] if you think this is a mistake." Buttons: Get OurNotch, Write to us (`mailto:`). It re-checks when opened, so a restored key unblocks.
PRD ref: `prd-m2.md > Revoked or Refunded Licence`.

### Partner Coverage
- The buyer's encrypted outbox gains `licenceKey`. The partner's Mac copies it into its Keychain on the next sync and validates it.
- Only the buyer's Mac (role `inviter` + active licence) can create invites; the gate never offers inviting to a partner.
PRD ref: `prd-m2.md > Activation`, `> Invite as a Surprise`.

### Pairing Confirmation
Changes to `Pairing Service` (`spec.md > Pairing Service`):
- **Expiry:** the joiner refuses an invite whose record is over 24 hours old (`creationDate`); the buyer's waiting screen offers a new code after 24 hours.
- **Joiner confirms:** after looking up the invite, the joiner sees "[Buyer] invited you, is that right?" before anything is saved.
- **Join request:** the joiner saves `join-<CODE>-<joinerId>` (field `code`, Queryable). Several requests per code are possible, so a wrong person can't use up the code.
- **Buyer approves:** the buyer's Mac queries joins for its code, shows "[Partner] wants to join, is this your love?". Yes → saves `approval-<CODE>` (created once, holding the approved `joinerId`) and pairs. No → saves `decline-<CODE>-<joinerId>` and keeps waiting.
- **Joiner waits:** checks every 3 s for `approval-<CODE>` (its own id → paired; another id → "that code was used") or its `decline` record ("that didn't work ♡ ask your love for a new code").
PRD ref: `prd-m2.md > Pairing With the Right Person`.

### Surprise Invite Email
The `mailto:` draft becomes: subject "I planned a surprise for you ♡", body "[Name] planned a surprise for you, sweetheart…" + download link `https://ournotch.app/download` + the code + "it expires in 24 hours". Localized with the rest of the app.
PRD ref: `prd-m2.md > Invite as a Surprise`.

### Hide and Pause
- **Settings → Hide OurNotch** with three choices: 1 hour, until tomorrow (next 6 am local), until I bring it back. Stores `hiddenUntil` (a date, or "forever") in UserDefaults; survives restarts.
- Hidden → the notch panel is ordered out; the ♡ menu shows **Show OurNotch**; a timer brings it back at `hiddenUntil`.
- Syncing continues while hidden. Arriving emojis and notes are **held**: `EmojiEffect` keeps the newest pending effect instead of playing, and the banner waits. On show, the held effect plays **once** and the banner scrolls.
- My outbox gains `awayUntil`; the partner's closed notch shows "away" in the mood slot until that time passes or I show again.
- Keyboard shortcut: **not built** until the learner confirms (the PRD marks it proposed). It would use the Carbon hot-key API, which needs no extra permission.
PRD ref: `prd-m2.md > Hide and Pause`.

### Languages
- All user-facing text moves into `Localizable.xcstrings` (SwiftUI string literals are picked up automatically; strings built in code use `String(localized:)`). Languages: English (source), French, German.
- Follows the Mac's language by default. **Settings → Language** (System / English / Français / Deutsch) writes the `AppleLanguages` preference for OurNotch only and restarts it; the Settings row says "OurNotch will restart" (learner).
- Mood labels, error messages, the invite email, and the blocked screen are included; logs stay English.
PRD ref: `prd-m2.md > Languages`.

### Settings Additions
In-notch Settings gains rows for Hide OurNotch, Language, and (buyer only) **Licence**: status, Find my licence (opens Dodo's customer portal), Remove from this Mac.
PRD ref: `prd-m2.md > Screens and Layout`.

### Diagnostics by Build
`Config.Diagnostics.uploads` becomes `true` only in Debug and Beta builds. The sold Release build records its local log but uploads nothing (logs and metrics stay on the Mac).
PRD ref: `prd-m2.md > Performance and Monitoring`.

### Packaging and Updates
- **Own Apple Developer account:** new bundle ID `app.ournotch.OurNotch`, new container `iCloud.app.ournotch.OurNotch`, Developer ID Application certificate, Hardened Runtime. `Config.Cloud.containerId` + entitlements updated.
- **CloudKit Production:** deploy the schema (Outbox and Metric `ownerId`, Join `code` Queryable) from the Console before the first sold build.
- **Notarization + DMG + Sparkle** via `scripts/release.sh`; Sparkle checks `https://downloads.ournotch.app/appcast.xml` daily and offers updates ("a new version is ready ♡"), installing on approval.
PRD ref: `prd-m2.md > Packaging and Updates`.

### Website Pages
In `website/`. The landing page already exists (other agent): sections and copy in `app/page.tsx`, with `PRICE` (`'$7.98'`) and `CHECKOUT` (`'#'`) constants at the top; components `HeroDemo`, `Bento`, `MadeForTwo`, `Char`, `Notch`. Changes and new routes:
- `/` landing: `PRICE` becomes the visitor's regional price from `CF-IPCountry` (`lib/prices.ts`: IN → ₹200, euro countries → €3, else $4.50); `CHECKOUT` becomes the static Dodo checkout link; add Download.
- `/thanks`: the post-checkout guide. Reads `license_key`; three numbered steps, one big button each: ① Download OurNotch → ② Open OurNotch (`ournotch://activate?key=…`) → ③ Invite your love (what the surprise email is, and that the code lasts 24 hours). The key is shown underneath with a Copy button, "also in your receipt email". Clears the key from the address bar.
- `/licence` ("My licence"): find your key (receipt email, or **Find my licence** → Dodo's customer portal), move to a new Mac (Remove from this Mac on the old one, paste the key on the new one), lost Mac or other problems → write to us.
- `/download`: redirects to the newest DMG on R2.
- `/privacy`, `/terms`: what's stored, diagnostics in beta only, revocation for abuse, no refunds except where the law requires, contact email.
- **Honesty rules from the website handoff, updated:** price is **$4.50 / ₹200 / €3** one time (was $7.98); one licence covers both Macs; **no fake discounts, strikethroughs, countdowns or testimonials**; messages arrive "within seconds"; macOS 14+ and iCloud on both Macs; ❤️ is one of the emoji, not a separate hearts feature. "No tracking" may be claimed for the **sold** build only once diagnostics are off there; until then, don't.
- `/fr`, `/de`: French and German versions of every page.
PRD ref: `prd-m2.md > The Landing Page`, `> Buying and Prices`.

### Admin Page
`/admin` in the same Next.js app, **behind Cloudflare Access** (owner's email only). Server-side route handlers call Dodo's API with the secret key (never sent to the browser):
- Sales: list payments (date, country, amount, refund status).
- Keys: status and activations per key.
- Actions: revoke / restore a key; free a lost Mac's slot (deactivate its activation, or raise the limit by one; see verify item 3).
PRD ref: `prd-m2.md > Admin Page`.

## Data Model

### Dodo (the licence book)
- **One product:** "OurNotch", one-time, base price **USD 4.50**, Localized Pricing rules **IN → ₹200**, **EUR → €3**; licence key entitlement with **activation limit 1** (the buyer's Mac; the partner never activates) and **no expiry**.
- **Per purchase:** customer (email, country), payment, licence key, and an activation named after the buyer's Mac.

### CloudKit public database (changes)
| Record | Name | Fields | Written by |
|---|---|---|---|
| `Invite` | `invite-<CODE>` | unchanged; `creationDate` (system) used for the 24 h expiry | buyer |
| `Join` | `join-<CODE>-<joinerId>` | `code` (**Queryable**), `joinerId`, `joinerName`, `joinerKey` | joiner |
| `Approval` | `approval-<CODE>` | `joinerId` | buyer, once |
| `Decline` | `decline-<CODE>-<joinerId>` | — | buyer |

**Encrypted outbox additions:** `licenceKey` (buyer only), `awayUntil` (date, while hidden).

### On this Mac
- **Keychain:** licence key, activation id (buyer only), licence state + last good check time.
- **UserDefaults:** `hiddenUntil`, `AppleLanguages` (only when overridden), declined join ids.
- **Leave and come back:** licence state survives restarts; a hidden notch stays hidden until `hiddenUntil`; held arrivals play on show.

### Free-tier check
- **Cloudflare:** Workers free plan (100,000 requests/day) covers the landing page and admin page at launch scale; R2's free tier (10 GB, no download fees) covers DMGs.
- **Dodo:** no fixed cost; per-sale fee only.
- **CloudKit:** one extra validate call per Mac per day goes to Dodo, not CloudKit. Pairing records add a few per couple.

## File Structure
```
OurNotch/
├── OurNotch/
│   ├── OurNotchApp.swift          # + URL scheme handling, Show/Hide in ♡ menu, gate/blocked routing
│   ├── Config.swift               # + Config.Licence (Dodo URLs, product link), Beta flag for diagnostics
│   ├── Localizable.xcstrings      # NEW: English, French, German
│   ├── Licence/                   # NEW
│   │   ├── LicenceService.swift   # Licence Service (activate/validate/deactivate, state, Keychain)
│   │   ├── LicenceGateView.swift  # Licence Gate
│   │   └── LicenceBlockedView.swift # Licence Blocked
│   ├── Model/
│   │   ├── AppState.swift         # + licence key in outbox, awayUntil, held arrivals
│   │   ├── Outbox.swift           # + licenceKey, awayUntil
│   │   └── HideState.swift        # NEW: Hide and Pause timing
│   ├── Notch/                     # + Settings rows (Hide, Language, Licence); "away" in closed notch
│   ├── Onboarding/OnboardingView.swift # + gate first, joiner confirm, buyer approval, surprise email
│   └── Sync/
│       ├── PairingService.swift   # + expiry, join requests, approve/decline
│       └── CloudStore.swift       # + Join query, Approval/Decline records
├── OurNotchTests/                 # + licence state rules, pairing approval, expiry, hide timing
├── scripts/release.sh             # NEW: archive, notarize, DMG, Sparkle sign, upload to R2
├── website/
│   ├── app/
│   │   ├── page.tsx               # landing (other agent)
│   │   ├── thanks/page.tsx        # NEW: 3-step post-checkout guide
│   │   ├── licence/page.tsx       # NEW: My licence help
│   │   ├── download/route.ts      # NEW: redirect to newest DMG
│   │   ├── privacy/page.tsx, terms/page.tsx  # NEW
│   │   ├── [locale]/…             # NEW: fr, de versions
│   │   └── admin/                 # NEW: page + route handlers (Dodo API), behind Cloudflare Access
│   ├── lib/
│   │   ├── dodo.ts                # NEW: server-only Dodo API helper
│   │   └── prices.ts              # NEW: country → price
│   └── wrangler.jsonc             # NEW: Cloudflare config (secrets set separately)
└── devpost/
```

## External Services and Dependencies

### Dodo Payments
- **Public (from the Mac app, no key):** base `https://live.dodopayments.com` or `https://test.dodopayments.com`.
  - `POST /licenses/activate` `{license_key, name}` → 201 `{id: "lki_…", …}`; 404 not found, 422 limit reached, 403 inactive.
  - `POST /licenses/validate` `{license_key, license_key_instance_id?}` → `{valid}`.
  - `POST /licenses/deactivate` `{license_key, license_key_instance_id}`.
- **Server only (admin page, `DODO_API_KEY` as a Cloudflare secret):** list payments; licence keys / customer entitlement grants (`GET /customers/{id}/entitlement_grants`); update or revoke a key (`PATCH /license_keys/{id}`, or revoke the grant); customer portal link.
- **Checkout:** static link `https://checkout.dodopayments.com/buy/<product_id>?redirect_url=https://ournotch.app/thanks`.
- **Cost:** 4 % + 40¢ per sale (+1.5 % international cards); India 4 % + 15¢. Payouts in USD/EUR/GBP.
- Docs: https://docs.dodopayments.com/features/license-keys, https://docs.dodopayments.com/developer-resources/integration-guide, https://docs.dodopayments.com/features/customer-portal. Notes: `research-dodo.md`.

### Cloudflare
Workers (website + admin route handlers, free plan), Access (admin lock, free), R2 (DMGs + appcast, free tier), DNS for ournotch.app. Docs linked under Stack.

### Apple
Developer Program ($99/year, learner's own account), Developer ID signing, notarization (`notarytool`), CloudKit Production. Docs: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution

### Sparkle
Update framework + `appcast.xml` feed, signed with an EdDSA key kept off the repo. Docs: https://sparkle-project.org/documentation/

## Important Failure Modes
- **Dodo or the internet unreachable** → OurNotch keeps working on its last good check; activation shows "can't reach the shop right now, try again" and the paste field stays.
- **Open OurNotch link doesn't arrive** (no `license_key`, app not installed) → the thank-you page and the receipt email both show the key; paste works.
- **Key in use on another Mac** → the gate explains Remove from this Mac / write to us; the admin page can free the slot.
- **Cloudflare adapter breaks a page** → the app is unaffected (no licence call goes through our site); fix and redeploy.
- **Notarization or Sparkle signing fails** → `release.sh` stops before upload, so no broken update reaches anyone.

## What Was Simplified and Why
- **Dodo as the database** instead of our own accounts and database (learner, option B): tracking and the kill switch with no data of ours to protect. Fuller version: customer accounts with "My Macs" and automatic restore.
- **One message for revoked and refunded** instead of two wordings: Dodo's validate answers only "valid or not", so the app can't tell them apart. Fuller version: the admin page or a webhook marks refunds so the app could word it differently.
- **Price label in the gate shows the US price with "price shown at checkout"** instead of the local price: the Mac app doesn't know the buyer's country without asking a server. Fuller version: a tiny price endpoint on ournotch.app.
- **Language override restarts the app** instead of switching live (learner): macOS picks an app's language at launch.
- **No keyboard shortcut for Hide** until confirmed.
- **Daily licence checks** instead of constant ones: revocation takes effect within a day, which is enough for abuse.

## Decisions and Open Issues

### Decisions
- **Learner:** host ournotch.app on Cloudflare (free plan allows commercial use; adapter setup accepted).
- **Learner:** the partner's Mac validates the buyer's key itself, received through the encrypted pairing, so revocation blocks both Macs even when the buyer's Mac is off.
- **Learner:** GitHub repo stays public until the hackathon ends, then goes private.
- **Learner:** Settings language change restarts OurNotch, with a note on the screen.
- **Learner:** diagnostics upload only in Beta builds; off in the sold build.
- **Carried from the PRD (learner):** Dodo-only data (option B), one activation slot, offline forever, both-sides pairing approval, 24 h codes, no refunds, ournotch.app.
- **Derived here (agent):** daily checks; `ournotch://` activation link; join/approval/decline records; held arrivals while hidden; Beta build configuration; bundle and container names; R2 for downloads.
- **Learner:** **Sparkle** for auto-updates (first third-party dependency).
- **Learner:** launch at $4.50 / ₹200 / €3 with no struck-through prices; a real sale comes later.
- **Learner:** the post-checkout journey is spelled out as pages: the 3-step thank-you guide and the My licence help page. No customer accounts.

### The learner's question: "Then what's the difference between the owner and the partner?"
Clarified in conversation: the buyer holds the key's only slot, sees the key, can invite and has licence settings; the partner's Mac holds the key hidden in its Keychain and only validates it, which uses no slot. A partner extracting the key still can't activate a second Mac, because the buyer holds the slot. **Checked in the build** by verify item 1: after the partner validates, a second `activate` on another Mac is still refused with 422.

### Open issues
- **Verify early:** the five items under Stack.
- **From the PRD, not blocking the licence work:** support email (needed for the blocked screen and terms); the ♡ menu icon; the learner's screen walk-through (blocks the UI pass); Days, number grouping, Quit button, no-notch pill; who checks translations; when the Apple Developer account is ready (blocks packaging and the new container); the launch bar.
