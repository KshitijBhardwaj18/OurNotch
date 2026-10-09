import SwiftUI

enum NotchTab: CaseIterable {
    case home, stats, note, emoji, mood, photo

    var label: String {
        switch self {
        case .home: String(localized: "Home")
        case .note: String(localized: "Whispers")
        case .emoji: String(localized: "Emoji")
        case .mood: String(localized: "Mood")
        case .photo: String(localized: "Photo")
        case .stats: String(localized: "Together")
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .note: "bubble.left"
        case .emoji: "face.smiling"
        case .mood: "cloud.sun"
        case .photo: "photo"
        case .stats: "infinity.circle"
        }
    }

}

/// The tab bar at the bottom of the open notch: each tab is an icon with its name underneath, so it's
/// always clear what it does; the chosen one sits on a soft pill (sliding between tabs) with a pink icon.
struct NotchTabBar: View {
    @Binding var selection: NotchTab
    /// True while Settings covers the tabs, so no tab looks selected.
    var dimmed = false
    @State private var hovered: NotchTab?
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 2) {
            ForEach(NotchTab.allCases, id: \.self) { tab in
                let selected = tab == selection && !dimmed
                Button { selection = tab } label: {
                    VStack(spacing: 2) {
                        Image(systemName: selected ? "\(tab.symbol).fill" : tab.symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selected ? Color.notchPink : hovered == tab ? .white : .secondaryLabel)
                            .frame(height: 17)
                        Text(tab.label)
                            .font(.system(size: 10, weight: selected ? .semibold : .medium, design: .rounded))
                            .foregroundStyle(selected ? Color.white : hovered == tab ? .white : .secondaryLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 70, height: 40)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.12))
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // The icon-only tabs still have a name (not the symbol's, like "Chart Column").
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(.isButton)
                .onHover { hovered = $0 ? tab : (hovered == tab ? nil : hovered) }
            }
        }
        .padding(3)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).strokeBorder(.white.opacity(0.06), lineWidth: 0.5))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selection)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dimmed)
        .animation(.easeOut(duration: 0.12), value: hovered)
    }
}

/// The little choice chips used for "Scroll", "Appears" and in Settings: separate rounded chips,
/// the chosen one in solid pink, the others quiet until hovered.
struct SmallSegmented<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var symbol: ((Option) -> String)? = nil
    @State private var hovered: Option?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button { selection = option } label: {
                    HStack(spacing: 5) {
                        if let symbol { Image(systemName: symbol(option)).font(.system(size: 10.5, weight: .bold)) }
                        Text(label(option))
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? Color.white : hovered == option ? .white.opacity(0.85) : .secondaryLabel)
                    .padding(.horizontal, 12)
                    .frame(height: 26)
                    .background(selected ? Color.notchPink : hovered == option ? .notchPressed : .notchField, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hovered = $0 ? option : (hovered == option ? nil : hovered) }
            }
        }
        .animation(.snappy(duration: 0.2), value: selection)
        .animation(.easeOut(duration: 0.12), value: hovered)
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

/// A cute tooltip for Home's cards. macOS shows `.help` tooltips only for the app in front,
/// and the notch belongs to a background app, so the notch draws its own: after a short hover the view
/// asks for a pill, and `OpenNotchView` draws it on top of everything (see `HintLayer`).
struct NotchHint: ViewModifier {
    let text: String
    var below = false
    var leading = false
    @State private var shown = false
    @State private var wait: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onHover { inside in
                wait?.cancel()
                guard inside else { shown = false; return }
                wait = Task {
                    try? await Task.sleep(for: .milliseconds(550))
                    if !Task.isCancelled { shown = true }
                }
            }
            .anchorPreference(key: HintKey.self, value: .bounds) { shown ? Hint(text: text, bounds: $0, below: below, leading: leading) : nil }
    }
}

struct Hint: Equatable {
    let text: String
    let bounds: Anchor<CGRect>
    /// Above the view unless asked; `leading` lines it up with the view's left edge.
    let below: Bool
    let leading: Bool
}

struct HintKey: PreferenceKey {
    static let defaultValue: Hint? = nil
    static func reduce(value: inout Hint?, nextValue: () -> Hint?) { value = nextValue() ?? value }
}

/// Draws the hovered view's hint above it (or below, if asked), always inside the notch's sides.
struct HintLayer: View {
    let hint: Hint?

    var body: some View {
        GeometryReader { box in
            if let hint {
                let rect = box[hint.bounds]
                let width = min(box.size.width - 8, CGFloat(hint.text.count) * 6.4 + 22) // close enough to centre it
                Text(hint.text)
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.notchPressed, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
                    .fixedSize()
                    .position(x: min(max(hint.leading ? rect.minX + width / 2 : rect.midX, width / 2 + 4), box.size.width - width / 2 - 4),
                              y: hint.below ? rect.maxY : rect.minY) // centred on the card's edge, clear of the names row
                    .transition(.opacity)
                    .id(hint.text)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.15), value: hint?.text)
    }
}

extension View {
    func heartbeat() -> some View { modifier(Heartbeat()) }

    /// A cute tooltip for anything in the notch (see `NotchHint`).
    func notchHint(_ text: String, below: Bool = false, leading: Bool = false) -> some View {
        modifier(NotchHint(text: text, below: below, leading: leading))
    }

    /// The dark `#1C1C1E` card that holds a tab. Neutral, so it's easy on the eyes in a dark room;
    /// pink is kept for what matters (your notes, the send heart, the counter, a selection).
    func cardStyle() -> some View {
        padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
