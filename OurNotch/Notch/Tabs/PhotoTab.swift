import SwiftUI

/// Send your love a photo that shows on their Home. Empty state only until sending arrives in slice 6.
struct PhotoTab: View {
    let state: AppState

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.tertiaryLabel, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(width: 150, height: 150)
                .overlay {
                    Image(systemName: "photo.badge.plus").font(.system(size: 26)).foregroundStyle(Color.tertiaryLabel)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Photo").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.secondaryLabel)
                Text("Send \(state.partnerName.lowercased()) a photo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("It shows up on their Home the next time they open their notch ♡")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Choose Photo…") {}
                    .buttonStyle(NotchButtonStyle(prominent: true))
                    .disabled(true)
                    .help("Coming next")
                    .padding(.top, 10)
            }
        }
        .frame(maxHeight: .infinity)
        .cardStyle()
    }
}

/// Small native-style button inside the notch: prominent pink or bordered.
struct NotchButtonStyle: ButtonStyle {
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration, prominent: prominent)
    }

    private struct StyledButton: View {
        let configuration: Configuration
        let prominent: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(fill, in: RoundedRectangle(cornerRadius: 6))
                .opacity(isEnabled ? 1 : 0.4)
        }

        private var fill: Color {
            if prominent { return configuration.isPressed ? .notchPinkPressed : .notchPink }
            return .white.opacity(configuration.isPressed ? 0.2 : 0.14)
        }
    }
}
