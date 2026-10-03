import ServiceManagement
import SwiftUI

/// Opening OurNotch at login. The only "permission" the app needs.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }
}

/// Opened from the gear in the notch.
struct SettingsView: View {
    @State private var opensAtLogin = LoginItem.isEnabled
    @State private var error: String?

    var body: some View {
        Form {
            Toggle("Open at Login", isOn: Binding(get: { opensAtLogin }, set: setOpensAtLogin))
            if let error {
                Text(error).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
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
