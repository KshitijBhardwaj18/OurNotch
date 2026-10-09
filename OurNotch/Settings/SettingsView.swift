import ServiceManagement
import SwiftUI

/// Opening OurNotch at login. The only "permission" the app needs.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }
}

/// OurNotch's own language: the Mac's, or one chosen in Settings. macOS picks an app's language at launch,
/// so choosing one restarts OurNotch (`spec-m2.md > Languages`).
enum AppLanguage: String, CaseIterable {
    case system, en, fr, de

    /// Each language in its own words, so it's findable whatever the current language.
    var label: String {
        switch self {
        case .system: String(localized: "System")
        case .en: "English"
        case .fr: "Français"
        case .de: "Deutsch"
        }
    }

    /// Only an override set for OurNotch itself counts; the Mac's own list lives in the global domain.
    static var current: AppLanguage {
        let mine = Bundle.main.bundleIdentifier.flatMap { UserDefaults.standard.persistentDomain(forName: $0) }
        return (mine?["AppleLanguages"] as? [String])?.first.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    func applyAndRestart() {
        guard self != Self.current else { return }
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        config.environment = ProcessInfo.processInfo.environment // keeps OURNOTCH_PROFILE across the restart
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}

/// Settings live inside the notch, in place of the current tab; the gear opens and closes them.
/// Cards like Home's: small settings two to a row, wider ones across.
struct SettingsPanel: View {
    let state: AppState
    @State private var opensAtLogin = LoginItem.isEnabled
    @State private var error: String?
    @AppStorage(PhotoStyle.storageKey) private var photoStyle: PhotoStyle = .soft

    var body: some View {
        @Bindable var state = state
        // Scrolls: the cards are taller than the notch's content area.
        ScrollView {
            VStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Settings").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Spacer()
                    Text("OurNotch \(Self.version)").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.tertiaryLabel)
                }
                .padding(.horizontal, 4)

                HStack(spacing: 10) {
                    SettingCard("Open at Login",
                                error ?? String(localized: "Your notch is there every time you open your Mac."),
                                warns: error != nil) {
                        switchToggle("Open at Login", isOn: Binding(get: { opensAtLogin }, set: setOpensAtLogin))
                    }
                    SettingCard("Mood words", String(localized: "Like 🍕 hungry, next to their mood.")) {
                        switchToggle("Mood words", isOn: $state.showsMoodWord)
                    }
                }

                SettingCard("Our anniversary", String(localized: "Counts your seconds together and the days to your anniversary, on both Macs.")) {
                    AnniversaryPicker(state: state)
                }

                SettingCard("Photo style", String(localized: "How photos blend into the dark notch.")) {
                    SmallSegmented(options: PhotoStyle.allCases, selection: $photoStyle, label: \.label)
                }

                SettingCard("Hide OurNotch", String(localized: "Hearts and whispers wait for you. Your love sees you're away.")) {
                    HStack(spacing: 6) {
                        ForEach(Hide.allCases, id: \.self) { choice in
                            Button(choice.label) { state.hide(until: choice.until()) }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .frame(height: 24)
                                .background(Color.notchPressed, in: Capsule())
                        }
                    }
                }

                SettingCard("Language", String(localized: "OurNotch restarts to switch.")) {
                    SmallSegmented(options: AppLanguage.allCases,
                                   selection: Binding(get: { AppLanguage.current }, set: { $0.applyAndRestart() }),
                                   label: \.label)
                }

                if state.licence?.isBuyer == true {
                    LicenceRow(state: state)
                }

                SettingCard("OurNotch \(Self.version)", String(localized: "Updates arrive by themselves. Questions or ideas? Write to us.")) {
                    HStack(spacing: 12) {
                        if Updates.shared.canCheck {
                            linkButton("Check for Updates") { Updates.shared.check() }
                        }
                        linkButton("Write to Us") {
                            NSWorkspace.shared.open(URL(string: "mailto:\(Config.Licence.supportEmail)")!)
                        }
                    }
                }
            }
        }
        .scrollIndicators(.never)
    }

    /// "1.0.4"
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    private func switchToggle(_ label: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn).toggleStyle(.switch).labelsHidden().controlSize(.small).tint(.notchPink)
    }

    private func linkButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain).font(.system(size: 11.5, weight: .medium)).foregroundStyle(Color.notchBlush)
    }

    private func setOpensAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.set(enabled)
            error = nil
        } catch {
            self.error = String(localized: "Couldn't change this right now. Try again later.")
        }
        opensAtLogin = LoginItem.isEnabled
    }
}

/// The date as a pill; clicking it opens a calendar.
private struct AnniversaryPicker: View {
    let state: AppState
    @State private var choosing = false

    var body: some View {
        Button { choosing.toggle() } label: {
            HStack(spacing: 5) {
                Image(systemName: "heart.fill").font(.system(size: 9)).foregroundStyle(Color.notchPink)
                Text(state.togetherSince?.formatted(date: .abbreviated, time: .omitted) ?? String(localized: "Choose a date"))
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(Color.notchPressed, in: Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $choosing, arrowEdge: .bottom) {
            DatePicker("Our anniversary",
                       selection: Binding(get: { state.togetherSince ?? .now }, set: state.setTogetherSince),
                       in: ...Date.now, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(.notchPink)
                .padding(10)
        }
    }
}

/// One setting as a card: its name with the control beside it, and a line about it underneath.
private struct SettingCard<Control: View>: View {
    let title: LocalizedStringKey
    let detail: String
    var warns = false
    @ViewBuilder let control: Control

    init(_ title: LocalizedStringKey, _ detail: String, warns: Bool = false, @ViewBuilder control: () -> Control) {
        self.title = title
        self.detail = detail
        self.warns = warns
        self.control = control()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                Spacer(minLength: 0)
                control
            }
            .frame(minHeight: 24)
            Text(detail)
                .font(.system(size: 11.5))
                .foregroundStyle(warns ? Color.notchPink : Color.secondaryLabel)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Buyer only: the key's status, where to find it, and freeing this Mac's slot to move to a new Mac.
private struct LicenceRow: View {
    let state: AppState
    @State private var confirming = false
    @State private var working = false
    @State private var error: String?

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Licence").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                Text(error ?? String(localized: "Active · covers you both"))
                    .font(.system(size: 11.5))
                    .foregroundStyle(error == nil ? Color.secondaryLabel : .notchPink)
                    .lineLimit(1)
            }
            Spacer()
            Button("Find My Licence") { NSWorkspace.shared.open(Config.Licence.portalURL) }
                .buttonStyle(.plain).font(.system(size: 11.5, weight: .medium)).foregroundStyle(Color.notchBlush)
            // Two taps, so a stray click never frees the slot.
            Button(confirming ? "Tap to Remove" : "Remove from This Mac", action: remove)
                .buttonStyle(.plain).font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(confirming ? Color.notchPink : Color.secondaryLabel)
                .disabled(working)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.notchCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func remove() {
        guard confirming else {
            confirming = true
            Task {
                try? await Task.sleep(for: .seconds(3))
                confirming = false
            }
            return
        }
        working = true
        Task {
            defer { working = false }
            do {
                try await state.removeLicence()
            } catch {
                self.error = (error as? LicenceError)?.errorDescription ?? String(localized: "Couldn't remove it right now.")
            }
        }
    }
}
