import SwiftUI

/// A note sliding right to left across the strip just below the camera, like a marquee:
/// `nikki  hi babe how are you? love you`. It can't scroll *through* the notch: nothing drawn behind
/// the camera is visible.
struct MessageBanner: View {
    let message: Message
    let senderName: String
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
        // 18 pt fades on both edges so the text slides in and out softly.
        .mask {
            HStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing).frame(width: 18)
                Rectangle()
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: 18)
            }
        }
    }

    private var text: some View {
        (Text(senderName.lowercased()).foregroundColor(.notchPink).fontWeight(.semibold)
            + Text("  \(message.text)").foregroundColor(.white))
            .font(.system(size: 12, weight: .medium))
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
    }
}
