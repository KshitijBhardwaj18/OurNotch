import SwiftUI

/// Plays arriving emojis: a soft pour from under the notch, or a full-screen splash.
@MainActor
@Observable
final class EmojiEffect {
    struct Pour: Identifiable {
        let id = UUID()
        let floaters: [Floater]
    }

    /// Pours currently playing under the notch. Each removes itself when finished.
    private(set) var pours: [Pour] = []
    @ObservationIgnored private var splashWindow: NSWindow?
    /// What the splash window shows; a burst arriving mid-splash joins it instead of being dropped.
    @ObservationIgnored private var glyphs = Splash()
    @ObservationIgnored private var splashEnds = Date.distantPast

    /// `emojis`: the ones that arrived, oldest first (a burst can mix them). The newest decides pour or splash.
    func play(newCount: Int, emojis: [SentEmoji]) {
        guard let newest = emojis.last else { return }
        switch Arrival.effect(forNew: newCount, mode: newest.mode) {
        case .pour: emojis.forEach { pour($0.char) }
        case .splash: splash(emojis.map(\.char))
        case nil: break
        }
    }

    func pour(_ char: String) {
        let pour = Pour(floaters: Floater.pour(char))
        pours.append(pour)
        PerfMonitor.shared.track("pour \(char)", seconds: Floater.longestPour)
        Task {
            try? await Task.sleep(for: .seconds(Floater.longestPour))
            pours.removeAll { $0.id == pour.id }
        }
    }

    /// A separate transparent window covering the whole screen. It ignores the mouse,
    /// so the user can keep working while emojis drift up.
    func splash(_ chars: [String]) {
        guard !chars.isEmpty, let screen = NotchGeometry.current()?.screenFrame else { return }
        let floaters = Floater.splash(chars, in: screen.size)
        splashEnds = max(splashEnds, .now + Floater.length(of: floaters))
        PerfMonitor.shared.track("splash \(chars.joined())", seconds: Floater.length(of: floaters))
        // ponytail: at most this many glyphs at once, older (already faded) ones dropped first; enough to fill the screen.
        glyphs.floaters = Array((glyphs.floaters + floaters).suffix(120))
        guard splashWindow == nil else { return }

        let window = NSPanel(contentRect: screen, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.hidesOnDeactivate = false
        window.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 2)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.contentView = NSHostingView(rootView: SplashView(splash: glyphs))
        window.orderFrontRegardless()
        splashWindow = window

        Task {
            while Date.now < splashEnds { try? await Task.sleep(for: .seconds(splashEnds.timeIntervalSinceNow)) }
            splashWindow?.close()
            splashWindow = nil
            glyphs.floaters = []
        }
    }
}

/// Emojis drifting softly down from under the notch.
struct PourView: View {
    let floaters: [Floater]

    var body: some View {
        ZStack {
            ForEach(floaters) { FloatingGlyph(floater: $0) }
        }
        .allowsHitTesting(false)
    }
}

@MainActor
@Observable
final class Splash {
    var floaters: [Floater] = []
}

private struct SplashView: View {
    let splash: Splash

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(splash.floaters) { FloatingGlyph(floater: $0).position($0.start) }
        }
        .ignoresSafeArea()
    }
}

/// One floating copy's path, size, color and timing, picked at random so no two look the same.
struct Floater: Identifiable {
    let id = UUID()
    let char: String
    var start: CGPoint = .zero
    let travel: CGSize
    let sway: CGFloat
    let spin: Double
    let size: CGFloat
    /// Only used for ❤️, which is drawn as the design's pink heart instead of the red emoji.
    let tint: Color
    let delay: Double
    let duration: Double

    static let longestPour = 0.5 + 1.5
    static let longestSplash = 17 * 0.08 + 3.0

    /// How long a set of floaters takes to finish.
    static func length(of floaters: [Floater]) -> Double { floaters.map { $0.delay + $0.duration }.max() ?? 0 }

    static func pour(_ char: String) -> [Floater] {
        (0..<Int.random(in: 2...3)).map { i in
            Floater(char: char,
                    travel: CGSize(width: .random(in: -24...24), height: .random(in: 100...130)),
                    sway: .random(in: 6...8) * (Bool.random() ? 1 : -1),
                    spin: .random(in: -14...14),
                    size: char == "❤️" ? .random(in: 14...20) : .random(in: 17...25),
                    tint: Bool.random() ? .notchPink : .notchBlush,
                    delay: Double(i) * 0.25,
                    duration: 1.5)
        }
    }

    /// One emoji rises 18 times; a burst rises more (8 per emoji, up to 60), the emojis taking turns.
    static func splash(_ chars: [String], in screen: CGSize) -> [Floater] {
        let count = chars.count == 1 ? 18 : min(60, max(18, chars.count * 8))
        return (0..<count).map { i in
            Floater(char: chars[i % chars.count],
                    start: CGPoint(x: .random(in: 40...(screen.width - 40)), y: screen.height + 30),
                    travel: CGSize(width: .random(in: -40...40), height: -.random(in: 320...400)),
                    sway: .random(in: 10...20) * (Bool.random() ? 1 : -1),
                    spin: .random(in: -20...20),
                    size: .random(in: 14...32),
                    tint: [Color.notchPink, .notchBlush, .white].randomElement()!,
                    delay: Double(i) * 0.08,
                    duration: 3.0)
        }
    }
}

/// Grows in, drifts along its path with a gentle sway and tilt, then fades out.
private struct FloatingGlyph: View {
    let floater: Floater
    @State private var started = false

    private struct Motion {
        var offset: CGSize = .zero
        var scale: CGFloat = 0.4
        var angle: Double = 0
        var opacity: Double = 0
    }

    var body: some View {
        glyph
            .keyframeAnimator(initialValue: Motion(), trigger: started) { content, motion in
                content
                    .scaleEffect(motion.scale)
                    .rotationEffect(.degrees(motion.angle))
                    .offset(motion.offset)
                    .opacity(motion.opacity)
            } keyframes: { _ in
                let d = floater.duration, t = floater.travel, s = floater.sway
                KeyframeTrack(\.offset) {
                    CubicKeyframe(CGSize(width: t.width * 0.33 + s, height: t.height * 0.33), duration: d / 3)
                    CubicKeyframe(CGSize(width: t.width * 0.66 - s, height: t.height * 0.66), duration: d / 3)
                    CubicKeyframe(t, duration: d / 3)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1, duration: d * 0.25, spring: .bouncy)
                }
                KeyframeTrack(\.angle) {
                    CubicKeyframe(floater.spin, duration: d)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: d * 0.12)
                    LinearKeyframe(1, duration: d * 0.5)
                    LinearKeyframe(0, duration: d * 0.38)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(floater.delay))
                started = true
            }
    }

    @ViewBuilder private var glyph: some View {
        if floater.char == "❤️" {
            Image(systemName: "heart.fill")
                .font(.system(size: floater.size))
                .foregroundStyle(floater.tint)
        } else {
            Text(floater.char).font(.system(size: floater.size))
        }
    }
}
