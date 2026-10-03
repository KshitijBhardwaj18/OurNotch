import SwiftUI

/// Everything from your love at a glance: their photo, their latest note, and time together.
struct HomeTab: View {
    let state: AppState

    static let photoWidth: CGFloat = 160

    var body: some View {
        // Ticks every second, only while the notch is open on Home.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 10) {
                photoTile(now: context.date)
                    .frame(width: Self.photoWidth, height: Config.Notch.contentSize.height)
                VStack(spacing: 10) {
                    noteTile(now: context.date)
                    stats(now: context.date)
                }
            }
        }
    }

    // MARK: Photo

    /// A portrait tile as tall as the content area; people photos look best tall.
    @ViewBuilder private func photoTile(now: Date) -> some View {
        if let photo = state.partnerPhoto {
            TreatedPhoto(image: photo, cornerRadius: 14)
                .overlay {
                    // Darkens the bottom half so the caption stays readable on any photo.
                    LinearGradient(stops: [.init(color: .clear, location: 0.5), .init(color: .black.opacity(0.55), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .overlay(alignment: .bottomLeading) {
                    Text("from \(state.partnerName.lowercased())" + (state.partnerOutbox.photo.map { " · \(shortAgo($0.sentAt, now: now, suffix: false))" } ?? ""))
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                }
        } else {
            emptyPhotoTile
        }
    }

    private var emptyPhotoTile: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo").font(.system(size: 30)).foregroundStyle(Color.tertiaryLabel)
            Text("No photo from \(state.partnerName.lowercased()) yet")
                .font(.system(size: 12))
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    /// Hours · Weekends · Seconds at a width ratio of 1.2 : 1 : 1.9, sized so each big number fits.
    private func stats(now: Date) -> some View {
        let since = state.togetherSince
        func value(_ compute: (Date) -> Int) -> String { since.map { compute($0).formatted() } ?? "—" }

        return GeometryReader { row in
            let unit = (row.size.width - 20) / 4.1
            HStack(spacing: 10) {
                statTile("Hours", value { Together.hours(since: $0, now: now) })
                    .frame(width: unit * 1.2)
                statTile("Weekends", value { Together.weekends(since: $0, now: now) })
                    .frame(width: unit)
                statTile("Seconds", value { Together.seconds(since: $0, now: now) },
                         highlighted: since != nil, withHeart: true)
                    .frame(width: unit * 1.9)
            }
        }
    }

    /// A big centered number with its label underneath.
    private func statTile(_ label: String, _ value: String, highlighted: Bool = false, withHeart: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold).monospacedDigit())
                .tracking(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(highlighted ? Color.notchPink : .white)
            HStack(spacing: 4) {
                Text(label)
                if withHeart {
                    Image(systemName: "heart.fill").font(.system(size: 9)).foregroundStyle(Color.notchPink).heartbeat()
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.secondaryLabel)
            .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 12))
    }
}
