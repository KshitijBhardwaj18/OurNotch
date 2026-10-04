---
doc: checklist
milestone: 2
status: approved
---

# Build Checklist — Milestone 2: Ready to Sell

Build mode: fast (carried from Milestone 1; each slice as a stacked PR the learner merges later)

Milestone 1's checklist (`checklist.md`) stays as the record of Milestone 1. Its open final-review items (lag, two-Mac edge cases, Days / grouping / Quit / pill, the disappearing notch) are carried into this milestone by `scope-m2.md` and land in slice 7 (UI/UX pass) and the final review here.

## Slices

- [x] **1. Paste a licence key and OurNotch is yours**
  Becomes usable: First open shows the **licence gate**: *Get OurNotch*, *I have a licence key*, *I have an invite code*. Paste a key from a Dodo test purchase → OurNotch activates and continues into onboarding. A made-up key shows a kind error; a key already active on another Mac says how to free it; with Wi-Fi off an activated OurNotch still opens.
  Why now: The learner chose licensing first, and it holds the milestone's riskiest unknowns: whether Dodo's `validate` really uses no slot (the whole partner-coverage design rests on it) and whether test mode issues keys. Pasting a key needs no website, so it proves Dodo from the Mac before anything is built around it. Setting up the Dodo test product is folded in here.
  PRD ref: `prd-m2.md > Activation`, `prd-m2.md > Screens and Layout` (Licence gate), `prd-m2.md > States and Boundaries`
  Spec ref: `spec-m2.md > Components` (Licence Service, Licence Gate), `spec-m2.md > Data Model` (Dodo, On this Mac), `spec-m2.md > External Services and Dependencies` (Dodo Payments), `spec-m2.md > Stack` (verify items 1 and 2)
  Build: Create the Dodo **test-mode** product (USD 4.50, IN ₹200 / EUR €3 localized prices, licence keys with activation limit 1, no expiry); `Config.Licence` (test/live base URL, checkout link, support email placeholder); `LicenceService` (activate / validate / deactivate over URLSession, Keychain storage, state `none / active / revoked`, offline keeps last answer); `LicenceGateView` as the first onboarding step for anyone not activated or paired (invite-code path goes straight to joining); unit tests for the state rules (200 valid, 404, 422, 403, network error, 5xx).
  Verify (mechanical): State-rule tests pass; build succeeds. With a test key from a Dodo test purchase: `activate` from the app succeeds and the key lands in the Keychain; a second `activate` (simulated other Mac) returns 422; `validate` with only the key returns `valid: true` and the second `activate` is *still* 422 (verify item 1); a made-up key shows the error; drive a fresh install through the gate by pasting the key and capture screenshots.
  Learner check: Reset OurNotch and launch it. On the gate, try a made-up key and read the error, then paste the test key and watch it continue into onboarding. Turn Wi-Fi off, relaunch, and confirm it still opens.
  Commit: `Add licence gate and key activation through Dodo`

