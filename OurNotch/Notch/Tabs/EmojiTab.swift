import SwiftUI

/// One-tap affection: pick an emoji, and choose whether it pours out of your love's notch or fills their screen.
struct EmojiTab: View {
    let state: AppState

    /// Remembered between launches and sent with each emoji.
    @AppStorage("emojiMode") private var mode: EmojiMode = .notch
    /// The emoji whose status is showing; cleared ~3 s after it's delivered.
    @State private var lastSent: String?
    @State private var clearTask: Task<Void, Never>?
    /// Bumped on each tap to play the little float-up on that button.
    @State private var taps: [String: Int] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 8)
            emojiRow
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                Text("Appears").font(.system(size: 12)).foregroundStyle(Color.pastelInk2)
                SmallSegmented(options: EmojiMode.allCases, selection: $mode, label: \.label, symbol: \.symbol)
            }
        }
        .pastelCard(Color.pastelSky)
        .onChange(of: state.emojiStatus) { _, status in
            guard status == .delivered else { return }
            clearTask?.cancel()
            clearTask = Task {
                try? await Task.sleep(for: .seconds(3))
                if !Task.isCancelled { lastSent = nil }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Send an emoji").pastelTitle()
                Text("Tap one and it pops up on \(state.partnerName.lowercased())'s screen ♡")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.pastelInk2)
            }
            Spacer()
            status.font(.system(size: 11.5, weight: .medium))
        }
    }

    @ViewBuilder private var status: some View {
        if let lastSent {
            if state.emojiStatus == .delivered {
                Text("Delivered \(lastSent)").foregroundStyle(Color.notchPink)
            } else {
                Text("Sent \(lastSent)").foregroundStyle(Color.pastelInk)
            }
        } else {
            Text("Tap to send").foregroundStyle(Color.pastelInk3)
        }
    }

    private var emojiRow: some View {
        HStack(spacing: 6) {
            ForEach(Config.emojis, id: \.self) { char in
                Button { send(char) } label: {
                    Text(char).font(.system(size: 32))
                }
                .buttonStyle(EmojiButtonStyle(isLastSent: char == lastSent))
                .overlay { TapBurst(char: char, trigger: taps[char, default: 0]) }
            }
        }
    }

    private func send(_ char: String) {
        state.sendEmoji(char, mode: mode)
        clearTask?.cancel()
        lastSent = char
        taps[char, default: 0] += 1
    }
}

/// `#2C2C2E` tile that dims and shrinks while pressed; tinted pink for the last one sent.
private struct EmojiButtonStyle: ButtonStyle {
    let isLastSent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(fill(pressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: 0x5A1E32).opacity(0.08), radius: 5, y: 2)
            .overlay {
                if isLastSent {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.notchPink.opacity(0.7), lineWidth: 1.5)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }

    private func fill(pressed: Bool) -> Color {
        if pressed { return .pastelBlush }
        return isLastSent ? Color.notchPink.opacity(0.16) : .white
    }
}

/// Three small copies float up ~40 pt from the tapped button (dx −10 / 0 / +10, 0.9 s, 70 ms apart).
private struct TapBurst: View {
    let char: String
    let trigger: Int

    var body: some View {
        ZStack {
            ForEach(Array([-10.0, 0, 10].enumerated()), id: \.offset) { index, dx in
                Text(char)
                    .font(.system(size: 14))
                    .keyframeAnimator(initialValue: Motion(), trigger: trigger) { view, motion in
                        view.offset(x: motion.dx, y: motion.dy).opacity(motion.opacity)
                    } keyframes: { _ in
                        let delay = Double(index) * 0.07
                        KeyframeTrack(\.dx) {
                            LinearKeyframe(0, duration: delay)
                            CubicKeyframe(dx, duration: 0.9)
                        }
                        KeyframeTrack(\.dy) {
                            LinearKeyframe(0, duration: delay)
                            CubicKeyframe(-40, duration: 0.9)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0, duration: delay)
                            LinearKeyframe(1, duration: 0.1)
                            LinearKeyframe(1, duration: 0.4)
                            LinearKeyframe(0, duration: 0.4)
                        }
                    }
            }
        }
        .allowsHitTesting(false)
    }

    private struct Motion {
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var opacity: Double = 0
    }
}
