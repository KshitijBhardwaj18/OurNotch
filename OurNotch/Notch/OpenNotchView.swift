import SwiftUI

/// The part of the notch that grows below the header when it opens: time together counting up live,
/// the heart button, a message box, and the last message from your love.
struct OpenNotchView: View {
    let state: AppState
    let effects: HeartsEffect
    @Binding var isEditing: Bool

    @State private var draft = ""
    @State private var mode: BannerMode = .three
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                timeTogether
                Spacer()
                VStack(spacing: 4) {
                    heartButton
                    statusText(state.heartStatus.label)
                }
            }
            composer
            footer
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity)
        .onChange(of: fieldFocused) { _, focused in isEditing = focused }
    }

    // MARK: Time and hearts

    private var timeTogether: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("together for")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            // Ticks every second, only while the notch is open.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(state.togetherSince.map { Self.counter(Together.elapsed(since: $0, now: context.date)) } ?? "…")
                    .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.blush)
            }
        }
    }

    private var heartButton: some View {
        Button {
            state.sendHeart()
            effects.pour()
        } label: {
            Image(systemName: "heart.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.rose)
                .frame(width: 52, height: 52)
                .background(Color.rose.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Messages

    private var composer: some View {
        HStack(spacing: 6) {
            TextField("say something sweet…", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white)
                .focused($fieldFocused)
                .onSubmit(send)

            Button(mode.label) { mode = mode.toggled }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.blush)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.white.opacity(0.08), in: Capsule())
                .help("How it scrolls on your love's notch")

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .foregroundStyle(canSend ? Color.rose : .white.opacity(0.25))
            .disabled(!canSend)
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .frame(height: 28)
        .background(.white.opacity(0.08), in: Capsule())
    }

    private var footer: some View {
        HStack {
            Text(state.partnerOutbox.message.map { "♡ \($0.text)" } ?? "no messages yet")
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            if let hint {
                Text(hint).foregroundStyle(Color.blush)
            } else {
                statusText(state.messageStatus.label)
            }
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .padding(.horizontal, 6)
    }

    private var canSend: Bool {
        if case .valid = MessageRules.check(draft) { true } else { false }
    }

    private var hint: String? {
        if case .invalid(let hint) = MessageRules.check(draft) { hint } else { nil }
    }

    private func send() {
        guard state.sendMessage(draft, mode: mode) else { return }
        draft = ""
        fieldFocused = false
    }

    // MARK: Helpers

    private func statusText(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.6))
            .frame(height: 12)
    }

    private static func counter(_ c: DateComponents) -> String {
        String(format: "%dd %02dh %02dm %02ds", c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
