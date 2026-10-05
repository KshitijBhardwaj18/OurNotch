import SwiftUI

/// Drives the first-launch steps, starting at the licence gate (`spec-m2.md > Licence Gate`).
/// Buyer: gate → licence key → name → invite → date → login → done. Partner: gate → name → join → login → done.
/// A Mac that already has a licence starts at welcome instead of the gate.
/// If the Mac isn't signed into iCloud, an iCloud step comes before the name.
@MainActor
@Observable
final class OnboardingModel {
    enum Step { case gate, licenceKey, welcome, icloud, name, invite, join, date, login, done }

    var step: Step
    /// Chosen at the gate: a partner joins with a code and needs no licence.
    private(set) var joining = false
    var typedKey = ""
    var name = ""
    var typedCode = ""
    var togetherSince = Calendar.current.startOfDay(for: .now)
    private(set) var inviteCode: String?
    /// The invite found from a typed code, shown as "kshitij invited you, is that right?" before asking.
    private(set) var foundInvite: Invite?
    /// Joiner: asked to join, waiting for the inviter's yes.
    private(set) var awaitingAnswer = false
    /// Inviter: someone asked to join; "is this your love?"
    private(set) var pendingJoin: Join?
    /// Inviter: joiners declined on this code, so their request isn't asked about again.
    @ObservationIgnored private var declined: Set<String> = []
    private(set) var pairing: Pairing?
    private(set) var error: String?
    private(set) var isWorking = false
    private(set) var opensAtLogin = LoginItem.isEnabled

    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let mailbox: Mailbox
    @ObservationIgnored private let service: PairingService
    @ObservationIgnored private let onFinished: () -> Void
    @ObservationIgnored private var waitTask: Task<Void, Never>?

    init(store: LocalStore, mailbox: Mailbox, onFinished: @escaping () -> Void) {
        self.store = store
        self.mailbox = mailbox
        self.service = PairingService(mailbox: mailbox, store: store)
        self.onFinished = onFinished
        let start: Step = store.licence?.status == .active ? .welcome : .gate
        self.start = start
        step = start
        name = store.myName ?? String(localized: "")
    }

    /// The first screen: the gate, or welcome for a Mac that already has a licence.
    let start: Step

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var partnerName: String { (pairing?.partnerName ?? foundInvite?.inviterName ?? String(localized: "your love")).lowercased() }

    /// The steps on the current path, for the page dots.
    var path: [Step] {
        joining || pairing?.role == .joiner
            ? [start, .name, .join, .login, .done]
            : (start == .gate ? [.gate, .licenceKey] : [.welcome]) + [.name, .invite, .date, .login, .done]
    }

    func go(to step: Step) {
        error = nil
        if step != .invite { waitTask?.cancel() }
        self.step = step
        if step == .invite { startInvite() }
    }

    // MARK: Licence gate

    func getOurNotch() { NSWorkspace.shared.open(Config.Licence.checkoutURL) }

    func joinWithCode() {
        joining = true
        checkICloud()
    }

    func backToStart() {
        joining = false
        go(to: start)
    }

    /// The website's "Open OurNotch" button: fills in the key and activates, showing any error on the key step.
    func activate(key: String) {
        guard !isWorking, step == .gate || step == .licenceKey || step == .welcome else { return }
        typedKey = key
        step = .licenceKey
        activate()
    }

    /// Switches the pasted key on for this Mac, then carries on as a buyer.
    func activate() {
        run {
            try await LicenceService(store: self.store).activate(key: self.typedKey)
            self.checkICloud()
        }
    }

    // MARK: iCloud

    /// Hearts and notes travel through iCloud, so the Mac must be signed in before pairing.
    func checkICloud() {
        isWorking = true
        Task {
            defer { isWorking = false }
            go(to: await mailbox.accountAvailable() ? .name : .icloud)
        }
    }

