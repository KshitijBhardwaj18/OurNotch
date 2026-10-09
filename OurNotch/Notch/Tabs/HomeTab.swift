import SwiftUI

/// Everything from your love at a glance: their photo, their latest note, and time together.
struct HomeTab: View {
    let state: AppState

    static let photoWidth: CGFloat = 210

    var body: some View {
        // Ticks every second, only while the notch is open on Home.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 10) {
                photoTile(now: context.date)
                    .frame(width: Self.photoWidth, height: Config.Notch.contentSize.height)
                VStack(spacing: 10) {
                    noteTile(now: context.date)
                    togetherTile(now: context.date)
                }
            }
        }
    }

    // MARK: Photo

    /// A portrait tile as tall as the content area; people photos look best tall.
    @ViewBuilder private func photoTile(now: Date) -> some View {
        if let photo = state.partnerPhoto {
            TreatedPhoto(image: photo, cornerRadius: 16)
                .overlay {
                    // Darkens the bottom half so the caption stays readable on any photo.
                    LinearGradient(stops: [.init(color: .clear, location: 0.5), .init(color: .black.opacity(0.55), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .overlay(alignment: .bottomLeading) {
                    Group {
                        if let photo = state.partnerOutbox.photo {
                            Text("from \(state.partnerName.lowercased()) · \(shortAgo(photo.sentAt, now: now, suffix: false))")
                        } else {
                            Text("from \(state.partnerName.lowercased())")
                        }
                    }
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
        .background(Color.pastelButter.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .tracking(-0.1)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .foregroundStyle(.white)
            } else {
                Text("No notes from \(state.partnerName.lowercased()) yet ♡")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondaryLabel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.pastelBlush.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Together

    /// The seconds you've been together, counting up in pink, with hours and weekends underneath.
    private func togetherTile(now: Date) -> some View {
        let since = state.togetherSince
        func value(_ compute: (Date) -> Int) -> String { since.map { compute($0).formatted() } ?? "…" }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Seconds")
                Image(systemName: "heart.fill").font(.system(size: 9)).foregroundStyle(Color.notchPink).heartbeat()
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.secondaryLabel)
            Text(value { Together.seconds(since: $0, now: now) })
                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                .tracking(-0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(since == nil ? Color.white : .notchPink)
            HStack(spacing: 14) {
                small(value { Together.hours(since: $0, now: now) }, "Hours")
                small(value { Together.weekends(since: $0, now: now) }, "Weekends")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.pastelMint.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func small(_ value: String, _ label: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value).font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit()).foregroundStyle(.white)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(Color.secondaryLabel)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}
