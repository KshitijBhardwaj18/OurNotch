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

    /// Stage mode (`OURNOTCH_STAGE=1` with `OURNOTCH_PROFILE`): pairs itself with the notch and takes commands from
    /// `stageFile`, so an ad can be filmed with no windows on screen. One command per write:
    /// `photo <path>`, `play <message>`, `note <message>`, `heart`, `kisses`, `mood <emoji>` (as the partner);
    /// `me <message>` (as this Mac); `open <tab>`, `close` (the notch).
    static var isStaging: Bool { Profile.name != nil && ProcessInfo.processInfo.environment["OURNOTCH_STAGE"] != nil }
    static let stageFile = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Caches/OurNotch-stage.txt")

    func startStage(notch store: LocalStore, notchState: @escaping () -> AppState?, onPaired: @escaping () -> Void) {
        Task {
            if model.state == nil {
                do {
                    try await model.pairForStage(notch: PairingService(mailbox: CloudStore(), store: store))
                    onPaired()
                } catch {
                    Diagnostics.shared.record("stage: pairing failed: \(error.localizedDescription)")
                }
            }
            // ponytail: polls a file, a socket if this ever leaves Debug
            while true {
                try? await Task.sleep(for: .milliseconds(300))
                guard let command = try? String(contentsOf: Self.stageFile, encoding: .utf8) else { continue }
                try? FileManager.default.removeItem(at: Self.stageFile)
                await model.run(command.trimmingCharacters(in: .whitespacesAndNewlines), notch: notchState())
            }
        }
    }

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

    // MARK: Stage

    private(set) var sceneStatus: String?

    /// Stage mode: invites, lets the notch ask to join in code, and says yes, so pairing needs no window.
    func pairForStage(notch: PairingService) async throws {
        name = "babe ♡"
        store.togetherSince = togetherSince
        let code = try await service.createInvite(name: name)
        let invite = try await notch.lookUpInvite(code: code)
        try await notch.requestJoin(code: code, name: "me")
        let join = try await service.waitForJoinRequest(code: code, declined: [])
        _ = try await service.approve(join, code: code)
        _ = try await notch.waitForAnswer(code: code, invite: invite)
        startIfPaired()
    }

    /// One stage command (see `PartnerSimulator.startStage`).
    func run(_ command: String, notch: AppState?) async {
        guard let state else { return }
        let (verb, rest) = (command.prefix { $0 != " " }, command.drop { $0 != " " }.trimmingCharacters(in: .whitespaces))
        Diagnostics.shared.record("stage: \(verb)")
        switch verb {
        case "photo":
            guard let jpeg = try? PhotoProcessing.squareJPEG(from: URL(filePath: rest)) else { return }
            _ = await state.sendPhoto(jpeg)
        case "play": await playScene(rest, on: state)
        case "note": state.sendMessage(rest, mode: .three)
        // One per command: 3 or more arriving together splash instead of pouring (`Arrival.effect`).
        case "heart": state.sendEmoji("❤️", mode: .notch)
        case "kisses": (0..<3).forEach { _ in state.sendEmoji("😘", mode: .fullScreen) }
        case "mood": state.setMood(rest.isEmpty ? nil : rest)
        case "me": notch?.sendMessage(rest, mode: .three)
        case "open": notch?.stageTab = NotchTab.allCases.first { "\($0)" == rest } ?? .home
        case "close": notch?.stageTab = nil
        default: break
        }
    }

    /// A short scene to film: a countdown to start recording, then hearts out of the notch, the message, and
    /// kisses across the screen, spaced so each arrives on its own.
    func playScene(_ message: String, on state: AppState) async {
        state.setMood("🥺")
        for second in (1...5).reversed() {
            sceneStatus = "Starting in \(second)…"
            try? await Task.sleep(for: .seconds(1))
        }
        sceneStatus = "Playing…"
        (0..<2).forEach { _ in state.sendEmoji("❤️", mode: .notch) }
        try? await Task.sleep(for: .seconds(5))
        state.sendMessage(message, mode: .three)
        try? await Task.sleep(for: .seconds(8))
        (0..<3).forEach { _ in state.sendEmoji("😘", mode: .fullScreen) }
        try? await Task.sleep(for: .seconds(4))
        sceneStatus = nil
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
                Button("Play scene") { Task { await model.playScene(draft, on: state) } }
                    .disabled(model.sceneStatus != nil)
                Text(model.sceneStatus ?? "For recording: mood, hearts, the message below, kisses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
