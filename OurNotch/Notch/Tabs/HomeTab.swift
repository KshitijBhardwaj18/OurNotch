import SwiftUI

/// Everything from your love at a glance, as a bento: their photo (square), their latest note across
/// the top, and below it your time together and their mood.
struct HomeTab: View {
    let state: AppState

    var body: some View {
        let side = Config.Notch.contentSize.height
        // Ticks every second, only while the notch is open on Home.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 10) {
                photoTile(now: context.date).frame(width: side, height: side)
                VStack(spacing: 10) {
                    noteTile(now: context.date).frame(height: (side - 10) * 0.56)
                    HStack(spacing: 10) {
                        togetherTile(now: context.date)
                        moodTile.frame(width: 110)
                    }
                }
            }
        }
    }

    // MARK: Photo

    /// A square tile as tall as the content area.
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

    /// Pip and Bun keep the space warm until the first photo arrives.
    private var emptyPhotoTile: some View {
        VStack(spacing: 10) {
            HStack(spacing: -6) {
                Image("pip-happy").resizable().scaledToFit().frame(width: 64)
                Image("bun-happy").resizable().scaledToFit().frame(width: 64)
            }
            .opacity(0.85)
            Text("No photo from \(state.partnerName.lowercased()) yet")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tile()
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
                    .lineLimit(2)
                    .foregroundStyle(.white)
            } else {
                Text("No notes from \(state.partnerName.lowercased()) yet ♡")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondaryLabel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .tile()
    }

    // MARK: Together

    /// The seconds you've been together, counting up in pink, with hours and weekends underneath.
    private func togetherTile(now: Date) -> some View {
        let since = state.togetherSince
        func value(_ compute: (Date) -> Int) -> String { since.map { compute($0).formatted() } ?? "…" }

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text("Seconds")
                Image(systemName: "heart.fill").font(.system(size: 9)).foregroundStyle(Color.notchPink).heartbeat()
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.secondaryLabel)
            Text(value { Together.seconds(since: $0, now: now) })
                .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                .tracking(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(since == nil ? Color.white : .notchPink)
            HStack(spacing: 12) {
                small(value { Together.hours(since: $0, now: now) }, "Hours")
                small(value { Together.weekends(since: $0, now: now) }, "Weekends")
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .tile()
    }

    private func small(_ value: String, _ label: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value).font(.system(size: 12.5, weight: .semibold, design: .rounded).monospacedDigit()).foregroundStyle(.white)
            Text(label).font(.system(size: 10.5, weight: .medium)).foregroundStyle(Color.secondaryLabel)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    // MARK: Mood

    /// Their mood, big: the emoji with its word, or a quiet heart when they haven't set one.
    private var moodTile: some View {
        VStack(spacing: 4) {
            if let mood = state.partnerOutbox.mood {
                Text(mood).font(.system(size: 30))
                Text((Config.moodLabel(mood) ?? "").lowercased())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Image(systemName: "heart").font(.system(size: 22)).foregroundStyle(Color.notchBlush)
                Text("No mood").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.secondaryLabel)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tile()
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: state.partnerOutbox.mood)
    }
}

private extension View {
    /// A Home tile: the same dark card as the other tabs.
    func tile() -> some View {
        background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
