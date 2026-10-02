import SwiftUI

/// A message sliding right to left across the strip just below the camera, like a marquee.
/// It can't scroll *through* the notch: nothing drawn behind the camera is visible.
struct MessageBanner: View {
    let message: Message
    /// Called after the third pass for `.three`; never for `.untilOpened`.
    let onFinished: () -> Void

    @State private var textWidth: CGFloat = 0
    @State private var start = Date.now

    var body: some View {
        GeometryReader { strip in
            // Position is computed from elapsed time each frame, so the motion stays perfectly linear.
            TimelineView(.animation) { context in
                let travel = strip.size.width + textWidth
                let distance = context.date.timeIntervalSince(start) * Config.Message.bannerSpeed
                text.offset(x: strip.size.width - distance.truncatingRemainder(dividingBy: max(travel, 1)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .task(id: textWidth) {
                guard message.mode == .three, textWidth > 0 else { return }
                let onePass = (strip.size.width + textWidth) / Config.Message.bannerSpeed
                let remaining = onePass * 3 - Date.now.timeIntervalSince(start)
                try? await Task.sleep(for: .seconds(max(0, remaining)))
                if !Task.isCancelled { onFinished() }
            }
        }
        // Soft edges so the text fades in and out instead of being cut off.
        .mask(LinearGradient(stops: [.init(color: .clear, location: 0),
                                     .init(color: .black, location: 0.1),
                                     .init(color: .black, location: 0.9),
                                     .init(color: .clear, location: 1)],
                             startPoint: .leading, endPoint: .trailing))
    }

    private var text: some View {
        Text(message.text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
    }
}
