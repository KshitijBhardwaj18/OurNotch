import SwiftUI

/// The black shape at the top of the screen. Hovering opens it; leaving closes it.
///
/// Animation approach (learned from Boring Notch): the header row stays in place in both states,
/// and the open content is added below it. The spring is attached to the notch itself, and the
/// whole notch is flattened into one layer, so only the shape's size and corners animate.
struct NotchView: View {
    let state: AppState
    let effects: HeartsEffect
    let geometry: NotchGeometry

    @State private var isOpen = false
    @State private var hoverTask: Task<Void, Never>?

    private static let openRadii: (top: CGFloat, bottom: CGFloat) = (14, 24)
    private static let closedRadii: (top: CGFloat, bottom: CGFloat) = (6, 12)
    private static let openSpring = Animation.spring(response: 0.42, dampingFraction: 0.8)
    private static let closeSpring = Animation.spring(response: 0.45, dampingFraction: 1.0)

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(effects.pours) { pour in
                PourView(hearts: pour.hearts).padding(.top, size.height)
            }
            notch
        }
        // Pin everything to the top-center of the (larger, transparent) panel.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var notch: some View {
        VStack(spacing: 0) {
            NotchHeaderView(state: state, notchSize: geometry.notchSize)
                .frame(height: closedHeight)

            if isOpen {
                OpenNotchView(state: state, effects: effects)
                    .padding(.bottom, 12)
                    .transition(.scale(scale: 0.8, anchor: .top)
                        .combined(with: .opacity)
                        .animation(.smooth(duration: 0.35)))
            }
        }
        .padding(.horizontal, radii.top) // keep content clear of the curved ears
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(.black)
        .clipShape(NotchShape(topRadius: radii.top, bottomRadius: radii.bottom))
        .compositingGroup()
        .animation(isOpen ? Self.openSpring : Self.closeSpring, value: isOpen)
        .contentShape(Rectangle())
        .onHover(perform: hoverChanged)
        .sensoryFeedback(.alignment, trigger: isOpen)
    }

    private var radii: (top: CGFloat, bottom: CGFloat) { isOpen ? Self.openRadii : Self.closedRadii }

    private var closedHeight: CGFloat { geometry.notchSize.height + Config.Notch.closedExtraHeight }

    private var size: CGSize {
        if isOpen { return Config.Notch.openSize }
        let width = geometry.notchSize.width + Config.Notch.closedSideWidth * 2 + Self.closedRadii.top * 2
        return CGSize(width: width, height: closedHeight)
    }

    /// Waits briefly before opening or closing so a mouse passing by doesn't flicker the notch.
    /// One cancellable task means only the latest hover change wins.
    private func hoverChanged(_ hovering: Bool) {
        hoverTask?.cancel()
        hoverTask = Task {
            try? await Task.sleep(for: hovering ? Config.Notch.hoverOpenDelay : Config.Notch.hoverCloseDelay)
            guard !Task.isCancelled else { return }
            isOpen = hovering
        }
    }
}
