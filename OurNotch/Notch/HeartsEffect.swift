import SwiftUI

/// Plays arriving hearts: a soft pour from the notch, or a full-screen splash for 3 or more.
@MainActor
@Observable
final class HeartsEffect {
    struct Pour: Identifiable {
        let id = UUID()
        let hearts = HeartSpec.pour()
    }

    /// Pours currently playing under the notch. Each removes itself when finished.
    private(set) var pours: [Pour] = []
    @ObservationIgnored private var splashWindow: NSWindow?

    func play(newHearts count: Int) {
        switch Hearts.effect(forNew: count) {
        case .pour: pour()
        case .splash: splash()
        case nil: break
        }
    }

    func pour() {
        let pour = Pour()
        pours.append(pour)
        Task {
            try? await Task.sleep(for: .seconds(HeartSpec.longestPour))
            pours.removeAll { $0.id == pour.id }
        }
    }

    /// A separate transparent window covering the whole screen. It ignores the mouse,
    /// so the user can keep working while hearts drift up.
    func splash() {
        guard splashWindow == nil, let screen = NotchGeometry.current()?.screenFrame else { return }

        let window = NSPanel(contentRect: screen, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 2)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.contentView = NSHostingView(rootView: SplashView(hearts: HeartSpec.splash(in: screen.size)))
        window.orderFrontRegardless()
        splashWindow = window

        Task {
            try? await Task.sleep(for: .seconds(HeartSpec.longestSplash))
            splashWindow?.close()
            splashWindow = nil
        }
    }
}

/// Hearts falling softly out from under the notch.
struct PourView: View {
    let hearts: [HeartSpec]

    var body: some View {
        ZStack {
            ForEach(hearts) { FloatingHeart(spec: $0) }
        }
        .allowsHitTesting(false)
    }
}

private struct SplashView: View {
    let hearts: [HeartSpec]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(hearts) { FloatingHeart(spec: $0).position($0.start) }
        }
        .ignoresSafeArea()
    }
}

/// One heart's path, size, color and timing, picked at random so no two look the same.
struct HeartSpec: Identifiable {
    let id = UUID()
    var start: CGPoint = .zero
    let travel: CGSize
    let sway: CGFloat
    let size: CGFloat
    let color: Color
    let delay: Double
    let duration: Double

    static let longestPour = 0.6 + 1.8
    static let longestSplash = 1.2 + 2.6

    static func pour(count: Int = 10) -> [HeartSpec] {
        (0..<count).map { _ in
            HeartSpec(travel: CGSize(width: .random(in: -110...110), height: .random(in: 60...140)),
                      sway: .random(in: 8...18),
                      size: .random(in: 10...20),
                      color: Bool.random() ? .rose : .blush,
                      delay: .random(in: 0...0.6),
                      duration: .random(in: 1.4...1.8))
        }
    }

    static func splash(in screen: CGSize, count: Int = 70) -> [HeartSpec] {
        (0..<count).map { _ in
            HeartSpec(start: CGPoint(x: .random(in: 0...screen.width), y: screen.height + 40),
                      travel: CGSize(width: .random(in: -60...60), height: -screen.height * .random(in: 0.6...1.05)),
                      sway: .random(in: 15...35),
                      size: .random(in: 18...46),
                      color: Bool.random() ? .rose : .blush,
                      delay: .random(in: 0...1.2),
                      duration: .random(in: 2.0...2.6))
        }
    }
}

/// Grows in, drifts along its path with a gentle sway, then fades out.
private struct FloatingHeart: View {
    let spec: HeartSpec
    @State private var started = false

    private struct Motion {
        var offset: CGSize = .zero
        var scale: CGFloat = 0.3
        var opacity: Double = 0
    }

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: spec.size))
            .foregroundStyle(spec.color)
            .keyframeAnimator(initialValue: Motion(), trigger: started) { content, motion in
                content
                    .scaleEffect(motion.scale)
                    .offset(motion.offset)
                    .opacity(motion.opacity)
            } keyframes: { _ in
                let d = spec.duration, t = spec.travel, s = spec.sway
                KeyframeTrack(\.offset) {
                    CubicKeyframe(CGSize(width: t.width * 0.33 + s, height: t.height * 0.33), duration: d / 3)
                    CubicKeyframe(CGSize(width: t.width * 0.66 - s, height: t.height * 0.66), duration: d / 3)
                    CubicKeyframe(t, duration: d / 3)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1, duration: d * 0.3, spring: .bouncy)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: d * 0.15)
                    LinearKeyframe(1, duration: d * 0.5)
                    LinearKeyframe(0, duration: d * 0.35)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(spec.delay))
                started = true
            }
    }
}
