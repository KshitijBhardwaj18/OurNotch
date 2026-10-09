import SwiftUI
import UniformTypeIdentifiers

/// Send your love a photo; it shows on their Home until you send a new one.
struct PhotoTab: View {
    let state: AppState

    @State private var isWorking = false
    @State private var failed = false

    var body: some View {
        HStack(spacing: 16) {
            tile.frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 3) {
                eyebrow.font(.system(size: 11, weight: .medium))
                Text(state.myPhoto == nil ? "Send \(partner) a photo" : "Last sent to \(partner)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(state.myPhoto == nil ? "It shows up on their Home the next time they open their notch ♡"
                                          : "Shows on their Home until you send a new one ♡")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                Button(state.myPhoto == nil ? "Choose Photo…" : "Send New Photo…", action: choose)
                    .buttonStyle(NotchButtonStyle(prominent: state.myPhoto == nil))
                    .disabled(isWorking)
                    .padding(.top, 10)
            }
        }
        .frame(maxHeight: .infinity)
        .cardStyle(tint: .pastelButter)
    }

    private var partner: String { state.partnerName.lowercased() }

    @ViewBuilder private var tile: some View {
        if let photo = state.myPhoto {
            TreatedPhoto(image: photo)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.tertiaryLabel, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .overlay {
                    Image(systemName: "photo.badge.plus").font(.system(size: 26)).foregroundStyle(Color.tertiaryLabel)
                }
        }
    }

    /// "Photo", or "2h ago · Delivered ♡" once one is sent.
    @ViewBuilder private var eyebrow: some View {
        if failed {
            Text("Couldn't send that photo. Try another ♡").foregroundStyle(Color.notchPink)
        } else if isWorking {
            Text("Sending…").foregroundStyle(Color.secondaryLabel)
        } else if let sent = state.myOutbox.photo {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text("\(shortAgo(sent.sentAt, now: context.date).capitalizedFirst) · \(state.photoStatus.label)")
            }
            .foregroundStyle(state.photoStatus == .delivered ? Color.notchPink : .secondaryLabel)
        } else {
            Text("Photo").foregroundStyle(Color.secondaryLabel)
        }
    }

    private func choose() {
        choosePhoto { url in
            isWorking = true
            failed = false
            Task {
                defer { isWorking = false }
                guard let jpeg = try? PhotoProcessing.squareJPEG(from: url) else { failed = true; return }
                failed = !(await state.sendPhoto(jpeg))
            }
        }
    }
}

/// Opens the Mac's file picker for one image. Shared with the Partner Simulator.
@MainActor
func choosePhoto(_ chosen: @escaping (URL) -> Void) {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false
    panel.message = "Choose a photo for your love"
    NSApp.activate()
    panel.begin { response in
        if response == .OK, let url = panel.url { chosen(url) }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

/// Small native-style button inside the notch: prominent pink or bordered.
struct NotchButtonStyle: ButtonStyle {
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration, prominent: prominent)
    }

    private struct StyledButton: View {
        let configuration: Configuration
        let prominent: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(fill, in: RoundedRectangle(cornerRadius: 6))
                .opacity(isEnabled ? 1 : 0.4)
        }

        private var fill: Color {
            if prominent { return configuration.isPressed ? .notchPinkPressed : .notchPink }
            return .white.opacity(configuration.isPressed ? 0.2 : 0.14)
        }
    }
}
