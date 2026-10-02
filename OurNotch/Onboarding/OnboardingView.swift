import ServiceManagement
import SwiftUI

/// Drives the first-launch steps: welcome → name → invite or join → together since (inviter) → open at login.
@MainActor
@Observable
final class OnboardingModel {
    enum Step { case welcome, name, choosePath, invite, join, paired, togetherSince, openAtLogin }

    var step: Step = .welcome
    var name = ""
    var typedCode = ""
    var togetherSince = Calendar.current.startOfDay(for: .now)
    private(set) var inviteCode: String?
    private(set) var pairing: Pairing?
    private(set) var error: String?
    private(set) var isWorking = false
    private(set) var opensAtLogin = SMAppService.mainApp.status == .enabled

    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let service: PairingService
    @ObservationIgnored private let onFinished: () -> Void
    @ObservationIgnored private var waitTask: Task<Void, Never>?

    init(store: LocalStore, mailbox: Mailbox, onFinished: @escaping () -> Void) {
        self.store = store
        self.service = PairingService(mailbox: mailbox, store: store)
        self.onFinished = onFinished
        name = store.myName ?? ""
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    func go(to step: Step) {
        error = nil
        if step == .choosePath { waitTask?.cancel() }
        self.step = step
    }

    // MARK: Pairing

    /// Posts the invite, then waits in the background for my love to join.
    func startInvite() {
        go(to: .invite)
        guard inviteCode == nil else { return waitForJoin() }
        Task {
            do {
                inviteCode = try await service.createInvite(name: trimmedName)
                waitForJoin()
            } catch {
                self.error = "couldn't create an invite ♡ try again"
            }
        }
    }

    private func waitForJoin() {
        guard let inviteCode else { return }
        waitTask?.cancel()
        waitTask = Task {
            guard let pairing = try? await service.waitForJoin(code: inviteCode) else { return }
            self.pairing = pairing
            go(to: .paired)
        }
    }

    func join() {
        isWorking = true
        error = nil
        Task {
            defer { isWorking = false }
            do {
                pairing = try await service.join(code: typedCode, name: trimmedName)
                go(to: .paired)
            } catch let pairingError as PairingError {
                error = pairingError.errorDescription
            } catch {
                self.error = "something went wrong ♡ try again"
            }
        }
    }

    /// Opens the user's own Mail app with a pre-written invite. No email server needed.
    func sendInviteEmail() {
        guard let inviteCode else { return }
        let body = """
        I'd love for us to share a little space in our notches ♡

        1. Download OurNotch: \(Config.Pairing.downloadURL)
        2. Choose "I have a code" and type: \(inviteCode)

        love, \(trimmedName)
        """
        var mail = URLComponents()
        mail.scheme = "mailto"
        mail.queryItems = [URLQueryItem(name: "subject", value: "come live in my notch ♡"),
                           URLQueryItem(name: "body", value: body)]
        if let url = mail.url { NSWorkspace.shared.open(url) }
    }

    // MARK: After pairing

    /// Only the inviter is asked "together since"; the joiner receives it.
    func continueAfterPairing() {
        go(to: pairing?.role == .inviter ? .togetherSince : .openAtLogin)
    }

    func saveTogetherSince() {
        store.togetherSince = togetherSince
        go(to: .openAtLogin)
    }

    func setOpensAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            error = nil
        } catch {
            self.error = "couldn't change that ♡ you can try again later"
        }
        opensAtLogin = SMAppService.mainApp.status == .enabled
    }

    func finish() { onFinished() }
}

// MARK: - Views

struct OnboardingView: View {
    let model: OnboardingModel

    var body: some View {
        Group {
            switch model.step {
            case .welcome: welcome
            case .name: nameStep
            case .choosePath: choosePath
            case .invite: invite
            case .join: join
            case .paired: paired
            case .togetherSince: togetherSince
            case .openAtLogin: openAtLogin
            }
        }
        .frame(width: 420, height: 440)
        .animation(.smooth, value: model.step)
        .environment(model)
    }

