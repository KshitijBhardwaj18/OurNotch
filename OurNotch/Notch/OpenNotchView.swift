import SwiftUI

/// The expanded notch: time together counting up live, and the heart button.
struct OpenNotchView: View {
    let state: AppState
    let notchSize: CGSize

    var body: some View {
        VStack(spacing: 0) {
            // The top row sits beside the camera, which hides anything drawn behind it.
            Color.clear.frame(height: notchSize.height)

            HStack(alignment: .center) {
                timeTogether
                Spacer()
                heartButton
            }
            .padding(.horizontal, 18)
            .frame(maxHeight: .infinity)
        }
    }

    private var timeTogether: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Together.days(since: state.togetherSince))")
                    .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("days together")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            // Ticks every second, only while the notch is open.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.counter(Together.elapsed(since: state.togetherSince, now: context.date)))
                    .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.blush)
            }
        }
    }

    private var heartButton: some View {
        Button {
            // Sending a heart arrives in slice 2.
        } label: {
            Image(systemName: "heart.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.rose)
                .frame(width: 64, height: 64)
                .background(Color.rose.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private static func counter(_ c: DateComponents) -> String {
        String(format: "%dd %02dh %02dm %02ds", c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
