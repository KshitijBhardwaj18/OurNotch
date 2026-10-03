import CloudKit
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
            Button("Save Diagnostics") { appDelegate.saveDiagnostics() }
            Divider()
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
        Diagnostics.shared.record(Self.launchSummary)

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
            MainActor.assumeIsolated {
                Diagnostics.shared.record("Mac woke")
                self?.syncEveryone(.wake)
            }
        }
        NSApp.registerForRemoteNotifications()
    }

    // MARK: Pings

    /// CloudKit's silent ping: the partner's row changed.
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        let subscription = CKNotification(fromRemoteNotificationDictionary: userInfo)?.subscriptionID ?? "unknown"
        Diagnostics.shared.record("ping received (subscription \(subscription))")
        syncEveryone(.ping)
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Only the last few characters: enough to tell devices apart, not enough to reuse.
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Diagnostics.shared.record("registered for pings (token …\(token.suffix(6)))")
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Diagnostics.shared.record("ping registration FAILED: \(error.diagnosticDescription)")
    }

    private func syncEveryone(_ source: SyncSource) {
        state?.syncNow(source)
        #if DEBUG
        partnerSimulator.syncNow(source)
        #endif
    }

    // MARK: Diagnostics

    /// "OurNotch 0.1 (1) Release · macOS 26.6.2 · Mac16,12 · notch 179×32 · checks every 10 s"
    private static var launchSummary: String {
        let info = Bundle.main.infoDictionary
        let version = "\(info?["CFBundleShortVersionString"] ?? "?") (\(info?["CFBundleVersion"] ?? "?"))"
        #if DEBUG
        let build = "Debug"
        #else
        let build = "Release"
        #endif
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let geometry = NotchGeometry.current()
        let screen = geometry.map { "\($0.hasNotch ? "notch" : "no notch, pill") \(Int($0.notchSize.width))×\(Int($0.notchSize.height))" } ?? "no screen"
        return "launched OurNotch \(version) \(build) · macOS \(ProcessInfo.processInfo.operatingSystemVersionString) · \(String(cString: model)) · \(screen) · checks every \(Config.Cloud.pollInterval)"
    }

    /// Downloads both Macs' logs into ~/Library/Logs/OurNotch/ and shows them in Finder.
    func saveDiagnostics() {
        Task {
            let folder = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Logs/OurNotch")
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try? Data(Diagnostics.shared.text.utf8).write(to: folder.appending(path: "this-mac.log"))
            if let partnerId = state?.pairing.partnerId {
                let partnerLog = (try? await mailbox.fetchDiagnostics(owner: partnerId)) ?? "(no log uploaded yet)"
                try? Data(partnerLog.utf8).write(to: folder.appending(path: "partner-mac.log"))
            }
            NSWorkspace.shared.activateFileViewerSelecting([folder.appending(path: "this-mac.log")])
        }
    }

    /// Starts syncing and shows the notch. Returns false if this Mac isn't paired yet.
    @discardableResult
    private func startNotch() -> Bool {
        guard let state = AppState(store: store, mailbox: mailbox) else { return false }
        state.onEmojisArrived = { [effects] count, emoji in effects.play(newCount: count, emoji: emoji) }
        state.start()
        Diagnostics.shared.startUploading(owner: state.pairing.myId, mailbox: mailbox)
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
