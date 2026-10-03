import SwiftUI

/// Drives the first-launch steps.
/// Inviter: welcome → name → invite → date → login → done. Joiner: welcome → name → join → login → done.
/// If the Mac isn't signed into iCloud, an iCloud step comes right after welcome.
@MainActor
@Observable
final class OnboardingModel {
    enum Step { case welcome, icloud, name, invite, join, date, login, done }

    var step: Step = .welcome
    var name = ""
    var typedCode = ""
    var togetherSince = Calendar.current.startOfDay(for: .now)
    private(set) var inviteCode: String?
    /// The invite found from a typed code, shown as "nikki ♥ invited you" before joining.
    private(set) var foundInvite: Invite?
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
        name = store.myName ?? ""
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var partnerName: String { (pairing?.partnerName ?? foundInvite?.inviterName ?? "your love").lowercased() }

    /// The steps on the current path, for the page dots.
    var path: [Step] {
        step == .join || pairing?.role == .joiner
            ? [.welcome, .name, .join, .login, .done]
            : [.welcome, .name, .invite, .date, .login, .done]
    }

    func go(to step: Step) {
        error = nil
        if step != .invite { waitTask?.cancel() }
        self.step = step
        if step == .invite { startInvite() }
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
        Task {
            if inviteCode == nil {
                do {
                    inviteCode = try await service.createInvite(name: trimmedName)
                } catch {
                    self.error = "Couldn't create an invite. Try again."
                    return
                }
            }
            guard let inviteCode else { return }
            waitTask?.cancel()
            waitTask = Task {
                guard let pairing = try? await service.waitForJoin(code: inviteCode) else { return }
                self.pairing = pairing
                go(to: .date)
            }
        }
    }

    func copyCode() {
        guard let inviteCode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(inviteCode, forType: .string)
    }

    /// Opens the user's own Mail app with a pre-written invite. No email server needed.
    func sendInviteEmail() {
        guard let inviteCode else { return }
        let body = """
        I'd love for us to share a little space in our notches ♡

        1. Download OurNotch: \(Config.Pairing.downloadURL)
        2. Choose "I Have a Code" and type: \(inviteCode)

        love, \(trimmedName)
        """
        var mail = URLComponents()
        mail.scheme = "mailto"
        mail.queryItems = [URLQueryItem(name: "subject", value: "come live in my notch ♡"),
                           URLQueryItem(name: "body", value: body)]
        if let url = mail.url { NSWorkspace.shared.open(url) }
    }

    // MARK: Join

    func lookUpCode() {
        run {
            self.foundInvite = try await self.service.lookUpInvite(code: self.typedCode)
        }
    }

    func join() {
        run {
            self.pairing = try await self.service.join(code: self.typedCode, name: self.trimmedName)
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
            } catch {
                self.error = "Something went wrong. Try again."
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
            self.error = "Couldn't change this right now. You can turn it on later in Settings."
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
                Text(error).font(.system(size: 12)).foregroundStyle(Color.accentPink).padding(.bottom, 8)
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
            Screen(symbol: "envelope", title: "Invite your love",
                   message: "Share this code — it's just for the two of you.") { inviteCode }
        case .join:
            joinScreen
        case .date:
            Screen(symbol: "calendar", title: "When did you get together?", message: "") {
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
            Screen(symbol: "heart.fill", title: "\(invite.inviterName.lowercased()) ♥ invited you",
                   message: "Code \(PairingService.normalize(model.typedCode))") {}
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
        case .invite:
            Button("I Have a Code") { model.go(to: .join) }.buttonStyle(.link)
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

    private var continueTitle: String? {
        switch model.step {
        case .welcome: "Get Started"
        case .icloud: "Try Again"
        case .invite: nil // advances by itself when your love joins
        case .join: model.foundInvite.map { "Join \($0.inviterName.lowercased())" } ?? "Continue"
        case .done: "Done"
        default: "Continue"
        }
    }

    private var canContinue: Bool {
        switch model.step {
        case .welcome, .icloud: !model.isWorking
        case .name: !model.trimmedName.isEmpty
        case .join: !model.typedCode.isEmpty && !model.isWorking
        default: true
        }
    }

    private func continueAction() {
        guard canContinue else { return }
        switch model.step {
        case .welcome, .icloud: model.checkICloud()
        case .name: model.go(to: .invite)
        case .invite: break
        case .join: model.foundInvite == nil ? model.lookUpCode() : model.join()
        case .date: model.saveTogetherSince()
        case .login: model.go(to: .done)
        case .done: model.finish()
        }
    }

    private var backAction: (() -> Void)? {
        switch model.step {
        case .icloud, .name: { model.go(to: .welcome) }
        case .invite: { model.go(to: .name) }
        case .join: model.foundInvite == nil ? { model.go(to: .invite) } : model.editCode
        case .done: { model.go(to: .login) }
        default: nil // the welcome screen, and steps after pairing that can't be undone
        }
    }
}

/// One screen: an icon, a title, a short line, then the screen's controls.
private struct Screen<Content: View>: View {
    var icon: AnyView? = nil
    var symbol: String? = nil
    let title: String
    let message: String
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
            if !message.isEmpty {
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
private struct AppIcon: View {
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
