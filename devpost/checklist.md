---
doc: checklist
status: approved
---

# Build Checklist

Build mode: fast (learner chose 2026-10-02; each slice as a stacked PR the learner merges later)

Workflow (learner decision, `spec.md > Decisions and Open Issues`): each slice is its own branch and pull request, stacked bottom-up on the one below it and linked with `gh stack link --base main`. An initial commit on `main` (`.gitignore` + planning docs) gives the stack a base.

## Slices

- [x] **1. A cute notch lives on your screen**
  Becomes usable: Launch OurNotch and a black shape grows out of your real notch showing a days-together number and a ♡. Hover and it springs open to show the live counter (days down to seconds); move away and it closes. A ♡ in the menu bar has *Quit*. No Dock icon. The together-since date is a placeholder for now.
  Why now: The notch window is the first hard unknown and everything visible lands inside it. Building it first proves the overlay, positioning, hover, and look-and-feel before any data exists. Project scaffolding is folded in here.
  PRD ref: `prd.md > Screens and Layout`, `prd.md > Look and Feel`, `prd.md > Days Together`
  Spec ref: `spec.md > Components` (Notch Window, Notch Geometry, Closed Notch View, Open Notch View, Menu Bar Item), `spec.md > Look and Feel`, `spec.md > File Structure`, `devpost/boring-notch-notes.md`
  Build: Create `OurNotch.xcodeproj` (macOS 14 target, agent app with `LSUIElement`, Sign to Run Locally, unit test target), `Config.swift`, `NotchPanel`, `NotchGeometry` (notch screen, pill fallback), our own `NotchShape`, `NotchView` with debounced hover, `ClosedNotchView`, `OpenNotchView` layout skeleton (counter, heart button, message area placeholders), `MenuBarExtra` with Quit, days-together math with a unit test, and `README.md` with how to run.
  Verify (mechanical): `xcodebuild build` and `xcodebuild test` succeed; launch the built app, confirm the process runs with no Dock icon, and take a screenshot of the top of the screen showing the black notch shape with the days number and ♡.
  Learner check: Run OurNotch from Xcode (⌘R). Look at your notch: you should see a number and a ♡ beside it. Hover over it — it should spring open with a live counter ticking seconds. Move away and it closes. Click the ♡ in the menu bar → Quit.
  Commit: `Add notch window with closed and open states`

- [x] **2. Your love's hearts pour out of your notch**
  Becomes usable: Open the Partner Simulator (♡ menu → *Partner Simulator*, Debug only). Tap ❤ there → soft hearts float out of your notch. Tap ❤×3 → a full-screen splash of hearts. Quit OurNotch, send hearts from the simulator, relaunch → the missed hearts appear. Tap the ♡ in your open notch → the simulator receives it and your notch shows *sent ♡* then *delivered ♡*.
  Why now: This is the unique kernel — a heart from your partner arriving in your notch. It comes right after the notch exists so the most important behavior is proven early, including the missed-hearts math you asked about.
  PRD ref: `prd.md > Sending Hearts`, `prd.md > Missed Hearts`, `prd.md > States and Boundaries`
  Spec ref: `spec.md > Components` (Hearts Effect, App State, Partner Simulator), `spec.md > Data Model`, `spec.md > What Was Simplified and Why` (local file mailbox), `spec.md > Decisions and Open Issues` (missed hearts)
  Build: `Outbox` payload struct, the `Mailbox` interface with the local file version, `AppState` (heart counts, new = sent − shown, sent/delivered, 1-second tap bundling, persistence in UserDefaults), `HeartsEffect` pour + full-screen click-through splash window, the heart button wired in the open notch, and the Debug-only `PartnerSimulator` window with its own identity and storage. Both sides use a fixed dev pairing until slice 4.
  Verify (mechanical): Unit tests for the hearts math (12 sent, 9 shown → 3 → splash; 2 new → pour) and sent/delivered pass. Run the app, drive the simulator to send 1 heart, then 3, and capture screenshots of the pour and the splash; quit, write hearts to the mailbox, relaunch, and confirm the missed hearts are shown; send a heart from the notch and confirm the simulator's received count and the *delivered* status.
  Learner check: Open the Partner Simulator from the ♡ menu. Send 1 heart → watch hearts float out of your notch. Send 3 → the whole screen fills with hearts. Then hover your notch, tap ❤, and watch *sent ♡* turn into *delivered ♡* while the simulator counts it.
  Commit: `Add hearts between partners with pour and splash effects`

