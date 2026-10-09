import SwiftUI

enum NotchTab: CaseIterable {
    case home, note, emoji, mood, photo

    var label: String {
        switch self {
        case .home: String(localized: "Home")
        case .note: String(localized: "Note")
        case .emoji: String(localized: "Emoji")
        case .mood: String(localized: "Mood")
        case .photo: String(localized: "Photo")
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
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(selected ? Color.pastelInk : .secondaryLabel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if selected { Capsule().fill(Color.pastelBlush) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .frame(width: CGFloat(NotchTab.allCases.count) * 76, height: 30)
        .background(Color.white.opacity(0.08), in: Capsule())
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
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? Color.white : .pastelInk)
                    .padding(.horizontal, 10)
                    .frame(height: 22)
                    .background {
                        if selected { Capsule().fill(Color.pastelInk) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(.white.opacity(0.75), in: Capsule())
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

    /// The pastel page that holds a tab, like the website's cards: cream fading into the tab's colour.
    func pastelCard(_ color: Color) -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(LinearGradient(colors: [.pastelCream, color], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .environment(\.colorScheme, .light)
    }

    /// A tab's title, in the website's rounded heavy type.
    func pastelTitle() -> some View {
        font(.system(size: 16, weight: .heavy, design: .rounded)).tracking(-0.3).foregroundStyle(Color.pastelInk)
    }
}

/// "now", "2m ago", "1h ago", "3d ago", or "2m", "1h", "3d" without the suffix.
func shortAgo(_ date: Date, now: Date = .now, suffix: Bool = true) -> String {
    let seconds = max(0, Int(now.timeIntervalSince(date)))
    switch (seconds, suffix) {
    case (..<60, _): return String(localized: "now")
    case (..<3600, true): return String(localized: "\(seconds / 60)m ago")
    case (..<3600, false): return String(localized: "\(seconds / 60)m")
    case (..<86_400, true): return String(localized: "\(seconds / 3600)h ago")
    case (..<86_400, false): return String(localized: "\(seconds / 3600)h")
    case (_, true): return String(localized: "\(seconds / 86_400)d ago")
    case (_, false): return String(localized: "\(seconds / 86_400)d")
    }
}