    func openICloudSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings")!)
    }

    // MARK: Invite

    /// Posts the invite (once), then waits in the background for my love to join.
    private func startInvite() {
        // Only the buyer invites; a partner is covered through the pairing (`spec-m2.md > Partner Coverage`).
        guard store.licence?.isBuyer == true, store.licence?.status == .active else {
            error = String(localized: "Only the person who bought OurNotch can invite. Go back and choose I Have an Invite Code.")
            return
        }
        Task {
            if inviteCode == nil {
                do {
                    inviteCode = try await service.createInvite(name: trimmedName)
                } catch {
                    self.error = String(localized: "Couldn't create an invite. Try again.")
                    return
                }
            }
            waitForJoinRequest()
        }
    }

    /// Waits in the background until someone asks to join, then asks "is this your love?".
    private func waitForJoinRequest() {
        guard let inviteCode else { return }
        waitTask?.cancel()
        waitTask = Task {
            guard let join = try? await service.waitForJoinRequest(code: inviteCode, declined: declined) else { return }
            pendingJoin = join
        }
    }

    /// "Yes, this is my love."
    func approveJoin() {
        guard let join = pendingJoin, let inviteCode else { return }
        run {
            self.pairing = try await self.service.approve(join, code: inviteCode)
            self.pendingJoin = nil
            self.go(to: .date)
        }
    }

    /// "No": they're told gently, and the code keeps waiting for the right person.
    func declineJoin() {
        guard let join = pendingJoin, let inviteCode else { return }
        run {
            try await self.service.decline(join, code: inviteCode)
            self.declined.insert(join.joinerId)
            self.pendingJoin = nil
            self.waitForJoinRequest()
        }
    }

    /// A fresh code, e.g. after the old one expired (24 h) or went to the wrong person.
    func newCode() {
        inviteCode = nil
        pendingJoin = nil
        declined = []
        startInvite()
    }

    func copyCode() {
        guard let inviteCode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(inviteCode, forType: .string)
    }

    /// Opens the user's own Mail app with a pre-written invite. No email server needed.
    func sendInviteEmail() {
        guard let inviteCode else { return }
        let body = String(localized: """
        \(trimmedName) planned a surprise for you, sweetheart ♡

        A little place in your Mac's notch where things from both of us arrive.

        1. Download OurNotch (free for you): \(Config.Pairing.downloadURL)
        2. Open it, choose "I Have an Invite Code" and type: \(inviteCode)

        The code works for 24 hours.

        love, \(trimmedName)
        """)
        var mail = URLComponents()
        mail.scheme = "mailto"
        mail.queryItems = [URLQueryItem(name: "subject", value: String(localized: "I planned a surprise for you ♡")),
                           URLQueryItem(name: "body", value: body)]
        if let url = mail.url { NSWorkspace.shared.open(url) }
    }

    // MARK: Join

    func lookUpCode() {
        run {
            self.foundInvite = try await self.service.lookUpInvite(code: self.typedCode)
        }
    }

    /// "Yes, that's my love": asks to join, then waits for the inviter's yes.
    func join() {
        guard let invite = foundInvite else { return }
        let code = typedCode
        run {
            try await self.service.requestJoin(code: code, name: self.trimmedName)
            self.awaitingAnswer = true
            defer { self.awaitingAnswer = false }
            do {
                self.pairing = try await self.service.waitForAnswer(code: code, invite: invite)
            } catch {
                self.foundInvite = nil // declined, used or expired: back to typing a code
                throw error
            }
            self.go(to: .login)
        }
    }

    func editCode() {
        foundInvite = nil
        error = nil
    }

    private func run(_ work: @escaping () async throws -> Void) {
        isWorking = true
        error = nil
        Task {
            defer { isWorking = false }
            do {
                try await work()
            } catch let pairingError as PairingError {
                error = pairingError.errorDescription
            } catch let licenceError as LicenceError {
                error = licenceError.errorDescription
            } catch {
                self.error = String(localized: "Something went wrong. Try again.")
            }
        }
    }

    // MARK: After pairing

    func saveTogetherSince() {
        store.togetherSince = togetherSince
        go(to: .login)
    }

    func setOpensAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.set(enabled)
            error = nil
        } catch {
            self.error = String(localized: "Couldn't change this right now. You can turn it on later in Settings.")
        }
        opensAtLogin = LoginItem.isEnabled
    }

    func finish() { onFinished() }
}

// MARK: - Views

