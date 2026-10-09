import SwiftUI

/// Everything from your love at a glance, as a bento: their photo (square), their latest note across
/// the top, and below it your time together and their mood. Each card opens its tab.
struct HomeTab: View {
    let state: AppState
    /// Opens another tab (a card was clicked).
    let go: (NotchTab) -> Void

    var body: some View {
        let side = Config.Notch.contentSize.height
        // Ticks every second, only while the notch is open on Home.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 10) {
                card(.photo, hint: String(localized: "Send \(state.partnerName.lowercased()) a photo back ♡"), leading: true) { photoTile(now: context.date) }.frame(width: side, height: side)
                VStack(spacing: 10) {
                    card(.note, hint: String(localized: "Read your whispers and whisper back ♡"), below: true) { noteTile(now: context.date) }.frame(height: (side - 10) * 0.56)
                    HStack(spacing: 10) {
                        card(.stats, hint: String(localized: "Every second counts ♡ Click for more")) { togetherTile(now: context.date) }
                        card(.mood, hint: String(localized: "Share your mood too ♡")) { moodTile(now: context.date) }.frame(width: 116)
                    }
                }
            }
        }
    }

    /// Tooltips sit above the cards, except the note's, which drops below it.
    private func card(_ tab: NotchTab, hint: String, below: Bool = false, leading: Bool = false,
                      @ViewBuilder _ content: () -> some View) -> some View {
        Button { go(tab) } label: { content() }
            .buttonStyle(CardButtonStyle())
            .notchHint(hint, below: below, leading: leading)
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
                Text(note.shown)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .tracking(-0.1)
                    .lineSpacing(2)
                    .lineLimit(2)
                    .foregroundStyle(.white)
            } else {
                Text("No whispers from \(state.partnerName.lowercased()) yet ♡")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondaryLabel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .tile()
    }

    // MARK: Together

    /// The seconds you've been together, counting up in pink, labelled underneath. More on the Stats tab.
    private func togetherTile(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.togetherSince.map { Together.seconds(since: $0, now: now).formatted() } ?? "…")
                .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                .tracking(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(state.togetherSince == nil ? Color.white : .notchPink)
            HStack(spacing: 4) {
                Text("seconds of us, and counting")
                Image(systemName: "heart.fill").font(.system(size: 9)).foregroundStyle(Color.notchPink).heartbeat()
            }
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(Color.secondaryLabel)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .tile()
    }

    // MARK: Mood

    /// A little widget, centred: "THEIR MOOD", their emoji big in a soft circle, its word underneath.
    /// While they've hidden OurNotch: a moon, and "away" (until when, if they said).
    private func moodTile(now: Date) -> some View {
        let away = state.partnerIsAway(now: now)
        let mood = away ? nil : state.partnerOutbox.mood
        return VStack(spacing: 6) {
            Text("Their mood")
                .textCase(.uppercase)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color.tertiaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            ZStack {
                Circle().fill(Color.notchField)
                if away {
                    Image(systemName: "moon.fill").font(.system(size: 17)).foregroundStyle(Color.notchBlush)
                } else if let mood {
                    Text(mood).font(.system(size: 24)).transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "heart").font(.system(size: 17, weight: .medium)).foregroundStyle(Color.tertiaryLabel)
                }
            }
            .frame(width: 40, height: 40)
            Text(away ? awayLabel : mood.flatMap(Config.moodLabel)?.lowercased() ?? String(localized: "not set"))
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(mood == nil && !away ? Color.secondaryLabel : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tile()
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: mood)
    }

    /// "away till 6:00 AM", or just "away" for "until I'm back".
    private var awayLabel: String {
        guard let until = state.partnerOutbox.awayUntil, until != .distantFuture else { return String(localized: "away") }
        return String(localized: "away till \(until.formatted(date: .omitted, time: .shortened))")
    }
}

private extension View {
    /// A Home tile: the same dark card as the other tabs.
    func tile() -> some View {
        background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Home's cards: the whole card is the button; it dips a little while pressed.
private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