- [x] **3. A message scrolls across your notch**
  Becomes usable: In the open notch, type a short message, choose *3 times* or *until opened*, and send. From the simulator, send "hi babe how are you? love you" → it scrolls in a strip just below your notch, 3 times or until you open the notch. The open notch shows the last message received and *sent ♡ / delivered ♡* for yours. Too-long or empty messages can't be sent and show a gentle hint.
  Why now: The second half of the kernel. It reuses the outbox and status plumbing from slice 2, so it lands quickly and completes the full "oh, that's cool" loop on one Mac.
  PRD ref: `prd.md > Sending Messages`, `prd.md > States and Boundaries`
  Spec ref: `spec.md > Components` (Message Banner, Message Rules, Open Notch View, Notch Window — typing), `spec.md > Data Model`
  Build: `MessageRules` (10 words, 60 characters, 15 per word) with unit tests, the message field + mode toggle + send in the open notch (panel becomes key while typing, notch stays open), message id/text/mode in the outbox, `MessageBanner` marquee below the notch, `untilOpened` banner persisted across restarts, last message display, message sent/delivered, simulator message sending and receiving.
  Verify (mechanical): Message-rule unit tests pass (empty, 11 words, 61 characters, a 16-letter word rejected; the sample message accepted). Run the app, send a message from the simulator in each mode and capture the banner scrolling; confirm `three` hides after 3 passes and `untilOpened` survives a relaunch; send from the notch and confirm the simulator shows it and the status turns *delivered*.
  Learner check: Send "hi babe how are you? love you" from the simulator and watch it scroll under your notch. Try typing a long message in your notch and see the hint. Send one back and watch the simulator receive it.
  Commit: `Add scrolling message banner and message sending`

- [x] **4. Pair with your love, privately**
  Becomes usable: First launch shows a small onboarding window: welcome → your name → *Invite your love* (shows a 6-letter code, *Send email* opens Mail with a cute invite, "waiting for your love…") or *I have a code* (enter code → "nikki ❤ invited you", or a gentle error for a bad/used code) → together-since date (inviter only) → *Open at login* toggle → done. The simulator joins using your code. From then on, outboxes are encrypted with a key only the two of you share, and days-together uses your real date.
  Why now: Pairing and encryption replace the fixed dev pairing once the kernel works. They come before CloudKit so the full journey — and the privacy promise — is proven locally first; CloudKit then only swaps how rows travel.
  PRD ref: `prd.md > The Core Journey` (steps 1-6), `prd.md > Onboarding and Sign In`, `prd.md > Pairing`, `prd.md > States and Boundaries` (Privacy)
  Spec ref: `spec.md > Components` (Onboarding, Pairing Service, Crypto), `spec.md > Data Model`, `spec.md > External Services and Dependencies` (Mail)
  Build: `Crypto` (Curve25519 key in Keychain, X25519 → HKDF-SHA256 → ChaChaPoly) with a round-trip unit test, `PairingService` over the `Mailbox` (invite/join records, unambiguous code alphabet, used-code detection, 3-second wait checks), `OnboardingView` steps with activation-policy swap for typing, `mailto:` invite, `SMAppService` open-at-login toggle, together-since flowing through the inviter's encrypted outbox, simulator join-by-code, removal of the fixed dev pairing.
  Verify (mechanical): Crypto round-trip and wrong-key-fails tests pass; code generator avoids 0/O/1/I. Run a fresh install, invite, join from the simulator, and confirm both sides pair; inspect the local mailbox file and confirm payloads are unreadable bytes; confirm a used code and a made-up code each show the error; confirm hearts and messages still flow after pairing.
  Learner check: Reset and launch OurNotch fresh. Go through onboarding, tap *Invite your love*, press *Send email* (just look at the draft), then join from the Partner Simulator with your code. Check that "… ❤ invited you" appears, your days-together number matches your date, and hearts still arrive.
  Commit: `Add onboarding, invite-code pairing, and end-to-end encryption`

