import SwiftUI

/// Read your love's latest note and write one back, choosing how it scrolls on their notch.
struct NoteTab: View {
    let state: AppState
    /// True while the field has focus, so the notch stays open while typing.
    @Binding var isEditing: Bool

    @State private var draft = ""
    @State private var mode: BannerMode = .three
    /// Briefly locks the field after sending, then clears it.
    @State private var isLocked = false
    @State private var showsSendStatus = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            theirLatest
            Spacer(minLength: 8)
            composer
            footer.padding(.top, 10)
        }
        .cardStyle()
        .onChange(of: focused) { _, now in isEditing = now }
    }

    // MARK: Their latest

    private var theirLatest: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let note = state.partnerOutbox.message {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text("From \(state.partnerName.lowercased()) · \(shortAgo(note.sentAt, now: context.date))")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondaryLabel)
                Text(note.text)
                    .font(.system(size: 16))
                    .lineLimit(2)
                    .foregroundStyle(.white)
            } else {
                Text("No notes from \(state.partnerName.lowercased()) yet ♡")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondaryLabel)
            }
        }
    }

    // MARK: Composer

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("", text: $draft, prompt: Text("Say something sweet…").foregroundStyle(Color.tertiaryLabel))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .focused($focused)
                .onSubmit(send)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(Color.notchField, in: RoundedRectangle(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(highlightsField ? Color.notchPink : .separator, lineWidth: 1)
                }
                .background {
                    if highlightsField {
                        RoundedRectangle(cornerRadius: 11).stroke(Color.notchPink.opacity(0.35), lineWidth: 3).padding(-1.5)
                    }
                }
                .disabled(isLocked)
                .opacity(isLocked ? 0.5 : 1)

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(canSend ? Color.white : .tertiaryLabel)
                    .frame(width: 32, height: 32)
                    .background(canSend ? Color.notchPink : .white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.top, 10)
        .overlay(alignment: .top) { Rectangle().fill(Color.separator).frame(height: 1) }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("Scroll").font(.system(size: 12)).foregroundStyle(Color.secondaryLabel)
            SmallSegmented(options: BannerMode.allCases, selection: $mode, label: \.label)
            Spacer()
            status
        }
    }

    // MARK: Status and validation

    private var status: some View {
        let verdict = MessageRules.check(draft)
        let (text, color): (String, Color) = {
            if draft.isEmpty || isLocked, showsSendStatus, state.messageStatus != .none {
                switch state.messageStatus {
                case .delivered: return (state.messageStatus.label, .notchPink)
                case .sent: return (state.messageStatus.label, .white)
                default: return (state.messageStatus.label, .secondaryLabel)
                }
            }
            if case .invalid(let hint) = verdict { return (hint, .notchPink) }
            let words = MessageRules.wordCount(draft)
            return words > 0 ? ("\(words) of \(Config.Message.maxWords) words", .tertiaryLabel)
                             : ("Up to \(Config.Message.maxWords) words", .tertiaryLabel)
        }()
        return Text(text)
            .font(.system(size: 11.5, weight: .medium).monospacedDigit())
            .foregroundStyle(color)
    }

    private var isInvalid: Bool {
        if case .invalid = MessageRules.check(draft) { true } else { false }
    }

    private var highlightsField: Bool { focused || isInvalid }

    private var canSend: Bool {
        guard !isLocked, case .valid = MessageRules.check(draft) else { return false }
        return true
    }

    /// Locks and dims the field while it sends, then clears it after ~2 s. Delivery keeps updating the status.
    private func send() {
        guard canSend, state.sendMessage(draft, mode: mode) else { return }
        isLocked = true
        showsSendStatus = true
        focused = false
        Task {
            try? await Task.sleep(for: .seconds(2))
            draft = ""
            isLocked = false
        }
    }
}
