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
                                .foregroundStyle(selected ? Color.white : .secondaryLabel)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 68)
                        .background(selected ? Color.notchPressed : .notchField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            if selected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.notchPink.opacity(0.6), lineWidth: 1)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .notchHint(selected ? String(localized: "Tap again to clear your mood")
                                   : String(localized: "Tell \(state.partnerName.lowercased()) you're feeling \(mood.label.lowercased())"))
                }
            }
        }
        .cardStyle()
        .animation(.snappy(duration: 0.2), value: state.myOutbox.mood)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your mood").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Shows next to your photo on \(state.partnerName.lowercased())'s notch ♡")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.secondaryLabel)
            }
            Spacer()
            // Their mood, so you can answer it with yours.
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(state.partnerName.lowercased())'s mood").foregroundStyle(Color.secondaryLabel)
                if let mood = state.partnerOutbox.mood {
                    Text(verbatim: "\(mood) \((Config.moodLabel(mood) ?? "").lowercased())")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("Not set yet").foregroundStyle(Color.tertiaryLabel)
                }
            }
            .font(.system(size: 11.5, weight: .medium))
        }
    }
}
