# OurNotch

A cute little shared space for couples that lives in the MacBook notch: tap to send your partner floating hearts, or send a message that scrolls across their notch.

## Run it

Requirements: macOS 14+, Xcode 27, a Mac signed into iCloud, and Xcode signed into an Apple Developer team that can use the CloudKit container (currently the company team `FFP4CMK386`, bundle `com.kshitijbhardwaj.OurNotch.dev`, container `iCloud.com.kshitijbhardwaj.OurNotch.dev`).

**Switching accounts later:** change `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER` in the project, the container in `OurNotch/OurNotch.entitlements`, and `Config.Cloud.containerId`. In the new container's CloudKit Console, add a **Queryable** index on `Outbox.ownerId` so pings work. CloudKit data doesn't move between accounts; couples pair again.

1. Open `OurNotch.xcodeproj`.
2. Select the **OurNotch** scheme and press ⌘R.

OurNotch has no Dock icon. It lives in the notch; hover to open it. Quit from the ♡ in the menu bar. In Debug builds the ♡ menu also has *Partner Simulator…* (pair and chat with a pretend partner) and *Reset Everything (test)*.

From the command line:

```bash
xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData -allowProvisioningUpdates build
open build/DerivedData/Build/Products/Debug/OurNotch.app
```

Performance and delivery logs: every event is appended to `~/Library/Logs/OurNotch/this-mac.log` as it happens (no note text, photos or keys). Lines tagged `[perf]` give each animation's dropped frames (notch open/close, tabs, pour, splash, banner) and any main-thread hang of 250 ms or more; `sent … ago` gives delivery time. Both Macs also save every measurement (animation frames, hangs, delivery delay on each side, CloudKit request times, pings) as `Metric` records in CloudKit; every 2 minutes the app downloads both sides into `metrics.csv` and the partner's latest log lines into `partner-mac.log` (♡ → *Save Diagnostics* does it now). Before shipping to Production, deploy the `Metric` schema with `ownerId` Queryable, or turn `Config.Diagnostics.uploads` off.

**Licence (Dodo Payments, test mode):** a fresh install opens on the licence gate. Every build talks to Dodo's test mode for now (`Config.Licence`). To try the gate without touching your real pairing, run a separate fresh identity in a Debug build:

```bash
OURNOTCH_PROFILE=gate1 build/DerivedData/Build/Products/Debug/OurNotch.app/Contents/MacOS/OurNotch
```

Get a test key by buying with card 4242 4242 4242 4242 at the gate's *Get OurNotch*, or ask the agent to create one through Dodo's API.

**Languages:** English, French and German live in `OurNotch/Localizable.xcstrings`. Building in Xcode keeps it in step with the code; after a command-line build, run `python3 scripts/sync-strings.py --check` to add new strings and list any missing a translation. Settings → Language overrides the Mac's language for OurNotch only (it restarts). To see a language without switching: `xcodebuild test -testLanguage de`, or run with `-AppleLanguages "(de)"`.

Tests: `xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData test`

## Project layout

- `OurNotch/OurNotchApp.swift`: entry point; the app delegate places the notch window.
- `OurNotch/Config.swift`: tunable values and colors.
- `OurNotch/Notch/`: the notch window, its shape, header, banner, emoji effects, and shared controls.
- `OurNotch/Notch/Tabs/`: the open notch's Home, Note, Emoji and Photo tabs.
- `OurNotch/Model/`: app state and pure logic (outbox, note rules, time-together math).
- `OurNotch/Sync/`: the mailbox (CloudKit `CloudStore` in the app; a local-file version for tests), pairing, encryption, and the Keychain.
- `OurNotch/Licence/`: the licence service (Dodo activate / validate).
- `OurNotch/Onboarding/`, `OurNotch/Settings/`: the setup window (starting at the licence gate) and the Settings window.
- `OurNotch/Debug/`: the Partner Simulator (Debug builds only) — a second partner on the same Mac.
- `devpost/`: planning docs (scope, PRD, spec, build checklist) and `design_handoff/` (the v3 design).

The notch approach is inspired by [Boring Notch](https://github.com/TheBoredTeam/boring.notch) (GPL-3.0). We learned from its design; no code was copied.
