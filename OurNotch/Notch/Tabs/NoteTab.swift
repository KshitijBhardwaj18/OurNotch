import SwiftUI

/// Your last notes to each other as a tiny conversation, and a field to write the next one,
/// choosing how it scrolls on their notch. Dressed like the website: a pastel page, white and pink
/// bubbles, rounded type, a few floating hearts.
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
            Text("our little notes ♡")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Ink.pink)
                .padding(.bottom, 6)
            conversation
            composer
            footer.padding(.top, 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(alignment: .topTrailing) { hearts }
        .background(LinearGradient(colors: [Color(hex: 0xFFF0E6), Color(hex: 0xFFD6DF)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .environment(\.colorScheme, .light)
        .onChange(of: focused) { _, now in isEditing = now }
    }

    private enum Ink {
        static let main = Color(hex: 0x16141A)
        static let soft = Color(hex: 0x5E5A66)
        static let pink = Color(hex: 0xFF375F)
    }

    /// A few pastel hearts drifting in the corner, like the website's hero.
    private var hearts: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(Array([(0xFFB3C2, 20.0, -24.0, 12.0), (0xFFE9A6, 15.0, -58.0, 16.0), (0xCFE3FF, 13.0, -90.0, 9.0)].enumerated()), id: \.offset) { i, h in
                    Image(systemName: "heart.fill")
                        .font(.system(size: h.1))
                        .foregroundStyle(Color(hex: UInt32(h.0)))
                        .rotationEffect(.degrees(sin(t * 0.9 + Double(i)) * 12))
                        .offset(x: h.2, y: h.3 + sin(t * 1.2 + Double(i) * 2) * 4)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Conversation

    @ViewBuilder private var conversation: some View {
        let lines = Conversation.lines(mine: state.myOutbox, theirs: state.partnerOutbox)
        if lines.isEmpty {
            HStack(spacing: 10) {
                Image("pip-happy").resizable().scaledToFit().frame(width: 44)
                Text("No notes yet. Say something sweet to \(state.partnerName.lowercased()) ♡")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Ink.soft)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { reader in
                ScrollView {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        VStack(spacing: 8) {
                            ForEach(lines) { line in bubble(line, now: context.date).id(line.id) }
                        }
                        .padding(.vertical, 6)
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
            .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(Ink.soft.opacity(0.7))
        return HStack(alignment: .bottom, spacing: 6) {
            if line.isMine { Spacer(minLength: 70); ago }
            Text(line.message.text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(line.isMine ? .white : Ink.main)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(line.isMine ? Ink.pink : .white,
                            in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: line.isMine ? 18 : 5,
                                                       bottomTrailingRadius: line.isMine ? 5 : 18, topTrailingRadius: 18,
                                                       style: .continuous))
                .shadow(color: Color(hex: 0x5A1E32).opacity(line.isMine ? 0.18 : 0.08), radius: 6, y: 3)
            if !line.isMine { ago; Spacer(minLength: 70) }
        }
        .transition(.scale(scale: 0.8, anchor: line.isMine ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
    }

    // MARK: Composer

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("", text: $draft, prompt: Text("Say something sweet…").foregroundStyle(Ink.soft.opacity(0.7)))
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Ink.main)
                .focused($focused)
                .onSubmit(send)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(.white, in: Capsule())
                .overlay(Capsule().strokeBorder(highlightsField ? Ink.pink : Ink.main.opacity(0.08), lineWidth: highlightsField ? 1.5 : 1))
                .disabled(isLocked)
                .opacity(isLocked ? 0.5 : 1)

            Button(action: send) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(canSend ? Ink.pink : Ink.main.opacity(0.15), in: Circle())
                    .scaleEffect(canSend ? 1 : 0.92)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: canSend)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .help("Send")
        }
        .padding(.top, 8)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Text("Scroll").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Ink.soft)
            ForEach(BannerMode.allCases, id: \.self) { option in
                let selected = option == mode
                Button { mode = option } label: {
                    Text(option.label)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(selected ? .white : Ink.main)
                        .padding(.horizontal, 10)
                        .frame(height: 22)
                        .background(selected ? Ink.main : .white.opacity(0.7), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            status
        }
        .animation(.snappy(duration: 0.2), value: mode)
    }

    // MARK: Status and validation

    private var status: some View {
        let verdict = MessageRules.check(draft)
        let (text, color): (String, Color) = {
            if draft.isEmpty || isLocked, showsSendStatus, state.messageStatus != .none {
                switch state.messageStatus {
                case .delivered: return (state.messageStatus.label, Ink.pink)
                default: return (state.messageStatus.label, Ink.soft)
                }
            }
            if case .invalid(let hint) = verdict { return (hint, Ink.pink) }
            let words = MessageRules.wordCount(draft)
            return words > 0 ? (String(localized: "\(words) of \(Config.Message.maxWords) words"), Ink.soft)
                             : (String(localized: "Up to \(Config.Message.maxWords) words"), Ink.soft)
        }()
        return Text(text)
            .font(.system(size: 11.5, weight: .semibold, design: .rounded).monospacedDigit())
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
