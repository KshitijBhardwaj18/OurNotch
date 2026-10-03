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
    @State private var opensAtLogin = LoginItem.isEnabled
    @State private var error: String?
    @AppStorage(PhotoStyle.storageKey) private var photoStyle: PhotoStyle = .soft

    var body: some View {
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
        }
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
