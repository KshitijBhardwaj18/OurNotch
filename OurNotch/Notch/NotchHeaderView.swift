import SwiftUI

/// The row beside the camera. Closed: your love's little avatar and mood, and a heartbeat ♥. Open: the couple's names and the
/// Settings gear. Both layouts sit in the same row and crossfade, so nothing reflows mid-animation.
struct NotchHeaderView: View {
    let state: AppState
    let notchSize: CGSize
    let isOpen: Bool
    @Binding var showsSettings: Bool

    var body: some View {
        ZStack {
            closed.opacity(isOpen ? 0 : 1)
            open.opacity(isOpen ? 1 : 0).allowsHitTesting(isOpen)
        }
        .animation(.easeOut(duration: 0.2), value: isOpen)
    }

    private var closed: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                PartnerAvatar(state: state, size: 20)
                // "away" while my love has hidden their OurNotch; re-checked each minute so it clears on time.
                TimelineView(.everyMinute) { context in
                    if state.partnerIsAway(now: context.date) {
                        Text("away").font(.system(size: 10, weight: .medium)).foregroundStyle(Color.secondaryLabel)
                    } else if let mood = state.partnerOutbox.mood {
                        Text(mood).font(.system(size: 13)).transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: state.partnerOutbox.mood)
            .padding(.leading, Config.Notch.closedInset)
            .frame(width: Config.Notch.closedSideWidth, alignment: .leading)

            // Nothing drawn behind the camera is visible, so leave at least its width empty.
            Spacer(minLength: notchSize.width)

            Image(systemName: "heart.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.notchPink)
                .heartbeat()
                .padding(.trailing, Config.Notch.closedInset + 2)
                .frame(width: Config.Notch.closedSideWidth, alignment: .trailing)
        }
    }

    private var open: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(state.myName.lowercased()).lineLimit(1)
                Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(Color.notchPink)
                Text(state.partnerName.lowercased()).lineLimit(1).truncationMode(.tail)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            // At most 160 pt, so the names always end well before the camera.
            .frame(maxWidth: 160, alignment: .leading)

            // No minimum here: this row is laid out (invisibly) in the narrow closed notch too,
            // and must never be wider than it, or it pushes the closed row off-center.
            Spacer(minLength: 0)

            Button { showsSettings.toggle() } label: {
                Image(systemName: showsSettings ? "gearshape.fill" : "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(showsSettings ? Color.notchPink : .secondaryLabel)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle()) // the gear's center is a hole; make the whole square clickable
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, Config.Notch.margin) // the notch view already insets past the ears
    }
}

/// Your love's photo in a small circle, or their initial on pink until they've sent one.
struct PartnerAvatar: View {
    let state: AppState
    let size: CGFloat

    var body: some View {
        Group {
            if let photo = state.partnerPhoto {
                Image(nsImage: photo).resizable().scaledToFill()
            } else {
                Color.notchPink.overlay {
                    Text(state.partnerName.prefix(1).lowercased())
                        .font(.system(size: size * 0.55, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
    }
}