- [x] **5. The new notch: tabs, notes, and emojis**
  Becomes usable: The notch follows the v3 design (`devpost/design_handoff/README.md`, used as the visual design; our own logic). Closed: days together + a heartbeat ♥; incoming notes scroll with your love's name in pink. Open (520 × 272): `sam ♥ nikki` top-left, a gear for Settings, and a bottom tab bar — **Home** (bento: photo tile, their latest note, Hours · Weekends · Seconds ticking live), **Note** (write with live word count and gentle hints, *3 times* / *Until opened*, Sending… → Sent ♡ → Delivered ♡), **Emoji** (❤️ 🥰 😘 🫶 🤗 🌹, *Out of the notch* / *Full screen*, remembered), **Photo** (empty state; sending arrives in slice 6). Emojis replace the heart button: each one pours out of your love's notch or splashes full screen, as the sender chose; 3+ that arrived while away always splash. Onboarding is restyled Setup-Assistant style (page dots, Back / Continue, Copy Code, Skip for Now). The gear opens a small Settings window (Open at Login).
  Why now: The learner found the old open notch cluttered at the early checkpoint and came back with a full design; CloudKit is waiting on the company admin to create the container, so the redesign goes first.
  PRD ref: `prd.md > Screens and Layout`, `prd.md > Look and Feel`, `prd.md > Sending Hearts`, `prd.md > Missed Hearts`, `prd.md > Sending Messages`, `prd.md > Onboarding and Sign In`
  Spec ref: `spec.md > Look and Feel`, `spec.md > Components`, `spec.md > Data Model`, `devpost/design_handoff/README.md`
  Build: Design tokens and shared controls (tab bar, small segmented control, heartbeat), new shape sizes and springs, header row (closed: days + heartbeat; open: names + gear), Home bento with stats math (hours, Saturdays, seconds), Note tab, Emoji tab, emoji arrivals replacing hearts in the outbox and effects, banner with partner name, Settings window, onboarding restyle with a look-up-then-join code step, simulator updated for emojis.
  Verify (mechanical): Tests for stats math (hours, weekends, seconds), emoji arrival rules (mode, 3+ → splash), note rule order and copy pass; build succeeds. Run the app paired with the simulator and capture screenshots of the closed notch, each tab, a note banner, and an emoji pour and splash.
  Learner check: Hover the notch and walk through Home, Note, Emoji, and Photo. Send a note and an emoji from the simulator and from your notch. Say whether it now feels like the design.
  Commit: `Redesign notch with tabs, notes, and emojis`

- [x] **6. Send your love a photo, and your mood**
  Becomes usable: The Photo tab sends a photo (Choose Photo… → square crop → encrypted upload → Sending → Delivered); it appears on your love's Home photo tile with `from nikki · 1h`. Every photo in the notch gets the Soft treatment by default; Settings offers Soft / Mono / Original. A new Mood tab sets your mood (emoji + label); your love's closed notch shows your small round avatar and mood to the left of the camera, with the ❤️ heartbeat on the right.
  Why now: Builds on slice 5's Photo tab and Home tile; before CloudKit so CloudKit carries the photo from the start.
  PRD ref: `prd.md > Your Love's Photo`, `prd.md > Your Mood`
  Spec ref: `spec.md > Components` (Partner Photo), `spec.md > Data Model`, `devpost/design_handoff/README.md` (Photo, Photo treatment)
  Build: `photoId` in the outbox, `Photo` record in the `Mailbox` (local file), NSOpenPanel + square crop + resize ≤ 512 px + JPEG + encryption, local cache of the partner's photo, Photo tab and Home tile wired, photo treatment modifier + Settings picker, simulator photo sending.
  Verify (mechanical): Tests for photo encrypt → store → fetch → decrypt, square crop size, and `photoId` change detection pass; the mailbox photo file is unreadable bytes. Run the app, send a photo each way, and capture the Home tile and Photo tab.
  Learner check: Send a photo from the Photo tab and see it on the simulator; send one from the simulator and see it on your Home tile and as the little avatar in your closed notch. Set a mood in the simulator and see it beside the avatar. Try Soft, Mono, and Original in Settings.
  Commit: `Add sending a photo and your mood to your love`

- [x] **7. Hearts travel through iCloud**
  Becomes usable: The same app, but rows travel through Apple's CloudKit public database instead of a local file. Onboarding checks you're signed into iCloud (with *Open System Settings* / *Try again* if not). Hearts and messages from the simulator arrive through real CloudKit; changes are picked up by silent pings, with checks on launch, wake, and every 5 minutes as a safety net. Ready for a second Mac.
  Why now: Company access arrived, but the Developer role can't create iCloud containers; it starts as soon as an admin creates `iCloud.com.kshitijbhardwaj.OurNotch.dev` (signing changes are stashed and ready). Company builds use `.dev` bundle/container names so the clean names stay free for the learner's own account.
  PRD ref: `prd.md > What We're Building`, `prd.md > States and Boundaries` (offline, iCloud storage full), `prd.md > The Core Journey` (step 9)
  Spec ref: `spec.md > Components` (Cloud Store), `spec.md > External Services and Dependencies` (CloudKit), `spec.md > Data Model`, `spec.md > Important Failure Modes`, `spec.md > Where It Runs and How Someone Tries It`
  Build: iCloud + push entitlements and container ID in `Config.swift`, private key moved to the Keychain, `CloudStore` implementing `Mailbox` (account status, save/fetch Invite/Join/Outbox/Photo (as encrypted `CKAsset`), `.changedKeys` updates), `CKQuerySubscription` + remote notification handling, launch/wake/5-minute fallback checks, rate-limit retry, iCloud check step in onboarding and `CKAccountChanged` handling, "will send when online ♡" state, README account-swap notes.
  Verify (mechanical): Build with the company team succeeds; run pairing, a heart, and a message between the app and the simulator through CloudKit and confirm the records exist in CloudKit Console with encrypted payloads; confirm a silent ping triggers a fetch (log line) for a development build; turn Wi-Fi off, send, turn it on, and confirm delivery.
  Learner check: With iCloud signed in, pair with the simulator again, send hearts and a message, and watch them arrive. Open CloudKit Console and see your two outbox rows — the payload is gibberish to anyone but you two.
  Commit: `Sync partners through CloudKit public database`

