import SwiftUI

@main
struct OurNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("OurNotch", systemImage: "heart") {
            Button("Quit OurNotch") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

/// Owns the app state and the notch window.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private var panel: NotchPanel?
    private var geometry: NotchGeometry?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests run inside the app; they don't need a notch on screen.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        placeNotch()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.placeNotch() }
        }
    }

    /// Creates the notch window, or moves it when displays change. The notification fires
    /// often, so it only re-places when the notch geometry actually changed.
    private func placeNotch() {
        guard let newGeometry = NotchGeometry.current(), newGeometry != geometry else { return }
        geometry = newGeometry

        let panel = self.panel ?? NotchPanel(frame: newGeometry.panelFrame)
        let hostingView = NSHostingView(rootView: NotchView(state: state, geometry: newGeometry))
        hostingView.sizingOptions = [] // the window stays fixed; only the shape inside animates

        // Hidden while moving so the jump isn't visible.
        panel.alphaValue = 0
        panel.setFrame(newGeometry.panelFrame, display: false)
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        panel.alphaValue = 1
        self.panel = panel
    }
}
