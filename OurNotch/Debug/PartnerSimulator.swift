#if DEBUG
import SwiftUI

/// A stand-in for your love on this Mac, for testing without a second Mac. Debug builds only.
/// It has its own identity and local storage, and talks through the same mailbox as the notch.
@MainActor
final class PartnerSimulator {
    private let state = AppState(pairing: .devPartner,
                                 mailbox: LocalFileMailbox(),
                                 defaults: UserDefaults(suiteName: "OurNotch.PartnerSimulator")!)
    private var window: NSWindow?

    func show() {
        state.start()
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: PartnerSimulatorView(state: state)))
            window.title = "Partner Simulator"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}

private struct PartnerSimulatorView: View {
    let state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Acts as your love, on this Mac. Test tool only.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Button("Send ❤") { state.sendHeart() }
                Button("Send ❤ ×3") { (0..<3).forEach { _ in state.sendHeart() } }
            }

            Grid(alignment: .leading, verticalSpacing: 6) {
                GridRow {
                    Text("Hearts sent").foregroundStyle(.secondary)
                    Text("\(state.myOutbox.heartsSent)  \(state.heartStatus.label)")
                }
                GridRow {
                    Text("Hearts received").foregroundStyle(.secondary)
                    Text("\(state.lastShownHearts)")
                }
            }
            .monospacedDigit()
        }
        .padding(20)
        .frame(width: 320, alignment: .leading)
    }
}
#endif
