---
doc: spec
status: approved
---

# OurNotch — Technical Spec (Milestone 1)

## How This Works, In Plain Language
OurNotch is a **native Mac app written in Swift**. It has three pieces:

1. **The notch window.** A transparent, borderless window sits on top of the menu bar exactly where the camera notch is. Inside it, the app draws a **black shape that extends the real notch**, so it looks like the notch itself is growing. Hover over it and it expands to the **open notch**; move away and it shrinks back to the **closed notch**. On Macs without a notch, it draws the same black pill at the top center. Learned from Boring Notch's approach; no code copied.
2. **The shared "spreadsheet": CloudKit's public database.** Apple hosts it for the app, with no server of our own. Each partner owns **one row** (their *outbox*). Only its owner can write it; both partners read each other's. Every row holds a few numbers and the latest message, **encrypted** so only the two partners can read it. Because it's the *app's* public database, it doesn't use the user's own iCloud storage, so a full iCloud doesn't block anyone.
3. **The lock: shared-key encryption.** When you pair, each Mac creates a key pair and the two swap the *public* halves through the invite. Each Mac then works out the **same secret key** without it ever travelling anywhere. Everything in your outbox is locked with that key before it leaves your Mac.

**Hearts are just a number.** Your row says "hearts sent: 12". Your partner's Mac remembers "I've shown up to 9". The difference (3) is how many are new, which is how missed hearts are counted. After showing them, your partner's Mac writes "I've seen up to 12" in *their* row, and your Mac sees that and shows **Delivered**.

**How it finds out quickly:** when a row changes, Apple sends a silent ping to the partner's Mac, and the app re-reads the row within seconds. As a safety net, it also checks when the Mac wakes, when the app launches, and every 5 minutes.

**Why this shape:** no server to run, no third-party libraries (Apple frameworks only), two tiny rows per couple so it stays free, and one writer per row so the two Macs never overwrite each other.

## The Core Journey Through the System
PRD ref: `prd.md > The Core Journey`.

1. **Welcome** → the onboarding window shows a few screens (`Onboarding`).
2. **iCloud check** (replaces Sign in with Apple; see Decisions) → the app asks CloudKit whether the Mac is signed into iCloud. If it isn't, it shows "Sign in to iCloud" with a button that opens System Settings and a *Try again* button. Then: *"What should your love call you?"* → the name is saved locally.
3. **Invite** → the app creates a random 6-character code and a key pair, then saves an `Invite` record (code, your name, your public key) to the public database. *Send email* opens your Mail app with a pre-written invite (code + download link). The screen shows the code and "waiting for your love…"; the app checks for a `Join` record for that code.
   **Join** → your partner types the code. Their app fetches the `Invite`, shows "**Nikki ❤ invited you**", makes its own key pair, and saves a `Join` record (their name, their public key). If a `Join` already exists, the code is "used" and they get a gentle error.
   **Both Macs** now have each other's public key → each derives the same secret key → **paired**. Each creates its own `Outbox` row.
