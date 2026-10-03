import SwiftUI

/// Set how you're doing; it shows next to your little avatar in your love's closed notch.
struct MoodTab: View {
    let state: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 8)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Config.moods, id: \.emoji) { mood in
                    let selected = state.myOutbox.mood == mood.emoji
                    Button {
                        // Tapping your current mood again clears it.
                        state.setMood(selected ? nil : mood.emoji)
                    } label: {
                        VStack(spacing: 3) {
                            Text(mood.emoji).font(.system(size: 22))
                            Text(mood.label)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(selected ? Color.white : .secondaryLabel)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selected ? Color.notchPink.opacity(0.16) : .notchField, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if selected {
                                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.notchPink.opacity(0.6), lineWidth: 1)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
        .animation(.snappy(duration: 0.2), value: state.myOutbox.mood)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your mood").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                Text("Shows next to your photo on \(state.partnerName.lowercased())'s notch ♡")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.secondaryLabel)
            }
            Spacer()
            Group {
                if let current = Config.moods.first(where: { $0.emoji == state.myOutbox.mood }) {
                    Text("Now \(current.emoji) \(current.label)").foregroundStyle(.white)
                } else {
                    Text("Tap one to set").foregroundStyle(Color.tertiaryLabel)
                }
            }
            .font(.system(size: 11.5, weight: .medium))
        }
    }
}
