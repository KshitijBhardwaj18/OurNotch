import SwiftUI

/// The row beside the camera. Closed: days together and a heartbeat ♥. Open: the couple's names and the
/// Settings gear. Both layouts sit in the same row and crossfade, so nothing reflows mid-animation.
struct NotchHeaderView: View {
    let state: AppState
    let notchSize: CGSize
    let isOpen: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            closed.opacity(isOpen ? 0 : 1)
            open.opacity(isOpen ? 1 : 0).allowsHitTesting(isOpen)
        }
        .animation(.easeOut(duration: 0.2), value: isOpen)
    }

    private var closed: some View {
        HStack(spacing: 0) {
            Group {
                if let since = state.togetherSince {
                    Text("\(Together.days(since: since))")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.white)
                } else {
                    Text("♡").font(.system(size: 12)).foregroundStyle(Color.tertiaryLabel)
                }
            }
            .frame(width: Config.Notch.closedSideWidth)

            // Nothing drawn behind the camera is visible, so leave at least its width empty.
            Spacer(minLength: notchSize.width)

            Image(systemName: "heart.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.notchPink)
                .heartbeat()
                .frame(width: Config.Notch.closedSideWidth)
        }
    }

    private var open: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(state.myName.lowercased()).fixedSize()
                Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(Color.notchPink)
                Text(state.partnerName.lowercased()).lineLimit(1).truncationMode(.tail)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: 148, alignment: .leading)

            Spacer(minLength: notchSize.width)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondaryLabel)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle()) // the gear's center is a hole; make the whole square clickable
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 8) // + the shape's 14 pt ear inset = 22 pt from the edges
    }
}
