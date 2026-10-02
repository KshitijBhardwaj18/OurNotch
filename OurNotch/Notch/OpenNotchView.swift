import SwiftUI

/// The part of the notch that grows below the header when it opens:
/// time together counting up live, and the heart button with its status.
struct OpenNotchView: View {
    let state: AppState
    let effects: HeartsEffect

    var body: some View {
        HStack(alignment: .center) {
            timeTogether
            Spacer()
            VStack(spacing: 4) {
                heartButton
                Text(state.heartStatus.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(height: 12)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity)
    }

    private var timeTogether: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("together for")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            // Ticks every second, only while the notch is open.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.counter(Together.elapsed(since: state.togetherSince, now: context.date)))
                    .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.blush)
            }
        }
    }

    private var heartButton: some View {
        Button {
            state.sendHeart()
            effects.pour()
        } label: {
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.rose)
                .frame(width: 56, height: 56)
                .background(Color.rose.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private static func counter(_ c: DateComponents) -> String {
        String(format: "%dd %02dh %02dm %02ds", c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
