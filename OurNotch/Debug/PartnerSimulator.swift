#if DEBUG
import SwiftUI

/// A stand-in for your love on this Mac, for testing without a second Mac. Debug builds only.
/// It is a separate person: its own id, keys, and storage, talking through the same mailbox as the notch.
@MainActor
final class PartnerSimulator {
    static let suiteName = "OurNotch.PartnerSimulator" + (Profile.name.map { ".\($0)" } ?? "")

    private let model = SimulatorModel(store: LocalStore(defaults: UserDefaults(suiteName: suiteName)!, keychainService: suiteName),
                                       mailbox: CloudStore())
    private var window: NSWindow?

    func syncNow(_ source: SyncSource) { model.state?.syncNow(source) }

    func show() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: PartnerSimulatorView(model: model)))
            window.title = "Partner Simulator"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        window?.showInFront()
    }
}

@MainActor
@Observable
private final class SimulatorModel {
    var name = "Manya"
    var typedCode = ""
    var togetherSince = Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 14))!
    private(set) var state: AppState?
    private(set) var inviteCode: String?
    /// Someone asked to join the simulator's invite; approve or decline it.
    private(set) var pendingJoin: Join?
    private(set) var waitingForYes = false
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
            pendingJoin = try await service.waitForJoinRequest(code: code, declined: [])
        } catch {
            self.error = error.localizedDescription
        }
    }

    func answer(_ yes: Bool) async {
        guard let join = pendingJoin, let code = inviteCode else { return }
        pendingJoin = nil
        do {
            if yes {
                _ = try await service.approve(join, code: code)
                startIfPaired()
            } else {
                try await service.decline(join, code: code)
                pendingJoin = try await service.waitForJoinRequest(code: code, declined: [join.joinerId])
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Plays the joiner: confirms the inviter, asks, and waits for their yes.
    func join() async {
        error = nil
        do {
            let invite = try await service.lookUpInvite(code: typedCode)
            try await service.requestJoin(code: typedCode, name: name)
            waitingForYes = true
            defer { waitingForYes = false }
            _ = try await service.waitForAnswer(code: typedCode, invite: invite)
            startIfPaired()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func startIfPaired() {
        state = AppState(store: store, mailbox: mailbox, who: "sim")
        state?.start()
    }
}

private struct PartnerSimulatorView: View {
    @Bindable var model: SimulatorModel

    @State private var draft = "hi babe how are you? love you"
    @State private var mode: BannerMode = .three
    @State private var emoji = "😘"
    @State private var emojiMode: EmojiMode = .notch

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
                if model.waitingForYes { Text("Asked. Waiting for the notch to say yes…").foregroundStyle(.secondary) }
            }

            GroupBox("Or invite the notch") {
                VStack(alignment: .leading) {
                    DatePicker("Together since", selection: $model.togetherSince, displayedComponents: .date)
                    if let join = model.pendingJoin {
                        Text("\(join.joinerName) wants to join. Is this your love?")
                        HStack {
                            Button("No") { Task { await model.answer(false) } }
                            Button("Yes") { Task { await model.answer(true) } }
                        }
                    } else if let code = model.inviteCode {
                        Text("Code: \(code), waiting…").textSelection(.enabled).monospaced()
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
                Picker("Emoji", selection: $emoji) {
                    ForEach(Config.emojis, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .fixedSize()
                Picker("Appears", selection: $emojiMode) {
                    ForEach(EmojiMode.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .labelsHidden()
                .fixedSize()
            }
            HStack {
                Button("Send \(emoji)") { state.sendEmoji(emoji, mode: emojiMode) }
                Button("Send \(emoji) ×3") { (0..<3).forEach { _ in state.sendEmoji(emoji, mode: emojiMode) } }
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

            Picker("Mood", selection: Binding(get: { state.myOutbox.mood ?? "" },
                                              set: { state.setMood($0.isEmpty ? nil : $0) })) {
                Text("No mood").tag("")
                ForEach(Config.moods, id: \.emoji) { Text("\($0.emoji) \($0.label)").tag($0.emoji) }
            }
            .fixedSize()

            HStack {
                Button("Send photo…") {
                    choosePhoto { url in
                        Task {
                            guard let jpeg = try? PhotoProcessing.squareJPEG(from: url) else { return }
                            _ = await state.sendPhoto(jpeg)
                        }
                    }
                }
                if let photo = state.partnerPhoto {
                    Image(nsImage: photo).resizable().scaledToFill().frame(width: 28, height: 28).clipShape(Circle())
                    Text("their photo").foregroundStyle(.secondary)
                }
            }

            Grid(alignment: .leading, verticalSpacing: 6) {
                GridRow {
                    Text("Emojis sent").foregroundStyle(.secondary)
                    Text("\(state.myOutbox.emojisSent)  \(state.emojiStatus.label)")
                }
                GridRow {
                    Text("Emojis received").foregroundStyle(.secondary)
                    Text("\(state.emojisReceived)")
                }
                GridRow {
                    Text("Message sent").foregroundStyle(.secondary)
                    Text(state.messageStatus.label)
                }
                GridRow {
                    Text("Photo sent").foregroundStyle(.secondary)
                    Text(state.photoStatus.label)
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