- [x] **2. Buy on the website and Open OurNotch activates it**
  Becomes usable: On `localhost:3000`, the price shows for your country (₹200 / €3 / $4.50, no strikethrough); *Buy* opens Dodo's test checkout; after paying with 4242 4242 4242 4242 you land on the **thank-you page** — ① Download → ② **Open OurNotch** → ③ Invite your love, key underneath with Copy. Clicking *Open OurNotch* activates the app with no key typed. *Get OurNotch* in the app's gate opens the same checkout.
  Why now: This is the milestone's "oh, that's cool" path — pay, click once, it's yours. It reuses slice 1's activation, so it adds only the website pages and the `ournotch://` link, and it checks whether Dodo really hands the key to the thank-you page (verify item 2) before anything else depends on it.
  PRD ref: `prd-m2.md > The Core Journey` (steps 1–4), `prd-m2.md > Buying and Prices`, `prd-m2.md > Activation`
  Spec ref: `spec-m2.md > The Core Journey Through the System` (steps 1–4), `spec-m2.md > Components` (Activation Link, Website Pages), `spec-m2.md > Look and Feel` (Website)
  Build: `website/lib/prices.ts` (country → price, with a dev override since localhost has no `CF-IPCountry`), `PRICE` / `CHECKOUT` wired on the landing page, `/thanks` page (3 steps, Copy, key cleared from the address bar), `ournotch` URL scheme + `application(_:open:)` → `LicenceService.activate` (ignored when already active or a partner), gate's *Get OurNotch* opens checkout.
  Verify (mechanical): `npm --prefix website run build` succeeds; the landing page shows ₹200 / €3 / $4.50 for IN / DE / US (checked via the override); a test-mode purchase through the browser pane ends on `/thanks?license_key=…` (or, if Dodo doesn't add it, a recorded revision); `open "ournotch://activate?key=…"` activates a fresh install; checked at 375 px and 1280 px with no horizontal scroll.
  Learner check: Run the website (`npm --prefix website run dev`), open http://localhost:3000, buy with the test card, then click *Open OurNotch* on the thank-you page and watch the app activate by itself. Say whether the thank-you page feels like opening a gift.
  Commit: `Add regional prices, thank-you page, and one-click activation`

- [x] **3. Your love is covered, and a revoked key blocks you both**
  Becomes usable: After pairing, the partner's Mac quietly receives the key and checks it (no licence step for them). Only the buyer can invite. Revoke the key in Dodo → both Macs show the kind **blocked** screen (Get OurNotch, Write to us) at their next check; restore → they come back. In-notch Settings shows **Licence** for the buyer: status, *Find my licence* (Dodo's portal), *Remove from this Mac* (frees the slot, back to the gate).
  Why now: Completes the licence model — one purchase per couple and the kill switch — on top of slices 1–2, before pairing changes in slice 4 so the coverage is tested on today's working pairing.
  PRD ref: `prd-m2.md > Activation` (one slot, Remove from this Mac, offline), `prd-m2.md > Revoked or Refunded Licence`, `prd-m2.md > Invite as a Surprise` (only buyers invite)
  Spec ref: `spec-m2.md > Components` (Partner Coverage, Licence Blocked, Settings Additions, Licence Service checks), `spec-m2.md > Data Model` (encrypted outbox additions)
  Build: `licenceKey` in the encrypted outbox (buyer only), partner stores + validates it; checks on launch and every 24 h when online; `LicenceBlockedView` replacing the notch on `revoked`, re-checks when opened; invites refused unless inviter + active; Settings Licence row; Partner Simulator acts as the partner for coverage.
  Verify (mechanical): Tests for coverage (key reaches the partner through the outbox), state transitions, and "partner can't invite" pass. Live with the simulator: revoke the test key via Dodo's API → the next check blocks both sides (screenshot); restore → unblocked; *Remove from this Mac* → `deactivate` succeeds and a fresh `activate` works again; Wi-Fi off after activation → still works.
  Learner check: Pair with the Partner Simulator, then I'll revoke your test key — watch the blocked screen appear, then come back when it's restored. Try *Find my licence* and *Remove from this Mac* in Settings.
  Commit: `Cover the partner with the buyer's licence and block revoked keys`

- [x] **4. Pairing needs a yes from both of you**
  Becomes usable: The partner enters the code → "**Kshitij** invited you, is that right?" → yes → the buyer's Mac asks "**Manya** wants to join, is this your love?" → only yes pairs. A no tells the joiner gently and keeps the code open for the right person. Codes expire after 24 hours. The invite email becomes the surprise: "Kshitij planned a surprise for you, sweetheart", with the download link, code and "expires in 24 hours".
  Why now: The "must fix before real users" safety item; it builds on the gate's invite-code path from slice 1 and the buyer-only invites from slice 3.
  PRD ref: `prd-m2.md > Pairing With the Right Person`, `prd-m2.md > Invite as a Surprise`
  Spec ref: `spec-m2.md > Components` (Pairing Confirmation, Surprise Invite Email), `spec-m2.md > Data Model` (CloudKit public database)
  Build: `PairingService` expiry from `creationDate`, `Join` records with Queryable `code`, `Approval` / `Decline` records, joiner confirm step, buyer approval prompt, joiner waiting states, surprise `mailto:` wording, simulator updated for both roles. The learner adds the `Join.code` Queryable index in CloudKit Console (Development).
  Verify (mechanical): Tests: expired code refused; two joiners on one code, buyer declines one and approves the other; approval with another id → "that code was used". Live with the simulator in both roles: confirm → approve pairs; decline → gentle message and the code still works; screenshots of both prompts and the email draft.
  Learner check: Invite from your notch and join from the simulator: say no once and watch the gentle message, then join again and say yes on both sides. Look at the surprise email draft.
  Commit: `Ask both partners to confirm before pairing and expire codes after 24 hours`

