import SwiftUI

enum NotchTab: CaseIterable {
    case home, note, emoji, mood, photo

    var label: String {
        switch self {
        case .home: "Home"
        case .note: "Note"
        case .emoji: "Emoji"
        case .mood: "Mood"
        case .photo: "Photo"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .note: "bubble.left"
        case .emoji: "face.smiling"
        case .mood: "cloud.sun"
        case .photo: "photo"
        }
    }
}

/// The native-looking segmented control at the bottom of the open notch (76 pt per tab × 28).
struct NotchTabBar: View {
    @Binding var selection: NotchTab
    /// True while Settings covers the tabs, so no tab looks selected.
    var dimmed = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NotchTab.allCases, id: \.self) { tab in
                let selected = tab == selection && !dimmed
                Button { selection = tab } label: {
                    HStack(spacing: 5) {
                        Image(systemName: selected ? "\(tab.symbol).fill" : tab.symbol)
                            .font(.system(size: 14))
                            .foregroundStyle(selected ? Color.notchPink : .secondaryLabel)
                        Text(tab.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(selected ? Color.white : .secondaryLabel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.segmentSelected)
                                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .frame(width: CGFloat(NotchTab.allCases.count) * 76, height: 28)
        .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 8))
        .animation(.snappy(duration: 0.2), value: selection)
        .animation(.snappy(duration: 0.2), value: dimmed)
    }
}

/// The small two-option control used for "Scroll" and "Appears".
struct SmallSegmented<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var symbol: ((Option) -> String)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button { selection = option } label: {
                    HStack(spacing: 4) {
                        if let symbol { Image(systemName: symbol(option)).font(.system(size: 10, weight: .semibold)) }
                        Text(label(option))
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(selected ? Color.white : .secondaryLabel)
                    .padding(.horizontal, 10)
                    .frame(height: 20)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.segmentSelected)
                                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 7))
        .animation(.snappy(duration: 0.2), value: selection)
    }
}

/// A double beat every 2.6 s: 1 → 1.18 → 1 → 1.1 → 1 over ~0.85 s, then rest.
struct Heartbeat: ViewModifier {
    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 1.0, repeating: true) { view, scale in
            view.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(1.18, duration: 0.18)
                CubicKeyframe(1.0, duration: 0.2)
                CubicKeyframe(1.1, duration: 0.17)
                CubicKeyframe(1.0, duration: 0.3)
                LinearKeyframe(1.0, duration: 1.75)
            }
        }
    }
}

extension View {
    func heartbeat() -> some View { modifier(Heartbeat()) }

    /// The `#1C1C1E` rounded card that holds the Note, Emoji and Photo tabs.
    func cardStyle() -> some View {
        padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// "now", "2m ago", "1h ago", "3d ago" — or "2m", "1h", "3d" without the suffix.
func shortAgo(_ date: Date, now: Date = .now, suffix: Bool = true) -> String {
    let seconds = max(0, Int(now.timeIntervalSince(date)))
    let ago = suffix ? " ago" : ""
    switch seconds {
    case ..<60: return "now"
    case ..<3600: return "\(seconds / 60)m\(ago)"
    case ..<86_400: return "\(seconds / 3600)h\(ago)"
    default: return "\(seconds / 86_400)d\(ago)"
    }
}
