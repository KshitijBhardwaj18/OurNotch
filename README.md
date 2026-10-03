# OurNotch

A cute little shared space for couples that lives in the MacBook notch: tap to send your partner floating hearts, or send a message that scrolls across their notch.

## Run it

Requirements: macOS 14+, Xcode 27.

1. Open `OurNotch.xcodeproj`.
2. Select the **OurNotch** scheme and press ⌘R.

OurNotch has no Dock icon. It lives in the notch; hover to open it. Quit from the ♡ in the menu bar. In Debug builds the ♡ menu also has *Partner Simulator…* (pair and chat with a pretend partner) and *Reset Everything (test)*.

From the command line:

```bash
xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/OurNotch.app
```

Tests: `xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData test`

## Project layout

- `OurNotch/OurNotchApp.swift`: entry point; the app delegate places the notch window.
- `OurNotch/Config.swift`: tunable values and colors.
- `OurNotch/Notch/`: the notch window, its shape, header, banner, emoji effects, and shared controls.
- `OurNotch/Notch/Tabs/`: the open notch's Home, Note, Emoji and Photo tabs.
- `OurNotch/Model/`: app state and pure logic (outbox, note rules, time-together math).
- `OurNotch/Sync/`: the mailbox (local file for now), pairing, and encryption.
- `OurNotch/Onboarding/`, `OurNotch/Settings/`: the setup window and the Settings window.
- `OurNotch/Debug/`: the Partner Simulator (Debug builds only) — a second partner on the same Mac.
- `devpost/`: planning docs (scope, PRD, spec, build checklist) and `design_handoff/` (the v3 design).

The notch approach is inspired by [Boring Notch](https://github.com/TheBoredTeam/boring.notch) (GPL-3.0). We learned from its design; no code was copied.
