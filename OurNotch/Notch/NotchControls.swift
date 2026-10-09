import SwiftUI

enum NotchTab: CaseIterable {
    case home, note, emoji, mood, photo, stats

    var label: String {
        switch self {
        case .home: String(localized: "Home")
        case .note: String(localized: "Note")
        case .emoji: String(localized: "Emoji")
        case .mood: String(localized: "Mood")
        case .photo: String(localized: "Photo")
        case .stats: String(localized: "Stats")
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .note: "bubble.left"
        case .emoji: "face.smiling"
        case .mood: "cloud.sun"
        case .photo: "photo"
        case .stats: "chart.bar"
        }
    }

    /// The tab bar's hover tooltip.
    var hint: String {
        switch self {
        case .home: String(localized: "Everything from your love, at a glance")
        case .note: String(localized: "Your little notes to each other")
        case .emoji: String(localized: "Send a little burst of love")
        case .mood: String(localized: "How you're both feeling")
        case .photo: String(localized: "A photo for their Home")
        case .stats: String(localized: "Your life together, in numbers")
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
                .notchHint(tab.hint)
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

/// A small tooltip pill above a view, shown after a short hover. The notch belongs to a background app,
/// and macOS only shows its own tooltips (`.help`) for the app in front, so the notch draws its own.
struct NotchHint: ViewModifier {
    let text: String
    /// Which edge the pill lines up with; views at the notch's sides keep theirs inside it.
    var edge: HorizontalAlignment = .center
    @State private var shown = false
    @State private var wait: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onHover { inside in
                wait?.cancel()
                guard inside else { withAnimation(.easeOut(duration: 0.12)) { shown = false }; return }
                wait = Task {
                    try? await Task.sleep(for: .milliseconds(550))
                    guard !Task.isCancelled else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { shown = true }
                }
            }
            .overlay(alignment: Alignment(horizontal: edge, vertical: .top)) {
                if shown {
                    Text(text)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.notchPressed, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                        .fixedSize()
                        .offset(y: -30)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
                        .allowsHitTesting(false)
                }
            }
            .zIndex(shown ? 10 : 0)
    }
}

extension View {
    func heartbeat() -> some View { modifier(Heartbeat()) }

    /// A cute tooltip for anything in the notch (see `NotchHint`).
    func notchHint(_ text: String, edge: HorizontalAlignment = .center) -> some View { modifier(NotchHint(text: text, edge: edge)) }

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