/// Setup-Assistant style: centered content, and a footer with page dots and Back / Continue.
/// Follows the system's light or dark appearance.
struct OnboardingView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let error = model.error {
                Text(error).font(.system(size: 12)).foregroundStyle(Color.accentPink)
                    .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.bottom, 8)
            }
            Divider()
            footer
        }
        .frame(width: 420, height: 440)
        .animation(.smooth(duration: 0.25), value: model.step)
    }

    // MARK: Screens

    @ViewBuilder private var content: some View {
        switch model.step {
        case .gate:
            gate
        case .licenceKey:
            Screen(symbol: "key", title: "Enter your licence key",
                   message: "It's in your receipt email from Dodo Payments.") {
                TextField("Licence key", text: $model.typedKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: 300)
                    .onSubmit(continueAction)
                Button("Don't have one? Get OurNotch", action: model.getOurNotch).buttonStyle(.link)
            }
        case .welcome:
            Screen(icon: AnyView(AppIcon()), title: "Welcome to OurNotch",
                   message: "A little love note that lives in the top of your screen.") {}
        case .icloud:
            Screen(symbol: "icloud", title: "Sign in to iCloud",
                   message: "OurNotch uses iCloud to carry your hearts and notes between your Macs. Sign in, then try again.") {
                Button("Open System Settings…", action: model.openICloudSettings)
            }
        case .name:
            Screen(symbol: "person", title: "What should your love call you?",
                   message: "Shown next to your hearts and notes.") {
                TextField("Your name", text: $model.name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)
                    .onSubmit(continueAction)
            }
        case .invite:
            if let join = model.pendingJoin {
                Screen(symbol: "heart.fill", title: "\(join.joinerName) wants to join",
                       message: "Is this your love? Only say yes if it's them.") {
                    HStack {
                        Button("No", action: model.declineJoin).controlSize(.large)
                        Button("Yes, It's My Love", action: model.approveJoin).buttonStyle(PinkProminentButtonStyle())
                    }
                    .disabled(model.isWorking)
                }
            } else {
                Screen(symbol: "envelope", title: "Invite your love",
                       message: "Share this code — it's just for the two of you, and works for 24 hours.") { inviteCode }
            }
        case .join:
            joinScreen
        case .date:
            Screen(symbol: "calendar", title: "When did you get together?") {
                DatePicker("Together since", selection: $model.togetherSince, in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.stepperField)
                    .labelsHidden()
                Text("That's \(Together.days(since: model.togetherSince).formatted()) days ♡")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(Color.accentPink)
            }
        case .login:
            Screen(symbol: "laptopcomputer", title: "Keep your love close",
                   message: "Your notch will be there every time you open your Mac.") {
                HStack {
                    Text("Open at Login")
                    Spacer()
                    Toggle("Open at Login", isOn: Binding(get: { model.opensAtLogin }, set: model.setOpensAtLogin))
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(width: 280)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            }
        case .done:
            Screen(symbol: "heart.fill", title: "You're all set ♡",
                   message: "Hover the notch anytime to send \(model.partnerName) a little love.") {}
        }
    }

    /// Feels like opening a gift: the price and one big button lead; the key and the code are secondary.
    private var gate: some View {
        Screen(icon: AnyView(AppIcon()), title: "Welcome to OurNotch",
               message: "A little place in your notch where things from both of you arrive.") {
            VStack(spacing: 10) {
                Button("Get OurNotch — \(Config.Licence.priceLabel)", action: model.getOurNotch)
                    .buttonStyle(PinkProminentButtonStyle())
                Text("One purchase for the two of you · local price shown at checkout")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                // Stacked, so they fit in every language ("Ich habe einen Einladungscode").
                VStack(spacing: 6) {
                    Button("I Have a Licence Key") { model.go(to: .licenceKey) }
                    Button("I Have an Invite Code", action: model.joinWithCode)
                }
                .buttonStyle(.link)
                .disabled(model.isWorking)
                .padding(.top, 6)
            }
        }
    }

    @ViewBuilder private var inviteCode: some View {
        if let code = model.inviteCode {
            Text(code)
                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                .tracking(6)
                .textSelection(.enabled)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
            HStack {
                Button("Copy Code", action: model.copyCode)
                Button("Send Email…", action: model.sendInviteEmail)
                Button("New Code", action: model.newCode)
            }
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Waiting for your love to join…").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        } else if model.error == nil {
            ProgressView()
        }
    }

    @ViewBuilder private var joinScreen: some View {
        if let invite = model.foundInvite {
            Screen(symbol: "heart.fill", title: "\(invite.inviterName) invited you",
                   message: model.awaitingAnswer ? nil : "Is that right? Only continue if it's your love.") {
                if model.awaitingAnswer {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Waiting for \(invite.inviterName) to say yes…").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Screen(symbol: "heart.fill", title: "Enter your code",
                   message: "The 6 letters from your love's invite.") {
                TextField("K7QM3X", text: $model.typedCode)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 180)
                    .onSubmit(continueAction)
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 8) {
            footerLeading
            Spacer()
            // Waiting on the network (activating, checking iCloud, pairing): show it, so a click never looks ignored.
            if model.isWorking {
                ProgressView().controlSize(.small)
            }
            if let back = backAction {
                Button("Back", action: back).controlSize(.large)
            }
            if let title = continueTitle {
                Button(title, action: continueAction)
                    .buttonStyle(PinkProminentButtonStyle())
                    .disabled(!canContinue)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }

    @ViewBuilder private var footerLeading: some View {
        switch model.step {
        case .date:
            Button("Skip for Now") { model.go(to: .login) }.buttonStyle(.link)
        default:
            HStack(spacing: 6) {
                ForEach(model.path, id: \.self) { step in
                    Circle()
                        .fill(step == model.step ? Color.primary : Color.secondary.opacity(0.35))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    private var continueTitle: LocalizedStringKey? {
        switch model.step {
        case .gate: nil // the gate's own buttons choose the path
        case .licenceKey: "Activate"
        case .welcome: "Get Started"
        case .icloud: "Try Again"
        case .invite: nil // advances by itself when your love joins
        case .join: model.awaitingAnswer ? nil : (model.foundInvite == nil ? "Continue" : "Yes, Ask to Join")
        case .done: "Done"
        default: "Continue"
        }
    }

    private var canContinue: Bool {
        switch model.step {
        case .welcome, .icloud: !model.isWorking
        case .licenceKey: !model.typedKey.trimmingCharacters(in: .whitespaces).isEmpty && !model.isWorking
        case .name: !model.trimmedName.isEmpty
        case .join: !model.typedCode.isEmpty && !model.isWorking
        default: true
        }
    }

    private func continueAction() {
        guard canContinue else { return }
        switch model.step {
        case .gate: break
        case .licenceKey: model.activate()
        case .welcome, .icloud: model.checkICloud()
        case .name: model.go(to: model.joining ? .join : .invite)
        case .invite: break
        case .join: model.foundInvite == nil ? model.lookUpCode() : model.join()
        case .date: model.saveTogetherSince()
        case .login: model.go(to: .done)
        case .done: model.finish()
        }
    }

    private var backAction: (() -> Void)? {
        switch model.step {
        case .licenceKey, .icloud, .name: model.backToStart
        case .invite: { model.go(to: .name) }
        case .join: model.awaitingAnswer ? nil : (model.foundInvite == nil ? { model.go(to: .name) } : model.editCode)
        case .done: { model.go(to: .login) }
        default: nil // the welcome screen, and steps after pairing that can't be undone
        }
    }
}

/// One screen: an icon, a title, a short line, then the screen's controls.
struct Screen<Content: View>: View {
    var icon: AnyView? = nil
    var symbol: String? = nil
    let title: LocalizedStringKey
    var message: LocalizedStringKey? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 14) {
            if let icon {
                icon
            } else if let symbol {
                Image(systemName: symbol).font(.system(size: 44)).foregroundStyle(Color.accentPink)
            }
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.3)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            content.padding(.top, 4)
        }
    }
}

/// The OurNotch icon: a white heart on a pink gradient tile.
struct AppIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 17)
            .fill(LinearGradient(colors: [Color(hex: 0xFF5C7A), Color(hex: 0xFF2D55)], startPoint: .top, endPoint: .bottom))
            .frame(width: 72, height: 72)
            .overlay(Image(systemName: "heart.fill").font(.system(size: 38)).foregroundStyle(.white))
    }
}

/// Prominent pink button, 28 pt tall, radius 6.
struct PinkProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration)
    }

    private struct StyledButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 28)
                .background(Color.accentPink.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 6))
                .opacity(isEnabled ? 1 : 0.4)
        }
    }
}

extension Color {
    /// systemPink: `#FF2D55` in light mode, `#FF375F` in dark — follows the window's appearance.
    static let accentPink = Color(nsColor: .systemPink)
}
