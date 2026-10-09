import SwiftUI

/// The Together tab: your life together in numbers, as six equal cards, the seconds counting up live in pink.
struct StatsTab: View {
    let state: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        // Ticks every second, only while the notch is open on Stats.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let since = state.togetherSince
            let height = (Config.Notch.contentSize.height - 10) / 2
            let value = { (compute: (Date) -> Int) in since.map { compute($0).formatted() } ?? "…" }

            LazyVGrid(columns: columns, spacing: 10) {
                card(value { Together.days(since: $0, now: context.date) }, "Days together").frame(height: height)
                card(value { Together.weekends(since: $0, now: context.date) }, "Weekends").frame(height: height)
                card(value { Together.hours(since: $0, now: context.date) }, "Hours").frame(height: height)
                card(value { Together.seconds(since: $0, now: context.date) }, "Seconds", pink: since != nil, heart: true)
                    .frame(height: height)
                card((state.myOutbox.emojisSent + state.partnerOutbox.emojisSent).formatted(), "Emojis between you",
                     detail: String(localized: "you \(state.myOutbox.emojisSent) · \(state.partnerName.lowercased()) \(state.partnerOutbox.emojisSent)"))
                    .frame(height: height)
                anniversary(since: since, now: context.date).frame(height: height)
            }
        }
    }

    @ViewBuilder private func anniversary(since: Date?, now: Date) -> some View {
        if let since {
            let days = Together.daysToAnniversary(since: since, now: now)
            if days == 0 {
                card("♡", "Happy anniversary!", pink: true)
            } else {
                card(days.formatted(), days == 1 ? "Day to your anniversary" : "Days to your anniversary")
            }
        } else {
            card("…", "Days to your anniversary")
        }
    }

    /// A number, its label underneath, and an optional small line below.
    private func card(_ value: String, _ label: LocalizedStringKey, detail: String? = nil, pink: Bool = false, heart: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                .tracking(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .foregroundStyle(pink ? Color.notchPink : .white)
            HStack(spacing: 4) {
                Text(label)
                if heart { Image(systemName: "heart.fill").font(.system(size: 9)).foregroundStyle(Color.notchPink).heartbeat() }
            }
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(Color.secondaryLabel)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            if let detail {
                Text(detail).font(.system(size: 10.5, weight: .medium)).foregroundStyle(Color.tertiaryLabel).lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
