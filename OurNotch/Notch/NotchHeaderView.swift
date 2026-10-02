import SwiftUI

/// The row beside the camera: days together on the left, ♡ on the right.
/// Closed, it is the whole notch. Open, the same row stretches wider and the rest of the notch grows below it,
/// so it never has to be swapped out mid-animation.
struct NotchHeaderView: View {
    let state: AppState
    let notchSize: CGSize

    var body: some View {
        HStack(spacing: 0) {
            Text("\(Together.days(since: state.togetherSince))")
                .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: Config.Notch.closedSideWidth)

            // Nothing drawn behind the camera is visible, so leave at least its width empty.
            Spacer(minLength: notchSize.width)

            Image(systemName: "heart.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.rose)
                .frame(width: Config.Notch.closedSideWidth)
        }
    }
}
