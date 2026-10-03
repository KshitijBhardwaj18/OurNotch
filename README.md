# OurNotch

A cute little shared space for couples that lives in the MacBook notch: tap to send your partner floating hearts, or send a message that scrolls across their notch.

## Run it

Requirements: macOS 14+, Xcode 27.

1. Open `OurNotch.xcodeproj`.
2. Select the **OurNotch** scheme and press ⌘R.

OurNotch has no Dock icon. It lives in the notch; hover to open it. Quit from the ♡ in the menu bar.

From the command line:

```bash
xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/OurNotch.app
```

Tests: `xcodebuild -project OurNotch.xcodeproj -scheme OurNotch -derivedDataPath build/DerivedData test`

## Project layout

- `OurNotch/OurNotchApp.swift`: entry point; the app delegate places the notch window.
- `OurNotch/Config.swift`: tunable values and colors.
- `OurNotch/Notch/`: the notch window, its shape, and the closed/open views.
- `OurNotch/Model/`: app state and pure logic.
- `devpost/`: planning docs (scope, PRD, spec, build checklist).

The notch approach is inspired by [Boring Notch](https://github.com/TheBoredTeam/boring.notch) (GPL-3.0). We learned from its design; no code was copied.
