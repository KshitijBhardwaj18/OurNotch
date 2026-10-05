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

- [x] **6. Hide OurNotch for a while**
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

- [x] **8. OurNotch speaks French and German**
  Becomes usable: On a Mac set to French, every screen is in French; Settings → *Language* (System / English / Français / Deutsch) switches OurNotch alone and restarts it. Nothing clips or wraps in German.
  Why now: After the UI/UX pass so translations cover final text.
  PRD ref: `prd-m2.md > Languages`
  Spec ref: `spec-m2.md > Components` (Languages, Settings Additions), `spec-m2.md > Look and Feel` (Fits in German)
  Build: `Localizable.xcstrings` with every user-facing string (`String(localized:)` for strings built in code; mood labels, errors, invite email, blocked screen), French and German translations (draft by the agent; native-speaker check is the learner's), Settings Language row writing `AppleLanguages` and relaunching, `minimumScaleFactor` / `ViewThatFits` where German is long.
  Verify (mechanical): Build succeeds with no untranslated strings reported; launch with `-AppleLanguages (fr)` and `(de)` and with the double-length pseudo-language and capture every screen; no clipped text.
  Learner check: Choose Deutsch in Settings, let OurNotch restart, and look through every tab. Then switch back.
  Commit: `Add French and German`

- [x] **9. Ready to release: Beta and sold builds, updates, and the release script**
  Becomes usable: Three build kinds — *Debug* (simulator), *Beta* (for test couples: diagnostics upload, Dodo test mode) and *Release* (the sold build: logs and metrics stay on the Mac). Sparkle is built in with a *Check for Updates…* item and separate Beta and Release feeds, switched on once the release key exists. `scripts/release.sh` archives, exports with Developer ID, makes the DMG, notarizes, writes the appcast and uploads to R2 — and until your account exists it stops after a local DMG.
  Why now: Everything about shipping that doesn't need your Apple account, done while you're away; the account steps are slice 11. Sparkle is the agreed first third-party dependency.
  PRD ref: `prd-m2.md > Packaging and Updates`, `prd-m2.md > Performance and Monitoring` (private diagnostics)
  Spec ref: `spec-m2.md > Components` (Packaging and Updates, Diagnostics by Build), `spec-m2.md > Where It Runs and How Someone Tries It` (three build kinds, release), `spec-m2.md > External Services and Dependencies` (Sparkle, Cloudflare R2)
  Build: Beta configuration (`BETA` flag), `Config.Diagnostics.uploads` by build, Sparkle 2 via Swift Package with per-configuration `SUFeedURL` / `SUPublicEDKey` build settings, *Check for Updates…* in the ♡ menu, `scripts/release.sh` + `scripts/ExportOptions.plist`, README release notes.
  Verify (mechanical): Debug, Beta and Release all build; each app's Info.plist carries its feed and Sparkle is embedded; only Beta has the `BETA` flag (so only Debug and Beta upload); `scripts/release.sh Beta` produces a DMG that mounts with the app and an Applications link and passes `codesign --verify`; tests pass.
  Learner check: Run `scripts/release.sh Beta`, open the DMG from `build/release/Beta/`, and drag OurNotch to Applications. Give testers Beta builds from now on.
  Commit: `Add Beta builds, Sparkle updates, and the release script`

- [x] **10. The website is complete: help, legal, French and German, locked admin**
  Becomes usable: On `localhost:3000`: the *My licence* help page, privacy policy and terms (revocation, no refunds except where the law requires), French and German versions of every page, `/download` pointing at the newest DMG, and `/admin` ready for Cloudflare Access (it verifies Access's signed token). The site builds for Cloudflare Workers and runs in Wrangler's local preview.
  Why now: All the website work that doesn't need the domain or a Cloudflare account; going live is slice 12.
  PRD ref: `prd-m2.md > The Landing Page`, `prd-m2.md > Admin Page`
  Spec ref: `spec-m2.md > Components` (Website Pages, Admin Page), `spec-m2.md > Stack` (Cloudflare, verify item 4), `spec-m2.md > Look and Feel` (Website)
  Build: `/licence`, `/privacy`, `/terms`, `/fr` and `/de` versions, `/download` → R2, Access JWT check in `lib/admin.ts`, `wrangler.jsonc` and the Cloudflare build adapter.
  Verify (mechanical): `npm run build` and the Cloudflare build succeed; Wrangler's local preview serves `/`, `/thanks`, `/licence`, `/privacy`, `/terms`, `/fr`, `/de`; `/admin` refuses a request without a valid Access token; pages pass 320 / 375 / 1280 px with no horizontal scroll.
  Learner check: Read the help, privacy and terms pages as a buyer would, and the French and German home pages.
  Commit: `Add help, legal, French and German pages and prepare the Cloudflare build`

- [ ] **11. Signed, notarized, and on your own Apple account**
  Becomes usable: A DMG from `scripts/release.sh` opens on a Mac that never ran OurNotch with no Gatekeeper warning, on your own Apple account and a new iCloud container. Publishing a newer version makes an installed copy offer "a new version is ready" and install it.
  Why now: Needs your own Apple Developer account, which comes last.
  PRD ref: `prd-m2.md > Packaging and Updates`
  Spec ref: `spec-m2.md > Components` (Packaging and Updates), `spec-m2.md > External Services and Dependencies` (Apple, Sparkle)
  Build: Bundle ID `app.ournotch.OurNotch`, container `iCloud.app.ournotch.OurNotch`, team and entitlements; Developer ID certificate and `notarytool` profile (learner); Sparkle `generate_keys` (learner backs up the key) and `SPARKLE_PUBLIC_KEY`; CloudKit schema deployed to Production with `Outbox.ownerId`, `Metric.ownerId` and `Join.code` Queryable; test couples pair again.
  Verify (mechanical): `release.sh` completes; `spctl -a -vv` and `xcrun stapler validate` pass on the DMG and app; an older build offers and installs the newer one from the appcast; the sold Release build uploads no diagnostics (log line); silent pings arrive in the Production build (verify item 5).
  Learner check: Download the DMG on your partner's Mac (or a fresh user account), open it — no warning — and pair again on the new container.
  Commit: `Ship signed, notarized DMG on our own account`

- [ ] **12. ournotch.app is live**
  Becomes usable: ournotch.app on Cloudflare with everything from slice 10, `/admin` locked to your email by Cloudflare Access, downloads served from R2. The whole journey runs from the live site in Dodo test mode; switching Dodo to live mode is the launch step.
  Why now: Last — it needs the domain, your Cloudflare account and slice 11's DMG; the app never depends on the site.
  PRD ref: `prd-m2.md > The Landing Page`, `prd-m2.md > Admin Page`, `prd-m2.md > The Core Journey`
  Spec ref: `spec-m2.md > Where It Runs and How Someone Tries It` (website, live), `spec-m2.md > External Services and Dependencies` (Cloudflare)
  Build: DNS for ournotch.app and downloads.ournotch.app (learner), R2 bucket `ournotch-downloads`, `wrangler deploy`, `DODO_API_KEY` as a Wrangler secret, the Access application and team domain for `/admin`.
  Verify (mechanical): Deploy succeeds; live pages load at 320 / 375 / 1280 px; `CF-IPCountry` picks the price; a signed-out browser is sent to Access's login for `/admin`; a test purchase on the live site ends on `/thanks` and *Open OurNotch* activates.
  Learner check: Open ournotch.app on your phone and laptop, read it as a stranger would, and buy once in test mode from the live site.
  Commit: `Deploy ournotch.app`

## Hands-on Checkpoints

- [ ] Early usable behavior explored — moved to just before slice 7 (see Revisions); originally after slice 3 (buy → activate → partner covered → revoke): feedback on the gate, thank-you page and blocked screen, **plus your screen-by-screen walk-through and the two-Mac edge cases** that drive slice 7
- [ ] Final kick-the-tires exploration and feedback completed — a stranger's journey on the live site to a heart in the partner's notch, then the week of daily test runs against the launch bar

## Final Review

- [x] ~~Learner action: `Join.code` Queryable index~~ — no longer needed: join requests use named slots (see Revisions).
- [x] **Admin page with real data:** learner added a test-mode key to `website/.env.local`; `/admin` lists the ₹200 sale from India and both test keys (active, 0 of 1 Macs) live from Dodo.
- [ ] **Review the privacy policy and terms** (`website/lib/i18n.ts > privacy, terms`): drafted by the agent from the PRD's decisions (no refunds except where the law requires, revocation for abuse, Dodo as seller of record, what's stored where); not legal advice — have them checked before selling.
- [ ] **Native-speaker check** of the French and German (`OurNotch/Localizable.xcstrings`; drafted by the agent with informal *tu* / *du*) before launch — who checks them is still an open question.
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
- `/admin` answers 404 in any production build until slice 10 checks Cloudflare Access and verifies Access's signed token; only the local dev server shows it.
- Slice 5 verified without the learner's secret key (it lives only in their Claude settings): the build succeeds, a production build returns 404 for `/admin`, no browser bundle mentions the key, and against a local stand-in serving Dodo's real response shapes the page listed the ₹200 sale from India and the key with its Mac, and Revoke → `PATCH {disabled:true}`, Restore → `{disabled:false}`, Free slot → `POST /licenses/deactivate`. The real-key run is a learner action in Final Review.
- Slice 6 verified by tests (hide timing incl. "until tomorrow" = next 6 am; two emojis and a note sent while hidden don't play, then play once together on show; the partner's notch shows "away" and clears; hidden survives a restart and ends if its time passed while closed) and by rendering the Settings row and the closed notch's "away". Showing and hiding the real notch window and the ♡ menu wasn't driven live (the learner was on a call); that's in the learner check.
- Held emojis are marked seen when they arrive, so the sender sees *Delivered* while their love is away; the "away" label tells them why nothing reacted yet. Holding the delivery back too would need a second "seen" counter.
- "away" is a small text label in the mood slot, re-checked each minute so it clears on time even without a new sync.
- Slice 8 built before slice 7 (order revised): slice 7 waits on the learner's walk-through, and the learner asked to build everything that doesn't need them. Text the polish pass adds or changes goes straight into the catalog with French and German, and `scripts/sync-strings.py --check` fails until it's translated.
- `xcodebuild` doesn't update the String Catalog (only building in the Xcode app does), so `scripts/sync-strings.py` merges the compiler's extracted strings into `Localizable.xcstrings` and lists missing translations. The Debug-only Partner Simulator stays English.
- Strings shown through plain `String` values (tab names, labels, errors, moods, "2m ago", the invite email) now use `String(localized:)`, and onboarding's `Screen` takes `LocalizedStringKey` — SwiftUI shows a `String` verbatim, so these would otherwise have stayed English.
- Fit verified by rendering every onboarding screen, the licence window, each notch tab, Settings and the closed header in German and French (`xcodebuild test -testLanguage`), instead of Xcode's double-length pseudo-language. Fixes found: German tab "Stimmung" → "Laune"; "Wochenenden" / "Week-ends" shrink to fit their tile; the Note tab's word counter wasn't localized; French "Envoyer un e-mail…" → "E-mail…"; German gate link shortened, and the gate's two links now stack in every language.
- French and German use the informal *tu* / *du* (a playful app for couples) and Apple's words for the notch ("encoche", "Notch"); moods are gender-neutral words ("Amour", "Joie", "Pas dispo") because French adjectives would need a gender.
- Settings → Language writes `AppleLanguages` for OurNotch only and relaunches it; the live relaunch wasn't driven (the learner was on a call) and is in the learner check.
- Slices 9 and 10 split into code now and accounts later (new slices 11 and 12), because the learner asked to finish all the coding first ("we can put things later"): slice 9 is the Beta / Release builds, private diagnostics, Sparkle wiring and the release script; slice 11 is everything that needs the learner's own Apple account (signing, notarization, the new container, Production, the Sparkle key); slice 10 is the rest of the website; slice 12 is going live on Cloudflare. What the learner gets is unchanged.
- Beta and Release use separate Sparkle feeds (`downloads.ournotch.app/beta/appcast.xml` and `/appcast.xml`), so test couples aren't "updated" onto a sold build that uploads no diagnostics.
- Sparkle stays off until `SPARKLE_PUBLIC_KEY` is set: its EdDSA key is generated in slice 11 with the learner present, because a lost key means existing users can never be updated again.
- Slice 9 verified: all three configurations build, feeds and the embedded Sparkle framework checked in each app, the `BETA` flag only in Beta, and `scripts/release.sh Beta` made a DMG that mounts with the app and an Applications link and passes `codesign --verify`. Notarization, upload and an end-to-end update need the account (slice 11).
- Slice 10: every word on the site moved into `website/lib/i18n.ts` (English, French, German); pages are shared components used by `app/(en)` (English at `/`) and `app/[lang]` (`/fr`, `/de`), two root layouts so each page has the right `<html lang>`. The landing page's demo, bento and "made for two" scene are translated too, including the scripted conversation. Checkout returns to the thank-you page in the buyer's language.
- Footer on every page: *My licence*, Privacy, Terms (the PRD asks for privacy and terms everywhere) and the language switch.
- `/admin` verifies Cloudflare Access's signed token itself (signature against the team's keys, audience, issuer, expiry, owner email) rather than trusting that Access is in front — a request through the workers.dev address or with a forged header gets a 404. Checked by `website/lib/admin.test.mjs` (9 cases) and in the built Worker (no token and a forged token → 404).
- Cloudflare build with `vinext` (Cloudflare's recommended path; `vinext check`: 100 % compatible), set up with no CDN cache, no KV data cache and no image optimization (free tier; the site has no `next/image`). Two fixes: the lockfile was regenerated because npm had left out rolldown's platform binary (`next` stays 16.3.8), and the Worker's compatibility date is 2026-09-28, the newest the local runtime supports. Verify item 4 confirmed locally: the built Worker serves every page in all three languages and `CF-IPCountry: IN` shows ₹200.
- `/download` points at `downloads.ournotch.app/OurNotch.dmg` (what `release.sh` uploads); `DOWNLOAD_URL` overrides it until R2 is live.
- Join requests moved from a query on `Join.code` (which needed a Queryable index added by hand in CloudKit Console) to five named slots per code (`join-<CODE>-0…4`) that the inviter reads by name — the learner couldn't find the field to index (CloudKit only creates it on first save), and reading by name needs no index in Development or Production. A joiner takes the first free slot; asking again reuses theirs; five strangers on one code would use it up (the inviter makes a New Code). Verified live through the real CloudKit container (Development): invite → a stranger and the partner both ask → the stranger is declined and told so → the partner is approved → both paired; this also created the `Join`, `Approval` and `Decline` record types.
- Slice 7 walk-through, item 1 (learner): the ♡ menu bar icon is a filled heart (`heart.fill`) instead of the outline — answers the PRD's open question about the menu icon.
- Slice 7 walk-through, item 2 (learner: "I clicked Activate, nothing happened"): the first activation request stalled until the 15 s timeout, with no sign of waiting, then showed "Can't reach the shop"; the retry took 0.1 s (Dodo saw one activation). Fixes: a spinner beside the footer buttons whenever onboarding or the licence window waits on the network; licence requests retry once when they get no answer (10 s each); each licence request's HTTP status or error is now logged.
