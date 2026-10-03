import os
import SwiftUI

@main
struct OurNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("OurNotch", systemImage: "heart") {
            #if DEBUG
            Button("Partner Simulator…") { appDelegate.partnerSimulator.show() }
            Button("Reset Everything (test)") { appDelegate.resetForTesting() }
            Divider()
            #endif
            Button("Quit OurNotch") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

/// Shows onboarding until this Mac is paired, then owns the app state, the heart effects, and the notch window.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let effects = EmojiEffect()
    #if DEBUG
    let partnerSimulator = PartnerSimulator()
    #endif
    static let keychainService = "OurNotch"
    private let store = LocalStore(defaults: .standard, keychainService: AppDelegate.keychainService)
    private let mailbox = CloudStore()
    private var state: AppState?
    private var panel: NotchPanel?
    private var geometry: NotchGeometry?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests run inside the app; they don't need a notch on screen.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        if !startNotch() { showOnboarding() }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.placeNotch() }
        }
        // A Mac that slept may have missed pings; check as soon as it wakes.
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.syncEveryone() }
        }
        NSApp.registerForRemoteNotifications()
    }

    // MARK: Pings

    /// CloudKit's silent ping: the partner's row changed.
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        syncEveryone()
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger(subsystem: "OurNotch", category: "cloud").error("No pings: \(error.localizedDescription, privacy: .public)")
    }

    private func syncEveryone() {
        state?.syncNow()
        #if DEBUG
        partnerSimulator.syncNow()
        #endif
    }

    /// Starts syncing and shows the notch. Returns false if this Mac isn't paired yet.
    @discardableResult
    private func startNotch() -> Bool {
        guard let state = AppState(store: store, mailbox: mailbox) else { return false }
        state.onEmojisArrived = { [effects] count, emoji in effects.play(newCount: count, emoji: emoji) }
        state.start()
        self.state = state
        placeNotch()
        return true
    }

    // MARK: Onboarding

    /// A regular window that needs typing, so the app briefly becomes a regular app (Dock icon, ⌘-Tab).
    private func showOnboarding() {
        let model = OnboardingModel(store: store, mailbox: mailbox) { [weak self] in self?.finishOnboarding() }
        let window = NSWindow(contentViewController: NSHostingController(rootView: OnboardingView(model: model)))
        window.title = "Welcome to OurNotch"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        onboardingWindow = window

        // Closing setup before pairing quits; there's nothing to show in the notch yet.
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                if self?.state == nil { NSApp.terminate(nil) }
            }
        }

        NSApp.setActivationPolicy(.regular)
        window.showInFront()
    }

    private func finishOnboarding() {
        startNotch()
        onboardingWindow?.close()
        onboardingWindow = nil
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: Notch window

    /// Creates the notch window, or moves it when displays change. The notification fires
    /// often, so it only re-places when the notch geometry actually changed.
    private func placeNotch() {
        guard let state, let newGeometry = NotchGeometry.current(), newGeometry != geometry else { return }
        geometry = newGeometry

        let panel = self.panel ?? NotchPanel(frame: newGeometry.panelFrame)
        let hostingView = NSHostingView(rootView: NotchView(state: state, effects: effects, geometry: newGeometry))
        hostingView.sizingOptions = [] // the window stays fixed; only the shape inside animates

        // Hidden while moving so the jump isn't visible.
        panel.alphaValue = 0
        panel.setFrame(newGeometry.panelFrame, display: false)
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        panel.alphaValue = 1
        self.panel = panel
    }

    #if DEBUG
    /// Forgets both identities (settings, keys, cached photos), then quits, so the next launch is a fresh
    /// install. Old records stay in CloudKit; new identities never read them.
    func resetForTesting() {
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        UserDefaults.standard.removePersistentDomain(forName: PartnerSimulator.suiteName)
        Keychain.delete(service: AppDelegate.keychainService)
        Keychain.delete(service: PartnerSimulator.suiteName)
        try? FileManager.default.removeItem(at: PhotoCache.defaultRoot)
        NSApp.terminate(nil)
    }
    #endif
}

extension NSWindow {
    /// Shows a window on whichever desktop (Space) the user is on, in front. OurNotch has no Dock icon,
    /// so without this a window can open on another desktop where the user never sees it.
    func showInFront() {
        collectionBehavior.insert(.moveToActiveSpace)
        NSApp.activate()
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()
    }
}
