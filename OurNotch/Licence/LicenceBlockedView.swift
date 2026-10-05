import SwiftUI

/// Shown instead of the notch while the licence is revoked or removed (`spec-m2.md > Licence Blocked`).
/// Kind, not alarming: a way forward is always one click away.
@MainActor
@Observable
final class LicenceBlockedModel {
    var typedKey = ""
    private(set) var status: Licence.Status
    private(set) var error: String?
    private(set) var isWorking = false

    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let onUnlocked: () -> Void

    init(store: LocalStore, onUnlocked: @escaping () -> Void) {
        self.store = store
        self.onUnlocked = onUnlocked
        status = store.licence?.status ?? .revoked
    }

    /// Asks Dodo again, so a restored key unblocks without typing anything.
    func checkAgain() {
        run { await LicenceService(store: self.store).check() }
    }

    /// A new key, or the same one moved back to this Mac.
    func activate() {
        run { try await LicenceService(store: self.store).activate(key: self.typedKey) }
    }

    func getOurNotch() { NSWorkspace.shared.open(Config.Licence.checkoutURL) }

    func readTerms() { NSWorkspace.shared.open(Config.Licence.termsURL) }

    func writeToUs() {
        var mail = URLComponents()
        mail.scheme = "mailto"
        mail.path = Config.Licence.supportEmail
        mail.queryItems = [URLQueryItem(name: "subject", value: String(localized: "My OurNotch licence"))]
        if let url = mail.url { NSWorkspace.shared.open(url) }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        isWorking = true
        error = nil
        Task {
            defer { isWorking = false }
            do {
                try await work()
            } catch {
                self.error = (error as? LicenceError)?.errorDescription ?? String(localized: "Something went wrong. Try again.")
                return
            }
            if store.licence?.isLocked == false {
                onUnlocked()
            } else if self.error == nil {
                self.error = String(localized: "Still not active. If you think this is a mistake, write to us.")
            }
        }
    }
}

struct LicenceBlockedView: View {
    @Bindable var model: LicenceBlockedModel

    var body: some View {
        VStack(spacing: 0) {
            Screen(symbol: model.status == .removed ? "laptopcomputer" : "key",
                   title: model.status == .removed ? "OurNotch was removed from this Mac" : "Your licence was revoked",
                   message: model.status == .removed
                       ? "Paste your licence key to use OurNotch here again."
                       : "This happens when a purchase is refunded, or when a licence is misused — shared publicly or used with a modified copy — as our terms explain. If you think this is a mistake, write to us at \(Config.Licence.supportEmail).") {
                TextField("Licence key", text: $model.typedKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: 300)
                    .onSubmit { if !model.typedKey.isEmpty { model.activate() } }
                HStack {
                    Button("Get OurNotch — \(Config.Licence.priceLabel)", action: model.getOurNotch)
                    Button("Write to Us", action: model.writeToUs)
                }
            }
            .padding(.horizontal, 36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let error = model.error {
                Text(error).font(.system(size: 12)).foregroundStyle(Color.accentPink)
                    .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.bottom, 8)
            }
            Divider()
            HStack {
                if model.status == .revoked {
                    Button("Check Again", action: model.checkAgain).buttonStyle(.link).disabled(model.isWorking)
                    Button("Read Our Terms", action: model.readTerms).buttonStyle(.link).padding(.leading, 12)
                }
                Spacer()
                if model.isWorking { ProgressView().controlSize(.small) }
                Button("Activate", action: model.activate)
                    .buttonStyle(PinkProminentButtonStyle())
                    .disabled(model.typedKey.trimmingCharacters(in: .whitespaces).isEmpty || model.isWorking)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
        }
        .frame(width: 420, height: 360)
    }
}