## Hands-on Checkpoints

- [x] Early usable behavior explored — after slice 2 (hearts pour and splash from the simulator), so feedback on the look, animations, and notch layout can shape messages and onboarding
- [ ] Final kick-the-tires exploration and feedback completed

## Final Review

- [ ] Retry: notch occasionally disappeared during the slice 2 checkpoint; `hidesOnDeactivate` fixed the app-switch case, but the learner's remaining trigger wasn't identified (full-screen app or desktop switch suspected)
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

- `Info.plist` replaced by build settings (`GENERATE_INFOPLIST_FILE`, `INFOPLIST_KEY_LSUIElement`); `Assets.xcassets` and `OurNotch.entitlements` deferred until something needs them (app icon, slice 5 CloudKit) — Xcode's folder-synced project generates the plist, and an empty asset catalog or entitlements file adds nothing yet.
- Slice 1 screenshot check replaced by a window-server check (layer 27 = menu bar + 3, 480×170 at top-center over a 179×32 notch) — this terminal lacks Screen Recording permission; the visual check moves to the slice 2 hands-on checkpoint.
- Local mailbox stores one file per outbox (`outbox-<owner>.json`) instead of one shared file — it mirrors CloudKit's one-writer-per-row model, so the two identities never overwrite each other.
- Notch panel grew 160 pt taller (transparent, click-through) — the pour needs room below the notch inside the same window.
- Early checkpoint feedback (after slice 2): closed notch made 2 pt taller (`Config.Notch.closedExtraHeight`) to fully cover the camera; close animation rebuilt on Boring Notch's structure — a persistent header row (`NotchHeaderView`, replacing `ClosedNotchView`) with open content added below it, spring attached via `.animation(_:value:)`, `.compositingGroup()` — because swapping the whole content mid-spring jittered; `hidesOnDeactivate = false` on the panel because it vanished when the user switched apps. Learner confirmed it looks good.
- Open notch grew from 150 to 196 pt tall — the message box and last-message line need their own rows below the counter and heart.
- The current banner is saved locally in both modes, not only `untilOpened` — one saved value is simpler; a `three` banner interrupted by quitting simply replays on relaunch.
- Sending from the notch is verified by a two-partner unit test on a temporary mailbox (send → partner sync → delivered), not by typing in the live notch — the terminal can't post keyboard/mouse events without Accessibility permission. Receiving, the 3-pass banner, and `untilOpened` across relaunch were verified live with screenshots.
- Private key stored in UserDefaults instead of the Keychain until slice 5 (marked `ponytail:` in `LocalStore.swift`) — ad-hoc "Sign to Run Locally" builds change signature every rebuild, so the Keychain would ask for the login password after each build and block automated tests. Slice 5 moves it to the Keychain once the app is signed with the company team. Needs the learner's OK.
- The Partner Simulator can also *invite* (with its own together-since date), not only join — so the notch's "I have a code" path can be tested on one Mac. Debug-only "Reset Everything (test)" menu item added for fresh-install testing.
- No partner `name` inside the encrypted outbox — names already travel in the Invite/Join records, and nothing reads them from the outbox.
- Slice 4 live check limited to the window server (fresh install shows only the onboarding window; the notch stays inactive until paired); the full pairing flow is verified by unit tests through the real `PairingService` and mailbox — the terminal can't click the onboarding UI, and the learner was on a call. The learner's hands-on check covers the clicks.
- Added slice 5 (tabbed redesign + partner photo) and renumbered CloudKit to slice 6 — at the early checkpoint the learner found the open notch cluttered and not cute, pointed to NotchBuddy's tabbed organization, and added one changeable partner photo. Cost explained (photo ~100 KB as an encrypted file vs ~1 KB rows; one more slice) and accepted. CloudKit access isn't available until tomorrow, so the redesign goes first.
- Next day: company access arrived (team added in Xcode, `.dev` bundle/container names agreed) but the Developer role can't create iCloud containers (`Your account does not have sufficient permissions to modify containers`); signing changes are stashed until an admin creates the container. CloudKit is now slice 7.
- The learner's designer returned a full v3 design (`devpost/design_handoff/`, used as the visual design with our logic). It adds an Emoji tab that replaces the heart button — each emoji pours out of the partner's notch or splashes full screen as the sender chooses, and 3+ missed always splash — plus Hours/Weekends/Seconds stats, a Settings gear, and a restyled onboarding; no avatars (learner). Split into slice 5 (new notch, notes, emojis) and slice 6 (photo).
- Slice 5 verified live by driving the app (Accessibility granted): fresh onboarding → invite → simulator joins with a lowercase code → date → login → done; every tab captured; note typed in the notch → Delivered ♡; emoji → Sent → Delivered; simulator note → banner with pink name; 1 emoji → pour; 3 → full-screen splash, window removed after. Found and fixed: the gear's hollow center ignored clicks (now a 28 pt square hit area); "Weekends" wrapped (kept to one line); helper windows now open on the active desktop (`showInFront`). Windows from other apps can't appear over a full-screen app when launched from the terminal — expected macOS behavior, not a bug.
- Numbers use the Mac's own grouping (e.g. 11,47,03,695 in Indian format) rather than the design's US grouping — native macOS behavior; learner to confirm.
- Photo tab shows its empty state with a disabled *Choose Photo…* until slice 6.
- Learner feedback on slice 5: open notch enlarged to 560 × 296 with an even 20 pt margin (content 520 × 200, photo square 200, 10 pt gaps) because the bento felt cramped; closed side slots widened 45 → 52 pt because the days count hugged the left edge; Settings moved inside the notch (the gear swaps the content area for a Settings card) because a separate window felt out of place.
- Second padding pass: margins now measured from the notch's black body, not its frame (the 14 pt ears sit inside the frame, so cards were only ~6 pt from the edge); open notch 568 × 296 around a 500 × 200 bento; photo tile made portrait (180 × 200) and stats split 1 : 1 : 1.8 so "Weekends" and the seconds fit at full size.
- Slice 5 review, round 3: the closed notch's hidden open-state row was wider than the closed shape and pushed the days count off-center (fixed: it may shrink); stat tiles now show a big centered number with the label underneath (photo tile 160 × 200).
- Added **mood** to slice 6 (learner): a Mood tab of emoji + label moods, and the closed notch shows the partner's small avatar (their photo) + mood on the left, ❤️ heartbeat on the right; the days count leaves the closed notch. Cost explained: one emoji in the encrypted row, and the avatar reuses the photo.
- Slice 6 verified: 23 tests (photos become ≤ 512 px square JPEGs, stored encrypted in the mailbox, downloaded + cached by the partner, Delivered; mood reaches the partner and clears). Live: the learner sent a photo from the simulator → Home tile with Soft treatment and "from manya · 1m", and the closed notch's avatar; Mood tab set → "Now 🎧 Focused"; simulator mood 🥺 → shown beside the avatar. Sending a photo *from* the notch is covered by the delivery test, not driven live. Placeholder partner name changed Nikki → Manya (learner). Closed side slots widened to 60 pt with a 10 pt inset so the avatar doesn't hug the curved edge. Tests no longer write photos to the real Application Support folder.
- Slice 7 verified live against the real CloudKit container (Development): iCloud check passed → invite saved to CloudKit → simulator joined through CloudKit → paired; simulator → notch: note (banner in ~3 s), 3 emojis (splash in ~2 s), mood (beside the avatar), photo (encrypted `CKAsset`, "New photo from partner"); notch → simulator: ❤️ → Delivered ❤️. Pings: subscription saved once the learner's `Outbox.ownerId` Queryable index existed. Not tested: offline/Wi-Fi-off retry and a full iCloud (changing network settings is the learner's call), and cross-Mac ping latency (needs the second Mac).
- Private key moved to the data-protection Keychain (team-signed builds); tests keep keys in throwaway `UserDefaults`. Debug builds poll every 3 s because CloudKit doesn't ping the Mac that made the change, so the notch and simulator on one Mac poll each other; Release polls every 5 min plus pings. Photos travel as `CKAsset`. The `.dev` bundle ID means a fresh install: the earlier local pairing was left behind (learner re-paired).
