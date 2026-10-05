import CloudKit
import os
import Sparkle
import SwiftUI

@main
struct OurNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("OurNotch", systemImage: "heart.fill") {
            if appDelegate.menu.isPaired {
                if appDelegate.menu.isHidden {
                    Button("Show OurNotch") { appDelegate.state?.show() }
                } else {
                    Menu("Hide OurNotch") {
                        ForEach(Hide.allCases, id: \.self) { choice in
                            Button(choice.label) { appDelegate.state?.hide(until: choice.until()) }
                        }
                    }
                }
                Divider()
            }
            #if DEBUG
            Button("Partner Simulator…") { appDelegate.partnerSimulator.show() }
            Button("Reset Everything (test)") { appDelegate.resetForTesting() }
            Divider()
            #endif
            if appDelegate.updates.canCheck {
                Button("Check for Updates…") { appDelegate.updates.check() }
            }
            Button("Save Diagnostics") { appDelegate.saveDiagnostics() }
            Divider()
            Button("Quit OurNotch") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

/// What the ♡ menu shows, observed by the menu.
@MainActor
@Observable
final class MenuState {
    var isPaired = false
    var isHidden = false
}

/// Shows onboarding until this Mac is paired, then owns the app state, the heart effects, and the notch window.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let menu = MenuState()
    let updates = Updates()
    let effects = EmojiEffect()
    #if DEBUG
    let partnerSimulator = PartnerSimulator()
    #endif
    static let keychainService = "OurNotch"
    private let store: LocalStore = {
        if let name = Profile.storageName {
            return LocalStore(defaults: UserDefaults(suiteName: name)!, keychainService: name)
        }
        return LocalStore(defaults: .standard, keychainService: AppDelegate.keychainService)
    }()
    private let mailbox = CloudStore()
    private(set) var state: AppState?
    private var panel: NotchPanel?
    private var geometry: NotchGeometry?
    private var onboardingWindow: NSWindow?
    private var onboarding: OnboardingModel?
    private var licenceWindow: NSWindow?
    private var lastLicenceCheck = Date.distantPast
    private var isLocked: Bool { store.licence?.isLocked == true }
    /// The notch shows unless the licence is locked or OurNotch is hidden for a while.
    private var notchVisible: Bool { !isLocked && state?.isHidden != true }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests run inside the app; they don't need a notch on screen.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        Diagnostics.shared.record(Self.launchSummary)
        PerfMonitor.shared.startWatchdog()

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
                self?.checkLicence()
            }
        }
        NSApp.registerForRemoteNotifications()
    }

    // MARK: Activation link

    /// `ournotch://activate?key=…` from the thank-you page. Ignored once this Mac is paired
    /// (the buyer is already active, and a partner is covered through the pairing).
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "ournotch" && url.host() == "activate" {
            guard let key = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "key" })?.value, !key.isEmpty else { continue }
            Diagnostics.shared.record("activation link opened")
            guard let onboarding else { continue }
            onboarding.activate(key: key)
            onboardingWindow?.showInFront()
        }
    }

    // MARK: Pings

    /// CloudKit's silent ping: the partner's row changed.
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        let subscription = CKNotification(fromRemoteNotificationDictionary: userInfo)?.subscriptionID ?? "unknown"
        Diagnostics.shared.record("ping received (subscription \(subscription))", metric: Metric(kind: .ping, name: "ping", detail: subscription))
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

    /// "launched OurNotch · Mac16,12 · macOS 26.6.2 · 0.1 (1) Release · notch 179×32 · checks every 60 s"
    private static var launchSummary: String {
        let geometry = NotchGeometry.current()
        let screen = geometry.map { "\($0.hasNotch ? "notch" : "no notch, pill") \(Int($0.notchSize.width))×\(Int($0.notchSize.height))" } ?? "no screen"
        return "launched OurNotch · \(Metric.device) · \(screen) · checks every \(Config.Cloud.pollInterval)"
    }

    /// Exports now and shows the folder in Finder.
    func saveDiagnostics() {
        Task {
            await exportDiagnostics()
            NSWorkspace.shared.activateFileViewerSelecting([Diagnostics.folder.appending(path: "metrics.csv")])
        }
    }

    /// Re-exports every few minutes, so after a test session the files are already there.
    private func startAutoExport() {
        guard Config.Diagnostics.uploads else { return }
        Task {
            while true {
                try? await Task.sleep(for: Config.Diagnostics.exportInterval)
                await exportDiagnostics()
            }
        }
    }

    /// Writes into ~/Library/Logs/OurNotch/, next to this Mac's own log (written as it happens):
    /// `partner-mac.log` (their latest lines) and `metrics.csv` (both Macs' measurements from CloudKit).
    private func exportDiagnostics() async {
        guard let pairing = state?.pairing else { return }
        let folder = Diagnostics.folder
        let partnerLog = (try? await mailbox.fetchDiagnostics(owner: pairing.partnerId)) ?? "(no log uploaded yet)"
        try? Data(partnerLog.utf8).write(to: folder.appending(path: "partner-mac.log"))

        var csv = "time,side,kind,name,ms,frames,dropped,detail,device\n"
        do {
            let mine = try await mailbox.fetchMetrics(owner: pairing.myId).map { ("me", $0) }
            let theirs = try await mailbox.fetchMetrics(owner: pairing.partnerId).map { ("partner", $0) }
            let time = ISO8601DateFormatter()
            time.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            for (side, m) in (mine + theirs).sorted(by: { $0.1.at < $1.1.at }) {
                let fields = [time.string(from: m.at), side, m.kind.rawValue, m.name, String(format: "%.0f", m.ms),
                              m.frames.map(String.init) ?? "", m.dropped.map(String.init) ?? "", m.detail ?? "", m.device]
                csv += fields.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",") + "\n"
            }
        } catch {
            csv = "# export failed: \(error.diagnosticDescription) (is Metric.ownerId Queryable in CloudKit Console?)\n" + csv
        }
        try? Data(csv.utf8).write(to: folder.appending(path: "metrics.csv"))
    }

    /// Starts syncing and shows the notch. Returns false if this Mac isn't paired yet.
    @discardableResult
    private func startNotch() -> Bool {
        guard let state = AppState(store: store, mailbox: mailbox) else { return false }
        // Syncing carries on while locked (a new key from the partner must still arrive); effects don't play.
        state.onEmojisArrived = { [weak self] count, emoji in
            guard let self, !self.isLocked else { return }
            self.effects.play(newCount: count, emoji: emoji)
        }
        state.onLicenceChanged = { [weak self] in self?.checkLicence() }
        state.onHiddenChanged = { [weak self] in self?.updateNotchVisibility() }
        state.onOpened = { [weak self] in
            guard let self, Date.now.timeIntervalSince(self.lastLicenceCheck) > Config.Licence.openCheckGap else { return }
            self.checkLicence()
        }
        state.start()
        Diagnostics.shared.startUploading(owner: state.pairing.myId, mailbox: mailbox)
        startAutoExport()
        self.state = state
        menu.isPaired = true
        menu.isHidden = state.isHidden
        placeNotch()
        applyLicence()
        startLicenceChecks()
        return true
    }

    // MARK: Licence

    /// On launch and then hourly (`Config.Licence.checkInterval`); waking, opening the notch and a newly received
    /// key check too.
    private func startLicenceChecks() {
        Task {
            while true {
                await runLicenceCheck()
                try? await Task.sleep(for: Config.Licence.checkInterval)
            }
        }
    }

    func checkLicence() {
        Task { await runLicenceCheck() }
    }

    private func runLicenceCheck() async {
        guard state != nil else { return }
        lastLicenceCheck = .now
        await LicenceService(store: store).check()
        Diagnostics.shared.record("licence check: \(store.licence?.status.rawValue ?? "none")")
        applyLicence()
    }

    /// Locked: the notch hides and the licence window shows. Unlocked: the reverse.
    private func applyLicence() {
        guard let state else { return }
        if isLocked {
            panel?.orderOut(nil)
            showLicenceWindow()
        } else {
            state.shareLicence()
            if let licenceWindow {
                licenceWindow.close()
                self.licenceWindow = nil
                NSApp.setActivationPolicy(.accessory)
            }
            updateNotchVisibility()
        }
    }

    private func updateNotchVisibility() {
        menu.isHidden = state?.isHidden ?? false
        if notchVisible { panel?.orderFrontRegardless() } else { panel?.orderOut(nil) }
    }

    private func showLicenceWindow() {
        guard licenceWindow == nil else { return }
        let model = LicenceBlockedModel(store: store) { [weak self] in self?.applyLicence() }
        let window = NSWindow(contentViewController: NSHostingController(rootView: LicenceBlockedView(model: model)))
        window.title = "OurNotch"
        window.styleMask = [.titled] // not closable: quit from the ♡ menu instead
        window.isReleasedWhenClosed = false
        window.center()
        licenceWindow = window
        NSApp.setActivationPolicy(.regular) // typing a key needs a regular app
        window.showInFront()
    }

    // MARK: Onboarding

    /// A regular window that needs typing, so the app briefly becomes a regular app (Dock icon, ⌘-Tab).
    private func showOnboarding() {
        let model = OnboardingModel(store: store, mailbox: mailbox) { [weak self] in self?.finishOnboarding() }
        onboarding = model
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
        onboarding = nil
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
        if notchVisible { panel.orderFrontRegardless() }
        panel.alphaValue = 1
        self.panel = panel
    }

    #if DEBUG
    /// Forgets both identities (settings, keys, cached photos), then quits, so the next launch is a fresh
    /// install. Old records stay in CloudKit; new identities never read them.
    /// Under `OURNOTCH_PROFILE` it forgets only that profile, never your real pairing.
    func resetForTesting() {
        if let name = Profile.storageName {
            UserDefaults.standard.removePersistentDomain(forName: name)
            Keychain.delete(service: name)
        } else {
            if let bundleId = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleId)
            }
            Keychain.delete(service: AppDelegate.keychainService)
            try? FileManager.default.removeItem(at: PhotoCache.defaultRoot) // per-person folders; a profile's are left
        }
        UserDefaults.standard.removePersistentDomain(forName: PartnerSimulator.suiteName)
        Keychain.delete(service: PartnerSimulator.suiteName)
        NSApp.terminate(nil)
    }
    #endif
}