4. **Together since** → the **inviter** answers; the date goes into the inviter's encrypted outbox. The joiner's app reads it from there (the joiner isn't asked).
5. **Open at login** → a single toggle. That's the whole "permissions" step; the notch needs no special Mac permissions.
6. **Closed notch** → shows days together (computed on your Mac from the together-since date) + a heart.
7. **Send a heart** → hover to open, tap ❤ → the local "hearts sent" goes up. Rapid taps are bundled (1-second pause) into one save → the outbox is saved → status *Sent*. Apple pings the partner → their app reads your row → new = sent − shown → hearts pour out (or the full-screen splash if 3+) → they write "seen up to N" → your app reads it → *Delivered*.
8. **Send a message** → type (validated) → choose *3 times* or *until opened* → save: message id + text + mode go into your outbox → *Sent*. The partner's app sees a new message id → the banner scrolls → they write "seen message id" → *Delivered*.
9. **Success** → see `Where It Runs and How Someone Tries It`.

```
 Your Mac                          CloudKit public DB                    Partner's Mac
 ┌──────────────┐  save (locked)   ┌───────────────────┐   silent ping   ┌──────────────┐
 │ tap ❤        │ ───────────────▶ │ Outbox: you       │ ──────────────▶ │ read, unlock │
 │ "Delivered"  │ ◀─────────────── │ Outbox: partner   │ ◀────────────── │ hearts pour  │
 └──────────────┘   read their row └───────────────────┘  "seen up to N" └──────────────┘
```

## Stack
- **Swift + SwiftUI** for all UI, with **AppKit** (`NSPanel`) for the notch window, because SwiftUI alone can't place a borderless window above the menu bar. Docs: https://developer.apple.com/documentation/swiftui, https://developer.apple.com/documentation/appkit/nspanel
- **CloudKit** (public database, query subscriptions). Docs: https://developer.apple.com/documentation/cloudkit
- **CryptoKit**: `Curve25519.KeyAgreement` + `HKDF` + `ChaChaPoly`. Docs: https://developer.apple.com/documentation/cryptokit
- **ServiceManagement** (`SMAppService.mainApp`) for open at login. Docs: https://developer.apple.com/documentation/servicemanagement/smappservice
- **Swift Testing / XCTest** for the logic tests.
- **No third-party dependencies.** Learner agreed to Apple frameworks only; tradeoff: hearts animations are hand-built, not from a library.
- **Xcode 27** (not installed yet; install from the Mac App Store). Deployment target: **macOS 14**.
- Unverified, check early in the build: that a user whose iCloud storage is full can still save to the *public* database (expected yes, because the public DB uses the app's quota); and that silent-push subscriptions arrive reliably on macOS for a development-signed build.

## Where It Runs and How Someone Tries It
- **Runs:** locally on this MacBook (Mac16,12, macOS 26, has a notch), launched from Xcode.
- **Requirements:** Xcode 27; the **company's Apple Developer team** added in Xcode (Settings → Accounts); the Mac signed into iCloud.
- **Start:** open `OurNotch.xcodeproj` → select the *OurNotch* scheme → ⌘R. The app has no Dock icon; it lives in the notch, with a ♡ menu bar item for *Quit*.
- **One-Mac testing (now):** in Debug builds, a **Partner Simulator** window (♡ menu bar item → *Partner Simulator*) acts as a second partner with its own identity, keys, and outbox, talking through **real CloudKit** (it checks every 3 seconds instead of waiting for pings). It can join an invite, send hearts and messages, and show what it received. It's a test tool, clearly labelled, and isn't included in release builds.
- **Two-Mac testing (later):** register the second Mac's hardware ID on the company account, then archive in Xcode → *Distribute App* → *Debugging/Development* → copy the app to the second Mac. **Both Macs must use the same CloudKit environment.** Development builds use the *Development* database; a website (Developer ID) build uses *Production*, and the schema must be deployed to production first.
- **Demo video:** QuickTime → New Screen Recording. Show the closed notch + Partner Simulator side by side: the simulator sends 1 heart (pour), then 3 (splash), then a message (banner scrolls); then send a heart from the notch and watch *Sent → Delivered* plus the simulator receive it.
- **Public repo:** https://github.com/KshitijBhardwaj18/OurNotch. No deployment planned (optional anyway).

## Look and Feel
Implements `prd.md > Look and Feel` (cute, minimal, modern). **Proposed. Learner to confirm in review.**
- **Notch body:** pure black (`#000000`) so it blends with the real notch; rounded bottom corners; shape grows smoothly from the notch.
- **Accent:** soft rose `#FF7AA2` for hearts and the send button; blush `#FFC2D4` for highlights. Text white; secondary text white at 60%.
- **Type:** SF Pro **Rounded** (`.rounded` system design). Days number semibold with fixed-width digits so the counter doesn't jiggle.
- **Hearts:** SF Symbol `heart.fill` in rose/blush, mixed sizes, float up with a slight sway and fade (~1.5 s). The splash fills the screen for ~3 s, click-through.
- **Motion:** spring open/close (gentle, slight bounce); no harsh pops.
- **Copy tone:** short, soft, lowercase-cute: "sent ♡", "delivered ♡", "waiting for your love…", "nikki ❤ invited you".
- **Onboarding window:** small, centered, one thing per screen, adapts to light/dark mode.
- **Avoid:** generic glassy dashboard styling, gradients everywhere, emoji overload.
- **Open notch layout:** tabbed, NotchBuddy-style (one job per tab, tab bar at the bottom). **Redesign in progress:** the learner is getting a visual design from a design agent using `devpost/design-brief.md`; that design replaces this line once approved.

## Components

### Notch Window
`NSPanel` subclass: borderless + non-activating, transparent, no shadow, level `.mainMenu + 3`, on all Spaces and over full-screen apps, dark appearance forced. Lessons from `devpost/boring-notch-notes.md`:
- **Fixed size, never resized:** created at the fully-open size plus padding and placed top-center; only the SwiftUI shape inside animates. Hidden (alpha 0) while being re-placed.
- **Click-through:** transparent pixels let clicks reach the menu bar; the closed-notch hover area is painted black at 1% opacity so it catches the mouse.
- **Typing:** `canBecomeKey = true` while staying non-activating, made key when the message field is used; the notch stays open while editing.
- **Hover:** `.onHover` with ~0.3 s delay before opening and ~0.1 s before closing (one cancellable task); haptic tick via `.sensoryFeedback`.
- **No private APIs** (no CGSSpace/SkyLight/XPC helper). Tradeoff: no lock-screen display.
PRD ref: `prd.md > Screens and Layout`.

### Notch Geometry
Reads the notch size from `NSScreen.safeAreaInsets.top` and `auxiliaryTopLeftArea`/`auxiliaryTopRightArea`. No notch → pill fallback (about 185×32 pt). Picks the screen **with the notch** (not `NSScreen.main`, which is just the screen with the focused window), falling back to the main screen; re-places on `didChangeScreenParametersNotification` only when the screens actually changed.
PRD ref: `prd.md > Open Questions` (Macs without a notch). Resolved: pill fallback.

### Closed Notch View
Days together + ❤ beside the notch. Widens temporarily to show the message banner.
PRD ref: `prd.md > Days Together`, `prd.md > Sending Messages`.

### Open Notch View
Opens on hover. Live counter (days → seconds, ticks every second only while open), heart button, message field, scroll-mode toggle, send, last message, sent/delivered status. Keeps a notch-wide gap in its top row (behind the camera).
PRD ref: `prd.md > Days Together`, `prd.md > Sending Hearts`, `prd.md > Sending Messages`.

### Partner Photo
One image per partner, chosen from the Mac (`NSOpenPanel`, images only), resized to at most 512 px on the long side and saved as JPEG (~100 KB), then **encrypted with the shared key** and stored as its own mailbox record (`Photo`, owner-only write). The outbox carries `photoId`; when the partner's `photoId` changes, the app fetches, decrypts, and caches the image locally. Shown on the Home tab.
PRD ref: `prd.md > Your Love's Photo`.

### Hearts Effect
Two effects: **pour** (hearts float out of the notch, inside the notch window area) and **splash** (a separate full-screen, click-through, transparent window with hearts across the whole screen, ~3 s, then closes). Chosen by new-heart count: `< 3` pour, `≥ 3` splash.
PRD ref: `prd.md > Sending Hearts`, `prd.md > Missed Hearts`.

### Message Banner
Scrolling text, built as a marquee: measure the text, draw it twice with a gap, slide it ~30 pt/s inside a clipped frame. **It can't scroll *through* the notch: nothing drawn behind the camera is visible.** It scrolls in a strip just **below** the notch (the closed shape grows down ~22 pt while a banner is showing). Mode `three` scrolls 3 times then hides. Mode `untilOpened` repeats until the user opens the notch; it's saved locally so it survives a restart.
PRD ref: `prd.md > Sending Messages`.

### Menu Bar Item
A small ♡ in the menu bar (`MenuBarExtra`): *Quit OurNotch*, and *Partner Simulator* in Debug builds. (Boring Notch's right-click menu on the notch is marked as not working.)
PRD ref: none (app shell).

### Message Rules
Pure function: trims, then rejects empty, > 10 words, > 60 characters, or any word > 15 characters. Returns a gentle hint ("a little shorter ♡"). Limits live in `Config.swift`.
PRD ref: `prd.md > Sending Messages` (Message validation).

### Onboarding
Window with steps: Welcome → iCloud check → name → Invite / I have a code → (inviter) together-since date → open at login → done. Invite: shows the code, *Send email* (`mailto:` link opened with `NSWorkspace`), waiting state. Join: code field, "X ❤ invited you", invalid/used-code errors.
PRD ref: `prd.md > Onboarding and Sign In`, `prd.md > Pairing`.

### Pairing Service
Creates the `Invite` (code from an unambiguous alphabet, no 0/O/1/I), looks up an invite by code, creates the `Join` (fails if one exists → "used"), waits for the `Join` (checks every 3 s while the waiting screen is open), then hands keys to Crypto.
PRD ref: `prd.md > Pairing`.

### Crypto
Generates and stores the private key in the **Keychain**. Derives the shared key: X25519 → HKDF-SHA256 (salt = pair id, info = "OurNotch v1") → `ChaChaPoly` seal/open of the outbox payload.
PRD ref: `prd.md > States and Boundaries` (Privacy).

### Cloud Store
All CloudKit calls: account status, save/fetch `Invite`/`Join`/`Outbox`, the query subscription on the partner's outbox, and handling the silent ping. Fallback checks on launch, wake (`NSWorkspace.didWakeNotification`), and every 5 minutes. Retries after `requestRateLimited` using CloudKit's suggested delay. The container ID is read from `Config.swift` so it's easy to swap accounts later.
PRD ref: `prd.md > Sending Hearts`, `prd.md > Missed Hearts`, `prd.md > States and Boundaries`.

### App State
One observable object: identity, pairing, partner name, together-since, my outbox, last partner outbox, last-shown heart count, statuses. Decides what to animate when a partner outbox arrives (new hearts → pour/splash; new message id → banner) and computes Sent/Delivered.
PRD ref: `prd.md > Missed Hearts`, `prd.md > Sending Hearts`, `prd.md > Sending Messages`.

### Partner Simulator (Debug only)
Window with a second, independent App State (own identity/keys/outbox, separate local storage) driving real CloudKit. Buttons: join code, send ❤, send ❤×3, send message (with mode); shows received hearts, messages, and statuses.
PRD ref: supports verification of all `prd.md > Features and Behavior` on one Mac.

## Data Model

### CloudKit public database (Development environment)
Default security: anyone signed in to the app can read; only the record's creator can change it.

| Record type | Record name | Fields | Written by |
|---|---|---|---|
| `Invite` | `invite-<CODE>` | `inviterId` (String), `inviterName` (String), `inviterKey` (Bytes, public key) | inviter, once |
| `Join` | `join-<CODE>` | `joinerId`, `joinerName`, `joinerKey` | joiner, once (an existing record = "used code") |
| `Outbox` | `outbox-<userId>` | `ownerId` (String, **Queryable index**, needed for pings), `payload` (Bytes, encrypted) | its owner only |

`pairId` = `<CODE>`. `userId` = a random UUID per install (not the iCloud account), so two identities can share one iCloud account for testing.

| `Photo` | `photo-<userId>` | `ownerId`, `image` (Asset, encrypted JPEG) | its owner only |

**Encrypted `payload` (JSON before locking):**
```json
{ "name": "Nikki", "togetherSince": "2023-02-14", // togetherSince: inviter only
  "heartsSent": 12,
  "message": { "id": "uuid", "text": "hi babe how are you? love you", "mode": "three|untilOpened", "sentAt": "…" },
  "seenHearts": 4,          // partner's heartsSent I've shown
  "seenMessageId": "uuid",   // partner's message I've shown
  "photoId": "uuid" }       // changes when I pick a new photo
```

**Subscription:** a `CKQuerySubscription` on `Outbox` where `ownerId == partnerId`, firing on create and update, sent as a silent ping (`shouldSendContentAvailable`). CloudKit doesn't ping the Mac that made the change, so on one Mac (notch + Partner Simulator) Debug builds check every 3 s; Release builds check every 5 min plus pings and wake.

### On this Mac
- **Keychain** (data-protection Keychain, service `OurNotch`; the simulator uses `OurNotch.PartnerSimulator`): private key. Tests keep keys in a throwaway `UserDefaults` suite instead.
- **UserDefaults:** `userId`, my name, role (inviter/joiner), `pairId`, partner id + public key + name, together-since, my outbox payload (so counts survive restarts), last-shown partner heart count, pending `untilOpened` banner, open-at-login setting.
- **Leave and come back:** everything above persists. On launch the app fetches the partner's outbox, so anything missed while it was closed shows then (pour/splash, banner).
- **Partner Simulator** uses a separate `UserDefaults` suite and Keychain entry.

### Free-tier estimate (1,000 users = 500 couples)
About 2,000 small records (~1 KB) ≈ **2 MB** stored, plus one ~100 KB photo per user ≈ **100 MB** of assets (re-check the current public-database asset allowance in slice 6). Requests: 5-minute checks ≈ 288k/day ≈ 3.3/s, plus about 20 hearts/messages per user per day ≈ 60k/day ≈ 0.7/s. Total ≈ **4 requests/s on average**, well below the published starting allowance (~40/s). These numbers are old; confirm in CloudKit Console → Telemetry once live.

## File Structure
```
OurNotch/
├── OurNotch.xcodeproj
├── OurNotch/
│   ├── OurNotchApp.swift         # entry point; app delegate creates the notch window + onboarding
│   ├── Config.swift              # CloudKit container ID, message limits, timings (easy account swap)
│   ├── OurNotch.entitlements     # iCloud (CloudKit) + push
│   ├── Info.plist                # LSUIElement = YES (no Dock icon)
│   ├── Assets.xcassets           # app icon, accent colors
│   ├── Notch/
│   │   ├── NotchPanel.swift      # Notch Window
│   │   ├── NotchShape.swift      # our own black notch shape (animatable corners)
│   │   ├── NotchGeometry.swift   # Notch Geometry
│   │   ├── NotchView.swift       # switches closed ↔ open on hover
│   │   ├── ClosedNotchView.swift # Closed Notch View
│   │   ├── OpenNotchView.swift   # Open Notch View
│   │   ├── MessageBanner.swift   # Message Banner
│   │   └── HeartsEffect.swift    # pour + full-screen splash window
│   ├── Onboarding/
│   │   └── OnboardingView.swift  # all onboarding steps
│   ├── Sync/
│   │   ├── Mailbox.swift         # Mailbox interface + local file version (used until CloudKit)
│   │   ├── CloudStore.swift      # Cloud Store (CloudKit Mailbox, added last)
│   │   ├── PairingService.swift  # Pairing Service
│   │   └── Crypto.swift          # Crypto
│   ├── Model/
│   │   ├── AppState.swift        # App State (hearts math, statuses)
│   │   ├── Outbox.swift          # payload struct + JSON
│   │   └── MessageRules.swift    # Message Rules
│   └── Debug/
│       └── PartnerSimulator.swift # Debug only
├── OurNotchTests/
│   └── OurNotchTests.swift       # message rules, hearts math, crypto round trip
├── devpost/                      # Devpost learning workspace
├── .gitignore
└── README.md                     # how to run, account swap notes
```

## External Services and Dependencies

### CloudKit (public database)
- **Container:** `iCloud.<company-team-bundle-prefix>.ournotch` (exact ID set at build time in `Config.swift` + entitlements). Created in Xcode → Signing & Capabilities → iCloud → CloudKit. Schema: create the record types in Development (saving a record of a new type in Development creates it automatically); **mark `pairId` and `ownerId` queryable**, and make record names fetchable, in CloudKit Console. Console: https://icloud.developer.apple.com/
- **Calls** (`CKContainer(identifier:).publicCloudDatabase`):
  - `accountStatus()` → `.available` required.
  - `save(CKRecord)` for Invite/Join/Outbox create; `modifyRecords(saving:, savePolicy: .changedKeys)` for outbox updates.
  - `record(for: CKRecord.ID)` to fetch invite/join/outbox by name.
  - `save(CKQuerySubscription)` once after pairing; silent pings arrive via `NSApplicationDelegate.application(_:didReceiveRemoteNotification:)` after `NSApp.registerForRemoteNotifications()`.
- **Keys:** none; it uses the signed app's entitlements and the user's iCloud sign-in. **Cost:** free within limits (see estimate). **Account:** company team for now; Developer ID and production schema deployment later.
- Docs: https://developer.apple.com/documentation/cloudkit/ckquerysubscription, https://developer.apple.com/documentation/cloudkit/ckcontainer/accountstatus()

### Mail
`mailto:?subject=…&body=…` opened with `NSWorkspace.shared.open`. The body includes the code and download link `https://github.com/KshitijBhardwaj18/OurNotch/releases` (placeholder until the website exists).

## Important Failure Modes
- **Not signed into iCloud / iCloud signed out later** → onboarding (or the open notch) shows "Sign in to iCloud" + *Open System Settings* + *Try again*; the app also listens for `CKAccountChanged`.
- **Offline / CloudKit error on send** → status stays *Sent*-pending with a small "will send when online ♡"; it retries on the next check. The local count is never lost because it's saved before syncing.
- **Ping doesn't arrive** → the 5-minute / wake / launch checks still deliver (slower, never lost).
- **Rate limited** → wait the suggested time and retry; rapid heart taps are bundled into one save.
- **Bad or used invite code** → gentle error, try again.

## What Was Simplified and Why
- **iCloud account + typed name** instead of Sign in with Apple — the learner agreed: CloudKit already knows the iCloud user; Sign in with Apple added a step and setup without adding anything without a server.
- **One outbox row per partner** instead of shared records — each row has one writer, which fits CloudKit's creator-only write rule and avoids conflicts.
- **Partner Simulator on one Mac** instead of two Macs now — the learner has no second Mac registered yet. It still uses real CloudKit + real encryption; only the "silent ping across two Macs" waits for the second Mac.
- **Per-install identity** instead of iCloud identity — allows testing with one iCloud account; real per-person identity can come with multi-device support.
- **Local sync stand-in until CloudKit access** — the learner has no company-account access yet (a free Apple ID can't use CloudKit either). Sync sits behind one small `Mailbox` interface with two versions: a **local file mailbox** (both identities on this Mac swap encrypted outboxes through a shared file in Application Support) used now, and **CloudKit** swapped in later with no other app changes. Learner chose this over Supabase (free plan caps live connections at 200 and needs a login step). Build order changes: UI, rules, crypto, pairing, and hearts logic first; **CloudKit last**. Tradeoff: real two-Mac sync stays unproven until then, and CloudKit surprises surface late. The demo labels the local stand-in until CloudKit lands. Runs with "Sign to Run Locally"; no Apple account needed until the CloudKit step.
- **Public window APIs only** instead of Boring Notch's private CGSSpace (own always-on-top layer, no sliding during Space switches) and SkyLight (show on lock screen). The learner wants to **explore both later**; they're undocumented and can break with macOS updates. See `devpost/boring-notch-notes.md > 2`.
- **Invite code doubles as pair id** — simple; protection against the wrong person pairing is deferred (`prd.md > Deferred From the POC`).

## Decisions and Open Issues

### Decisions
- **Learner: workflow.** Every build slice ships as its own scoped pull request (stacked PRs, bottom-up), following normal SDLC: branch → commit → PR → review → merge.
- **Learner:** drop Sign in with Apple; use the Mac's iCloud account, and if it isn't signed in, guide them to sign in and retry.
- **Learner:** the inviter answers "together since"; the partner receives it. Editing it later (by either partner) goes on the roadmap.
- **Learner:** build and test on one Mac now; a registered second Mac comes later.
- **Learner (scope):** CloudKit public database, encrypted, free to ~1,000 users; Boring Notch as an architecture reference, with no code copied (GPL-3.0).
- **Boring Notch study** (`devpost/boring-notch-notes.md`): adopt fixed-size window, hover delays, notch-screen detection, click-through, marquee, and full-screen click-through splash window; skip private APIs, XPC helper, and all extra permissions and packages.
- **Agent-proposed, accepted with the plan:** Apple frameworks only; X25519 + ChaChaPoly; outbox-per-partner model; 5-minute fallback checks; pill fallback on non-notch Macs; "open at login" as the only permission step; macOS 14 target.
- **Pending learner confirmation:** `Look and Feel` colors, fonts, and open-notch layout.

### The learner's question: "How will we figure out missed hearts? How will the back end work?"
Clarified with the running-count idea (the learner's own "single number" from scope): `new = partner.heartsSent − my lastShown`. **Checked in the build** by a unit test (12 sent, 9 shown → 3 → splash; 2 new → pour) and by the Partner Simulator sending 3 hearts while OurNotch is quit, then relaunching → splash.

### Open issues
- **Verify early:** public-DB save works when the user's iCloud is full; silent pings arrive on macOS (development build).
- **Second-Mac test:** cross-Mac ping latency ("within seconds") is unverified until a registered second Mac is available.
- **Company permission** to use their Apple account for this project (learner to confirm).
- **Xcode install + company team access in Xcode** are prerequisites for the first build step.
