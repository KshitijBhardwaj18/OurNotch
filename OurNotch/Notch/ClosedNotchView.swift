import SwiftUI

/// The always-visible notch: days together on the left of the camera, ♡ on the right.
struct ClosedNotchView: View {
    let state: AppState
    let notchSize: CGSize

    var body: some View {
        HStack(spacing: 0) {
            Text("\(Together.days(since: state.togetherSince))")
                .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: Config.Notch.closedSideWidth)

            // Nothing drawn behind the camera is visible, so leave it empty.
            Color.clear.frame(width: notchSize.width)

            Image(systemName: "heart.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.rose)
                .frame(width: Config.Notch.closedSideWidth)
        }
    }
}
