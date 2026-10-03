import SwiftUI

/// How photos are tinted inside the notch so any photo sits calmly on black. Chosen in Settings.
enum PhotoStyle: String, CaseIterable {
    case soft, mono, original

    var label: String {
        switch self {
        case .soft: "Soft"
        case .mono: "Mono"
        case .original: "Original"
        }
    }

    /// Remembered between launches.
    static let storageKey = "photoStyle"
}

/// A photo filling its frame with the chosen treatment: muted color, a pink soft-light wash,
/// a fade into the card color at the bottom, and a faint inner edge.
struct TreatedPhoto: View {
    let image: NSImage
    var cornerRadius: CGFloat = 12
    @AppStorage(PhotoStyle.storageKey) private var style: PhotoStyle = .soft

    var body: some View {
        Color.clear
            .overlay {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .modifier(Filter(style: style))
            }
            .overlay { wash }
            .overlay(alignment: .bottom) { fade }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
    }

    @ViewBuilder private var wash: some View {
        switch style {
        case .soft: Color.notchPink.opacity(0.22).blendMode(.softLight)
        case .mono: Color.notchPink.opacity(0.35).blendMode(.softLight)
        case .original: EmptyView()
        }
    }

    @ViewBuilder private var fade: some View {
        if style != .original {
            GeometryReader { box in
                LinearGradient(colors: [.clear, Color.notchCard.opacity(style == .soft ? 0.55 : 0.5)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: box.size.height * 0.45)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private struct Filter: ViewModifier {
        let style: PhotoStyle

        func body(content: Content) -> some View {
            switch style {
            case .soft: content.saturation(0.75).brightness(-0.06).contrast(1.05)
            case .mono: content.grayscale(1).contrast(1.08).brightness(-0.05)
            case .original: content
            }
        }
    }
}