- [x] **5. Your admin page: sales, keys, and the kill switch**
  Becomes usable: `localhost:3000/admin` lists test sales (date, country, price, refunds) and licence keys (status, Macs in use), with *Revoke* / *Restore* and *Free a slot* buttons that change the key in Dodo. The secret key never reaches the browser.
  Why now: It's the owner's side of slices 1–3 (revoking and freeing slots), and checks which Dodo API lists a key's activations (verify item 3). Its lock (Cloudflare Access) comes with the deploy in slice 10.
  PRD ref: `prd-m2.md > Admin Page`, `prd-m2.md > Revoked or Refunded Licence`
  Spec ref: `spec-m2.md > Components` (Admin Page), `spec-m2.md > External Services and Dependencies` (Dodo, server only)
  Build: `website/lib/dodo.ts` (server-only, `DODO_API_KEY` from `.dev.vars` / env), `/admin` page + route handlers for list payments, list keys + activations, revoke / restore, free a slot (or raise the limit by one if Dodo can't list activations).
  Verify (mechanical): Build succeeds; `/admin` lists slice 2's test purchase with country, price and "1 Mac"; Revoke → the app's next check blocks; Restore → unblocks; Free a slot → a new `activate` succeeds; the page's HTML and JS bundles contain no secret key (grep).
  Learner check: Open http://localhost:3000/admin, find your test purchase, revoke its key and watch OurNotch block, then restore it.
  Commit: `Add owner admin page for sales, keys, and revoking`

- [ ] **6. Hide OurNotch for a while**
  Becomes usable: Settings → *Hide OurNotch* → for 1 hour / until tomorrow / until I bring it back. The notch disappears; ♡ menu → *Show OurNotch* brings it back early. Hearts and notes that arrive while hidden wait and play once on return. Your love's closed notch shows "away" where your mood sits.
  Why now: Independent of licensing and a requested feature; it lands before the UI/UX pass so the pass can polish it with everything else.
  PRD ref: `prd-m2.md > Hide and Pause`
  Spec ref: `spec-m2.md > Components` (Hide and Pause), `spec-m2.md > Data Model` (On this Mac, encrypted outbox additions)
  Build: `HideState` (`hiddenUntil`, next 6 am rule), panel ordered out / in, ♡ menu Show/Hide, held emoji effect + banner, `awayUntil` in the outbox and "away" in the partner's closed notch. No keyboard shortcut (not confirmed).
  Verify (mechanical): Tests for hide timing (1 h, next 6 am, forever, survives restart) and held arrivals (play once on show). Live: hide → notch window gone; simulator sends 3 emojis → nothing plays; show → one splash; simulator shows "away" and clears.
  Learner check: Hide for 1 hour, send a heart from the simulator, then bring OurNotch back from the ♡ menu and watch it play once. Check the simulator shows you as away.
  Commit: `Add hiding OurNotch for a while with arrivals held until you're back`

- [ ] **7. UI/UX pass from your walk-through**
  Becomes usable: The screens you walk through (onboarding, closed notch, Home, Note, Emoji, Mood, Photo, Settings, and the new gate / blocked / approval screens) change the way you asked; Milestone 1's open questions (Days, number grouping, Quit button, no-notch pill, ♡ menu icon) and the two-Mac edge cases are decided and fixed.
  Why now: It needs your walk-through, which happens at the early checkpoint after slice 3, and it must come before languages so the text is final when it's translated.
  PRD ref: `prd-m2.md > UI/UX Pass`, `prd-m2.md > Look and Feel`
  Spec ref: `spec-m2.md > Look and Feel`, `devpost/design_handoff/README.md`
  Build: The agreed list from the walk-through, recorded here under Revisions before building. Text written new in this slice goes straight into the String Catalog.
  Verify (mechanical): Build and tests pass; each agreed change captured in a before/after screenshot.
  Learner check: Walk the same screens again and say what still feels wrong.
  Commit: `Polish onboarding and notch from the walk-through`

- [ ] **8. OurNotch speaks French and German**
  Becomes usable: On a Mac set to French, every screen is in French; Settings → *Language* (System / English / Français / Deutsch) switches OurNotch alone and restarts it. Nothing clips or wraps in German.
  Why now: After the UI/UX pass so translations cover final text.
  PRD ref: `prd-m2.md > Languages`
  Spec ref: `spec-m2.md > Components` (Languages, Settings Additions), `spec-m2.md > Look and Feel` (Fits in German)
  Build: `Localizable.xcstrings` with every user-facing string (`String(localized:)` for strings built in code; mood labels, errors, invite email, blocked screen), French and German translations (draft by the agent; native-speaker check is the learner's), Settings Language row writing `AppleLanguages` and relaunching, `minimumScaleFactor` / `ViewThatFits` where German is long.
  Verify (mechanical): Build succeeds with no untranslated strings reported; launch with `-AppleLanguages (fr)` and `(de)` and with the double-length pseudo-language and capture every screen; no clipped text.
  Learner check: Choose Deutsch in Settings, let OurNotch restart, and look through every tab. Then switch back.
  Commit: `Add French and German`

- [ ] **9. Signed, notarized, and self-updating**
  Becomes usable: A DMG from `scripts/release.sh` opens on a Mac that never ran OurNotch with no Gatekeeper warning, on your own Apple account and a new iCloud container. Publishing a newer version makes an installed copy offer "a new version is ready ♡" and install it. Beta builds upload diagnostics; the sold Release build uploads nothing.
  Why now: Needs your own Apple Developer account (not ready yet); everything earlier works on the company account. Sparkle is the first third-party dependency (agreed).
  PRD ref: `prd-m2.md > Packaging and Updates`, `prd-m2.md > Performance and Monitoring` (private diagnostics)
  Spec ref: `spec-m2.md > Components` (Packaging and Updates, Diagnostics by Build), `spec-m2.md > Where It Runs and How Someone Tries It` (three build kinds, release), `spec-m2.md > External Services and Dependencies` (Apple, Sparkle, Cloudflare R2)
  Build: Bundle ID `app.ournotch.OurNotch` and container `iCloud.app.ournotch.OurNotch`, Beta configuration, `Config.Diagnostics.uploads` by build, Sparkle 2 via Swift Package + appcast, `scripts/release.sh` (archive → notarize → staple → DMG → Sparkle sign → upload to R2), CloudKit schema deployed to Production by the learner, `/download` redirect.
  Verify (mechanical): `release.sh` completes; `spctl -a -vv` and `xcrun stapler validate` pass on the DMG and app; an older build offers and installs the newer one from the appcast; a Release build makes no diagnostics upload (log line); silent pings arrive in the Production build (verify item 5).
  Learner check: Download the DMG on your partner's Mac (or a fresh user account), open it — no warning — and pair again on the new container.
  Commit: `Ship signed, notarized DMG with Sparkle updates`

- [ ] **10. ournotch.app is live**
  Becomes usable: ournotch.app on Cloudflare: landing with regional prices, Download, thank-you page, *My licence* help, privacy policy and terms (revocation, no refunds), French and German versions, and `/admin` locked to your email by Cloudflare Access. The whole journey runs from the live site in Dodo test mode; switching to live mode is the launch step.
  Why now: Last, because it needs the DMG (slice 9), final copy, and the domain; the app never depends on the site, so nothing earlier waits for it.
  PRD ref: `prd-m2.md > The Landing Page`, `prd-m2.md > Admin Page`, `prd-m2.md > The Core Journey`
  Spec ref: `spec-m2.md > Components` (Website Pages, Admin Page), `spec-m2.md > Stack` (Cloudflare, verify item 4), `spec-m2.md > Where It Runs and How Someone Tries It` (website, live)
  Build: `/licence`, `/privacy`, `/terms`, `/fr` and `/de`, `wrangler.jsonc` + Cloudflare Workers deploy (vinext path), `DODO_API_KEY` as a Wrangler secret, Access policy on `/admin`, DNS for ournotch.app (learner's account steps).
  Verify (mechanical): Deploy succeeds; live pages load at 320 / 375 / 1280 px with no horizontal scroll; `CF-IPCountry` picks the price; `/admin` redirects a signed-out browser to the Access login; a test purchase on the live site ends on `/thanks` and *Open OurNotch* activates.
  Learner check: Open ournotch.app on your phone and laptop, read it as a stranger would, and buy once in test mode from the live site.
  Commit: `Deploy ournotch.app with legal, help, and admin pages`

## Hands-on Checkpoints

- [ ] Early usable behavior explored — moved to just before slice 7 (see Revisions); originally after slice 3 (buy → activate → partner covered → revoke): feedback on the gate, thank-you page and blocked screen, **plus your screen-by-screen walk-through and the two-Mac edge cases** that drive slice 7
- [ ] Final kick-the-tires exploration and feedback completed — a stranger's journey on the live site to a heart in the partner's notch, then the week of daily test runs against the launch bar

## Final Review

- [ ] **Learner action before pairing through CloudKit:** in CloudKit Console (Development), add a **Queryable** index on `Join.code` — without it the buyer's Mac can't see join requests. (Production gets it in slice 9.)
- [ ] **Learner action, admin page with real data:** put your Dodo **test-mode** API key in `website/.env.local` as `DODO_API_KEY=…` (ignored by git), restart the dev server, open http://localhost:3000/admin, and confirm the ₹200 test purchase and its key show. Revoke / Restore / Free slot were verified against a stand-in with Dodo's real response shapes, not yet against Dodo with your key.
- [ ] Final review complete — feedback resolved and learner confirms ready to ship

## Code Tour and App Map

- [ ] Learning activity complete — guided route, focused alternative, prior practice connected, or brief recap
- [ ] Optional edit and transfer reflection addressed — offered/declined/already covered/not applicable as appropriate
- [ ] `devpost/app-map.html` generated from finished code, checked, and shown, including a project-grounded practice to reuse

Activity and evidence: 
Route and stops: 
Edit outcome: 
Reflection: 
Activity mode: 

## Revisions
- Dodo test-mode product created before slice 1 (learner asked): `pdt_0Np1n3lC4hykWhTwMaNVV`, one-time USD 4.50, `by_currency` fixed prices INR 200 and EUR 3, **tax-inclusive** so the shown price is what people pay, licence key with 1 activation and no expiry. Verify item 3 answered from Dodo's API docs: `GET /license_key_instances?license_key_id=…` lists a key's activations, so "free a slot" can remove the lost Mac's activation instead of raising the limit.
- Verify item 1 confirmed live against Dodo test mode with a key made through the API: activate → 201; a second Mac → 422; `validate` with only the key → `valid: true`; the second Mac is *still* 422 afterwards, so the partner's check uses no slot. A made-up key → 404. Partner coverage stands as designed.
- Slice 1's live check ran through the real `OnboardingModel` against Dodo (made-up key → kind error, stays on the key step; the real key with stray spaces → activated, on to the name step, activation id stored; offline check keeps the licence), with the gate and key screens rendered to images, instead of clicking the onboarding window — the learner was on a full-screen call, so nothing was shown on their screen. The learner's hands-on check covers the real window.
- The activation is named after the Mac's computer name ("Kshitij's MacBook Pro") instead of "<name>'s <Mac model>" — the name step comes after the gate, and the computer name is usually exactly that.
- Debug builds accept `OURNOTCH_PROFILE=<name>` to run a separate fresh identity beside the real one — fresh-install checks no longer need *Reset Everything*, which would wipe the learner's real pairing with their partner.
- The gate's path decides joining: the "I Have a Code" link left the invite screen, since partners now choose *I Have an Invite Code* at the gate.
- Verify item 2 confirmed: a test purchase from `localhost:3000` (Dodo checkout detected India → ₹200.00 incl. GST; Dodo's published Indian test card and the gateway simulator) returned to `/thanks?…&license_key=<uuid>`, so test mode does issue keys and the redirect carries them. Dodo's keys are UUIDs, not short codes.
- The website (`website/`, built by the other agent from the approved pop design) is committed with this slice and owned by the build from here on (learner: "let's just build what we can").
- `/download` redirects to the GitHub releases page until slice 9 puts signed DMGs on R2. The app's *Get OurNotch* returns to `localhost:3000/thanks` in Debug and `ournotch.app/thanks` otherwise.
- The URL scheme lives in a small `OurNotch-Info.plist` at the repo root, merged into the generated Info.plist: build settings can't express `CFBundleURLTypes`, and a plist inside the synced `OurNotch/` folder would be copied as a resource.
- Clicking *Open OurNotch* into a fresh app wasn't driven live (the learner was on a call, and two installed copies share the `ournotch://` scheme); the purchased key was activated through the same `OnboardingModel.activate(key:)` the link calls, and the built app's Info.plist was checked for the scheme. The learner's check covers the real click.
- Slice 3 verified live against Dodo test mode with the purchased key, through the real `LicenceService`, `AppState` sync and `LicenceBlockedModel`: the partner received the key through the encrypted outbox (no slot used; a second Mac still refused); disabling the key in Dodo → both Macs `revoked`; re-enabling → *Check Again* unblocked; *Remove from This Mac* → `removed`, and a new Mac then activated. Disabled keys answer `validate` with `{valid:false}` and `activate` with 403, as the state rules assumed.
- *Remove from This Mac* locks this Mac behind the licence window (paste a key to use it here again) rather than returning to the onboarding gate — the Mac is still paired, and onboarding would start a new invite. The lock window serves both revoked and removed, with a key field, Get OurNotch and Write to Us; it can't be closed (quit from the ♡ menu).
- Licence status is `active / revoked / removed` instead of a revoked flag, so a removed key isn't mistaken for a revoked one and daily checks skip it.
- Locking applies only when this Mac has a licence that's revoked or removed; Macs paired in Milestone 1 have no licence and keep working (they re-pair on the new container in slice 9).
- In-notch Settings now scrolls: with the Licence row it is 241 pt tall in a 200 pt area, and Hide and Language rows are still to come.
- The early checkpoint moved from after slice 3 to just before slice 7: the learner asked to keep building through the coding first ("let's just build what we can"), and slice 7 is where their walk-through is needed. Slices 4–6 don't depend on it.
- Slice 4 verified with unit tests on the local mailbox (both sides say yes before pairing; a declined stranger doesn't use up the code and is told gently; a late joiner after approval gets "already used"; expired and made-up codes refused) and by driving the real onboarding models end to end (invite → partner confirms "Kshitij invited you" → asks → buyer sees "Manya wants to join" → yes → both paired), with each screen rendered. Not yet run through CloudKit: it needs the `Join.code` Queryable index the learner adds in CloudKit Console.
- Declined joiners are remembered in memory for the current code, not in UserDefaults — an invite code doesn't survive relaunching onboarding anyway (a fresh code is made), so there is nothing to restore.
- The invite screen gained *New Code* (any time, e.g. after 24 hours or a wrong person) instead of a timer that offers one after 24 hours.
- A joiner who is declined, or whose code was used or expired, goes back to typing a code, so they can't keep re-asking with the same one.
- Verify item 3 settled: `GET /license_key_instances?license_key_id=…` lists a key's Macs, and *Free slot* frees one through Dodo's public `deactivate` call (no secret needed).
- The payment list has no country, so the admin page reads each sale once more for `billing.country` (one request per sale, latest 50; marked `ponytail:`).
- Admin actions are Next.js server actions rather than route handlers — the same server-only boundary with less code; each action re-checks access, since server actions can be POSTed directly.
- `/admin` answers 404 in any production build until slice 10 puts it behind Cloudflare Access and verifies Access's signed token; only the local dev server shows it.
- Slice 5 verified without the learner's secret key (it lives only in their Claude settings): the build succeeds, a production build returns 404 for `/admin`, no browser bundle mentions the key, and against a local stand-in serving Dodo's real response shapes the page listed the ₹200 sale from India and the key with its Mac, and Revoke → `PATCH {disabled:true}`, Restore → `{disabled:false}`, Free slot → `POST /licenses/deactivate`. The real-key run is a learner action in Final Review.
