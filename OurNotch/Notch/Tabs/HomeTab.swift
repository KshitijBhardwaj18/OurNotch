import SwiftUI

/// Everything from your love at a glance: their photo, their latest note, and time together.
struct HomeTab: View {
    let state: AppState

    static let photoWidth: CGFloat = 180

    var body: some View {
        // Ticks every second, only while the notch is open on Home.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 10) {
                photoTile
                VStack(spacing: 10) {
                    noteTile(now: context.date)
                    stats(now: context.date)
                }
            }
        }
    }

    // MARK: Photo

    /// A portrait tile as tall as the content area; people photos look best tall. Empty until photos arrive in slice 6.
    private var photoTile: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo").font(.system(size: 30)).foregroundStyle(Color.tertiaryLabel)
            Text("No photo from \(state.partnerName.lowercased()) yet")
                .font(.system(size: 12))
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(width: Self.photoWidth, height: Config.Notch.contentSize.height)
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Note

    private func noteTile(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let note = state.partnerOutbox.message {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill").font(.system(size: 12)).foregroundStyle(Color.notchPink)
                    Text("\(state.partnerName.lowercased()) · \(shortAgo(note.sentAt, now: now))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondaryLabel)
                }
                Text(note.text)
                    .font(.system(size: 15, weight: .medium))
                    .tracking(-0.1)
                    .lineSpacing(2)
                    .lineLimit(2)
                    .foregroundStyle(.white)
            } else {
                Text("No notes from \(state.partnerName.lowercased()) yet ♡")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondaryLabel)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Stats

    /// Hours · Weekends · Seconds at a width ratio of 1 : 1 : 1.8, so every label and number fits at full size.
    private func stats(now: Date) -> some View {
        let since = state.togetherSince
        func value(_ compute: (Date) -> Int) -> String { since.map { compute($0).formatted() } ?? "—" }

        return GeometryReader { row in
            let unit = (row.size.width - 20) / 3.8
            HStack(spacing: 10) {
                statTile("Hours", value { Together.hours(since: $0, now: now) })
                    .frame(width: unit)
                statTile("Weekends", value { Together.weekends(since: $0, now: now) })
                    .frame(width: unit)
                statTile("Seconds", value { Together.seconds(since: $0, now: now) },
                         highlighted: since != nil, withHeart: true)
                    .frame(width: unit * 1.8)
            }
        }
    }

    private func statTile(_ label: String, _ value: String, highlighted: Bool = false, withHeart: Bool = false) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Text(label)
                if withHeart {
                    Image(systemName: "heart.fill").font(.system(size: 10)).foregroundStyle(Color.notchPink).heartbeat()
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.secondaryLabel)
            .lineLimit(1)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                .tracking(-0.3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(highlighted ? Color.notchPink : .white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 12))
    }
}