/// Sparkle updates (`spec-m2.md > Packaging and Updates`): checks the feed daily and offers a new version.
/// Off until the release key exists (slice 11 sets `SPARKLE_PUBLIC_KEY`), and in Debug builds.
@MainActor
final class Updates {
    private let controller: SPUStandardUpdaterController?

    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        #if DEBUG
        let enabled = false
        #else
        let enabled = !key.isEmpty
        #endif
        controller = enabled ? SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil) : nil
        Diagnostics.shared.record(enabled ? "updates: checking \(Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? "?")" : "updates: off (no release key yet, or a Debug build)")
    }

    var canCheck: Bool { controller != nil }
    func check() { controller?.checkForUpdates(nil) }
}

/// `OURNOTCH_PROFILE=<name>` (Debug builds) runs a separate, fresh identity next to the real one, with its own
/// Partner Simulator, so testing never touches your real pairing. Display settings (emoji mode, photo style,
/// language) stay shared with the real app.
enum Profile {
    #if DEBUG
    static let name = ProcessInfo.processInfo.environment["OURNOTCH_PROFILE"]
    #else
    static let name: String? = nil
    #endif
    /// Where this profile's settings and keys live; nil for the real identity.
    static var storageName: String? { name.map { "OurNotch.profile.\($0)" } }
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
