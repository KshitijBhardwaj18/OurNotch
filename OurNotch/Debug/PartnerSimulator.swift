#if DEBUG
import SwiftUI

/// A stand-in for your love on this Mac, for testing without a second Mac. Debug builds only.
/// It is a separate person: its own id, keys, and storage, talking through the same mailbox as the notch.
@MainActor
final class PartnerSimulator {
    static let suiteName = "OurNotch.PartnerSimulator"

    private let model = SimulatorModel(store: LocalStore(defaults: UserDefaults(suiteName: suiteName)!),
                                       mailbox: LocalFileMailbox())
    private var window: NSWindow?

    func show() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: PartnerSimulatorView(model: model)))
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

@MainActor
@Observable
private final class SimulatorModel {
    var name = "Nikki"
    var typedCode = ""
    var togetherSince = Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 14))!
    private(set) var state: AppState?
    private(set) var inviteCode: String?
    private(set) var error: String?

    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let mailbox: Mailbox
    @ObservationIgnored private var service: PairingService { PairingService(mailbox: mailbox, store: store) }

    init(store: LocalStore, mailbox: Mailbox) {
        self.store = store
        self.mailbox = mailbox
        startIfPaired()
    }

    /// Plays the inviter: answers "together since" up front, then waits for the notch to join.
    func invite() async {
        store.togetherSince = togetherSince
        do {
            let code = try await service.createInvite(name: name)
            inviteCode = code
            _ = try await service.waitForJoin(code: code)
            startIfPaired()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func join() async {
        do {
            _ = try await service.join(code: typedCode, name: name)
            startIfPaired()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func startIfPaired() {
        state = AppState(store: store, mailbox: mailbox)
        state?.start()
    }
}

private struct PartnerSimulatorView: View {
    @Bindable var model: SimulatorModel

    @State private var draft = "hi babe how are you? love you"
    @State private var mode: BannerMode = .three

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Acts as your love, on this Mac. Test tool only.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let state = model.state {
                controls(state)
            } else {
                pairing
            }
        }
        .padding(20)
        .frame(width: 340, alignment: .leading)
    }

    private var pairing: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Name", text: $model.name)

            GroupBox("Join the notch's invite") {
                HStack {
                    TextField("Code", text: $model.typedCode)
                    Button("Join") { Task { await model.join() } }
                }
            }

            GroupBox("Or invite the notch") {
                VStack(alignment: .leading) {
                    DatePicker("Together since", selection: $model.togetherSince, displayedComponents: .date)
                    if let code = model.inviteCode {
                        Text("Code: \(code) — waiting…").textSelection(.enabled).monospaced()
                    } else {
                        Button("Invite") { Task { await model.invite() } }
                    }
                }
            }

            if let error = model.error {
                Text(error).foregroundStyle(.red)
            }
        }
    }

    private func controls(_ state: AppState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paired with \(state.pairing.partnerName) (\(state.pairing.role.rawValue))")

            HStack {
                Button("Send ❤") { state.sendHeart() }
                Button("Send ❤ ×3") { (0..<3).forEach { _ in state.sendHeart() } }
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("Message", text: $draft)
                HStack {
                    Picker("Scroll", selection: $mode) {
                        Text(BannerMode.three.label).tag(BannerMode.three)
                        Text(BannerMode.untilOpened.label).tag(BannerMode.untilOpened)
                    }
                    .labelsHidden()
                    .fixedSize()
                    Button("Send message") { state.sendMessage(draft, mode: mode) }
                        .disabled(MessageRules.check(draft) == .empty)
                }
            }

            Grid(alignment: .leading, verticalSpacing: 6) {
                GridRow {
                    Text("Hearts sent").foregroundStyle(.secondary)
                    Text("\(state.myOutbox.heartsSent)  \(state.heartStatus.label)")
                }
                GridRow {
                    Text("Hearts received").foregroundStyle(.secondary)
                    Text("\(state.heartsReceived)")
                }
                GridRow {
                    Text("Message sent").foregroundStyle(.secondary)
                    Text(state.messageStatus.label)
                }
                GridRow {
                    Text("Last message").foregroundStyle(.secondary)
                    Text(state.partnerOutbox.message?.text ?? "none")
                }
            }
            .monospacedDigit()
        }
    }
}
#endif
