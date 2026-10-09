import SwiftUI

/// Set how you're doing; it shows next to your little avatar in your love's closed notch.
struct MoodTab: View {
    let state: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 8)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Config.moods, id: \.emoji) { mood in
                    let selected = state.myOutbox.mood == mood.emoji
                    Button {
                        // Tapping your current mood again clears it.
                        state.setMood(selected ? nil : mood.emoji)
                    } label: {
                        VStack(spacing: 3) {
                            Text(mood.emoji).font(.system(size: 26))
                            Text(mood.label)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(selected ? Color.notchPink : .pastelInk2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(selected ? Color.pastelBlush : .white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color(hex: 0x5A1E32).opacity(0.07), radius: 4, y: 2)
                        .overlay {
                            if selected {
                                RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.notchPink.opacity(0.7), lineWidth: 1.5)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .pastelCard(Color.pastelMint)
        .animation(.snappy(duration: 0.2), value: state.myOutbox.mood)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your mood").pastelTitle()
                Text("Shows next to your photo on \(state.partnerName.lowercased())'s notch ♡")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.pastelInk2)
            }
            Spacer()
            Group {
                if let current = Config.moods.first(where: { $0.emoji == state.myOutbox.mood }) {
                    Text("Now \(current.emoji) \(current.label)").foregroundStyle(Color.pastelInk)
                } else {
                    Text("Tap one to set").foregroundStyle(Color.pastelInk3)
                }
            }
            .font(.system(size: 11.5, weight: .medium))
        }
    }
}