    private var welcome: some View {
        StepLayout(title: "OurNotch",
                   subtitle: "a little shared space for the two of you, living in your notch. send hearts and sweet notes that float by while you work.") {
            Button("get started") { model.go(to: .name) }.buttonStyle(RoseButtonStyle())
        }
    }

    private var nameStep: some View {
        @Bindable var model = model
        return StepLayout(title: "what should your love call you?", subtitle: "they'll see this when you invite them.") {
            TextField("your name", text: $model.name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .onSubmit { if !model.trimmedName.isEmpty { model.go(to: .choosePath) } }
            Button("continue") { model.go(to: .choosePath) }
                .buttonStyle(RoseButtonStyle())
                .disabled(model.trimmedName.isEmpty)
        }
    }

    private var choosePath: some View {
        StepLayout(title: "pair with your love", subtitle: "one of you invites, the other types the code.") {
            Button("invite your love") { model.startInvite() }.buttonStyle(RoseButtonStyle())
            Button("I have a code") { model.go(to: .join) }.buttonStyle(.link)
        }
    }

    private var invite: some View {
        StepLayout(title: "your invite code", subtitle: "send it to your love. they choose \"I have a code\" and type it in.") {
            if let code = model.inviteCode {
                Text(code)
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospaced())
                    .tracking(6)
                    .textSelection(.enabled)
                Button("send email") { model.sendInviteEmail() }.buttonStyle(RoseButtonStyle())
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("waiting for your love to join…").foregroundStyle(.secondary)
                }
            } else if model.error == nil {
                ProgressView()
            }
            backButton
        }
    }

    private var join: some View {
        @Bindable var model = model
        return StepLayout(title: "enter your code", subtitle: "the 6 letters from your love's invite.") {
            TextField("ABC234", text: $model.typedCode)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 18, weight: .semibold, design: .rounded).monospaced())
                .multilineTextAlignment(.center)
                .frame(width: 180)
                .onSubmit(model.join)
            Button("join") { model.join() }
                .buttonStyle(RoseButtonStyle())
                .disabled(model.typedCode.isEmpty || model.isWorking)
            backButton
        }
    }

    private var paired: some View {
        let partner = model.pairing?.partnerName.lowercased() ?? "your love"
        let title = model.pairing?.role == .joiner ? "\(partner) ❤ invited you" : "\(partner) ❤ joined"
        return StepLayout(title: title, subtitle: "you're paired. hearts and notes now travel between your notches, locked so only you two can read them.") {
            Button("continue") { model.continueAfterPairing() }.buttonStyle(RoseButtonStyle())
        }
    }

    private var togetherSince: some View {
        @Bindable var model = model
        return StepLayout(title: "how long have you been together?", subtitle: "the day you got together. your notch counts from here.") {
            DatePicker("together since", selection: $model.togetherSince, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.field)
                .labelsHidden()
            Button("continue") { model.saveTogetherSince() }.buttonStyle(RoseButtonStyle())
        }
    }

    private var openAtLogin: some View {
        StepLayout(title: "keep your love close", subtitle: "open OurNotch when you log in, so their hearts always find you. no other permissions needed.") {
            Toggle("open at login", isOn: Binding(get: { model.opensAtLogin }, set: model.setOpensAtLogin))
                .toggleStyle(.switch)
            Button("done") { model.finish() }.buttonStyle(RoseButtonStyle())
        }
    }

    private var backButton: some View {
        Button("back") { model.go(to: .choosePath) }.buttonStyle(.link)
    }
}

/// One step: a heart, a title, a short line, then the step's controls. One thing per screen.
private struct StepLayout<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.rose)
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            content
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) { ErrorLine() }
    }
}

/// Shows the current model error, if any, at the bottom of the step.
private struct ErrorLine: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        if let error = model.error {
            Text(error)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Color.rose)
                .padding(.bottom, 24)
        }
    }
}

struct RoseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoseButton(configuration: configuration)
    }

    private struct RoseButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 9)
                .background(Color.rose.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
                .opacity(isEnabled ? 1 : 0.4)
        }
    }
}
