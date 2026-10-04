import ServiceManagement
import SwiftUI

/// Opening OurNotch at login. The only "permission" the app needs.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }
}

/// Settings live inside the notch, in place of the current tab; the gear opens and closes them.
struct SettingsPanel: View {
    let state: AppState
    @State private var opensAtLogin = LoginItem.isEnabled
    @State private var error: String?
    @AppStorage(PhotoStyle.storageKey) private var photoStyle: PhotoStyle = .soft

    var body: some View {
        // Scrolls once the rows outgrow the notch's 200 pt content area.
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open at Login").font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                        Text(error ?? "Your notch will be there every time you open your Mac.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(error == nil ? Color.secondaryLabel : .notchPink)
                    }
                    Spacer()
                    Toggle("Open at Login", isOn: Binding(get: { opensAtLogin }, set: setOpensAtLogin))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.small)
                        .tint(.notchPink)
                }
                .padding(12)
                .background(Color.notchField, in: RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Photo style").font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                        Text("How photos blend into the dark notch.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.secondaryLabel)
                    }
                    Spacer()
                    SmallSegmented(options: PhotoStyle.allCases, selection: $photoStyle, label: \.label)
                }
                .padding(12)
                .background(Color.notchField, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hide OurNotch").font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                        Text("Hearts and notes wait for you. Your love sees you're away.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.secondaryLabel)
                    }
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.notchField, in: RoundedRectangle(cornerRadius: 10))

                if state.licence?.isBuyer == true {
                    LicenceRow(state: state)
                }
            }
        }
        .scrollIndicators(.never)
        .cardStyle()
    }

    private func setOpensAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.set(enabled)
            error = nil
        } catch {
            self.error = "Couldn't change this right now. Try again later."
        }
        opensAtLogin = LoginItem.isEnabled
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
                Text("Licence").font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                Text(error ?? "Active · covers you both")
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
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.notchField, in: RoundedRectangle(cornerRadius: 10))
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
                self.error = (error as? LicenceError)?.errorDescription ?? "Couldn't remove it right now."
            }
        }
    }
}
