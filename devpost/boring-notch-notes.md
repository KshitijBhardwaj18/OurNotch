# Boring Notch: How It Works (study notes)

Reference: https://github.com/TheBoredTeam/boring.notch (GPL-3.0). **Concepts only. We reimplement; we never copy code.** Two of its files are themselves derived from other projects (`NotchShape` from DynamicNotchKit, `CGSSpace` from Parrot, MPL-2.0), so don't copy those either.

## 1. The window
- An `NSPanel` subclass: borderless + non-activating, transparent background, no shadow, not movable, level `.mainMenu + 3` (above the menu bar).
- `collectionBehavior`: all Spaces, stationary, shows over full-screen apps, skipped by ⌘-Tab cycling.
- Dark appearance forced on the window.
- **The window is never resized.** It's created at the *fully open* size plus shadow padding (theirs: 640×210), placed top-center, and only the SwiftUI black shape inside grows and shrinks. When re-placing it, they hide it (alpha 0) first to avoid a visible jump.
- Their panel can't take keyboard focus. They have no text field in the notch, so OurNotch has to solve that part itself (see 6).

## 2. The "drivers": private APIs (we skip these)
- **CGSSpace:** private window-server calls that put the notch in its own always-on-top "space," so it doesn't slide during Space switches. Optional; the public `collectionBehavior` gets most of the way.
- **SkyLight:** a private framework used only to show the notch **on the lock screen**.
- **XPC helper:** a separate, unsandboxed process for private brightness/keyboard-backlight APIs and the Accessibility check.
- **Why we skip all three:** they're undocumented, can break on any macOS update, and OurNotch doesn't need lock-screen display, brightness, or media keys.

## 3. Notch size and screens
- Width = screen width − `auxiliaryTopLeftArea.width` − `auxiliaryTopRightArea.width` (+ a few points). Height = `safeAreaInsets.top`.
- "Has a notch" = `safeAreaInsets.top > 0`. No notch → a fixed pill (theirs: 185×32).
- **Gotcha:** `NSScreen.main` is the screen with the key window, *not* the built-in display. Pick the screen that has the notch, and identify displays by a stable UUID.
- Re-place on `NSApplication.didChangeScreenParametersNotification`, but compare screens first (it fires often).

## 4. The black shape
- A custom SwiftUI `Shape`: small concave "ears" at the top that flare into the menu bar, plus rounded bottom corners. The corner radii are animatable, so the shape morphs smoothly between closed and open.
- Content is padded inward by the corner radius, filled black, and clipped to the shape. A 1 pt black strip at the very top hides any seam at the screen edge.
- In the open state, keep a notch-wide gap in the middle of the top row: **anything drawn behind the camera is invisible.**

## 5. Hover, open, close
- Plain SwiftUI `.onHover`; no tracking areas, no Accessibility.
- **Debounce:** wait ~0.3 s of hovering before opening and ~0.1 s after leaving before closing, using one cancellable task and re-checking state after each wait. Don't auto-close while something (a popover, a text field) is in use.
- Haptic tick on hover with `.sensoryFeedback` (macOS 14).
- Springs: open ≈ response 0.42 / damping 0.8; close ≈ 0.45 / 1.0. Content fades and scales in from the top.

## 6. Clicks and typing
- **Click-through is implicit:** fully transparent pixels of a non-opaque window let clicks pass to the menu bar below. Where they *want* to catch the mouse (under the closed notch), they paint black at 1% opacity. Shadows and faint fills swallow clicks.
- **Typing (our addition):** let the panel become key (`canBecomeKey = true`), keep it non-activating so the user's current app stays in front, make it key when the message field is used, and keep the notch open while editing.
- Windows that need focus (settings, onboarding) temporarily switch the app to a regular app (`.regular` activation policy), then back to `.accessory`.

## 7. Widening the closed notch ("live activity")
- The closed notch is an HStack: [content] [black block the width of the real notch] [content]. The black background grows to fit, animated.
- **Marquee:** measure the text width, render the text twice with a gap, and slide it linearly (~30 pt/s) inside a clipped frame. → Our message banner.

## 8. App shell
- Agent app (`LSUIElement`: no Dock icon) with a **menu bar item** (`MenuBarExtra`) for Settings and Quit.
- Onboarding is a normal window with steps. Launch at login via a package (we use `SMAppService` directly).
- Their packages: Defaults, KeyboardShortcuts, LaunchAtLogin, Sparkle (updates), Lottie, MacroVisionKit (full-screen detection), SkyLightWindow, and others. **We need none of them for Milestone 1.**

## 9. Effects
- Nothing pours out of their notch, and there's no full-screen overlay. The only particle effect is a `CAEmitterLayer` sparkle in onboarding.
- For our hearts: pour = emitter at the notch's position; splash = a **separate full-screen window with `ignoresMouseEvents = true`**, same level and Spaces behavior, closed after the animation.

## 10. Permissions they ask for, and why we don't
Accessibility (media-key interception), Camera (mirror), Calendar/Reminders, Apple Events (music control), file access (shelf). **OurNotch needs none of these.** Hover works without Accessibility.

## 11. Hard-won lessons to reuse
1. Fixed-size window; animate only the content.
2. Pick the notch screen by UUID, never `NSScreen.main`.
3. Hover delays (0.3 s open / 0.1 s close) with cancellable tasks.
4. Transparent = click-through; 1%-opacity fill where you need a hit area.
5. Nothing behind the camera is visible.
6. Hide while re-placing; compare screens before rebuilding.
7. Force dark appearance on the notch window.
8. Swap the activation policy for windows that need typing.
