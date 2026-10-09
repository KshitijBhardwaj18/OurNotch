import SwiftUI

/// Your last notes to each other as a tiny conversation, and a field to write the next one,
/// choosing how it scrolls on their notch.
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
            conversation
            composer
            footer.padding(.top, 10)
        }
        .cardStyle()
        .onChange(of: focused) { _, now in isEditing = now }
    }

    // MARK: Conversation

    @ViewBuilder private var conversation: some View {
        let lines = Conversation.lines(mine: state.myOutbox, theirs: state.partnerOutbox)
        if lines.isEmpty {
            Text("No notes from \(state.partnerName.lowercased()) yet ♡")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondaryLabel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            ScrollViewReader { reader in
                ScrollView {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        VStack(spacing: 5) {
                            ForEach(lines) { line in bubble(line, now: context.date).id(line.id) }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .defaultScrollAnchor(.bottom) // newest at the bottom, like Messages
                .scrollIndicators(.never)
                // A new note, theirs or mine, scrolls into view.
                .onChange(of: lines.last?.id) { _, last in
                    withAnimation(.snappy(duration: 0.25)) { reader.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }

    private func bubble(_ line: Conversation.Line, now: Date) -> some View {
        let ago = Text(shortAgo(line.message.sentAt, now: now, suffix: false))
            .font(.system(size: 10, weight: .medium).monospacedDigit())
            .foregroundStyle(Color.tertiaryLabel)
        return HStack(alignment: .bottom, spacing: 6) {
            if line.isMine { Spacer(minLength: 60); ago }
            Text(line.message.text)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(line.isMine ? Color.notchPink : .notchField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            if !line.isMine { ago; Spacer(minLength: 60) }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
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
            return words > 0 ? (String(localized: "\(words) of \(Config.Message.maxWords) words"), .tertiaryLabel)
                             : (String(localized: "Up to \(Config.Message.maxWords) words"), .tertiaryLabel)
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
