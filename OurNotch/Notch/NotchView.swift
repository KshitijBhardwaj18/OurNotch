import SwiftUI

/// The black shape at the top of the screen. Hovering opens it; leaving closes it.
struct NotchView: View {
    let state: AppState
    let effects: HeartsEffect
    let geometry: NotchGeometry

    @State private var isOpen = false
    @State private var hoverTask: Task<Void, Never>?

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
        content
            .padding(.horizontal, radii.top)
            .frame(width: size.width, height: size.height)
            .background(.black)
            .clipShape(NotchShape(topRadius: radii.top, bottomRadius: radii.bottom))
            .onHover(perform: hoverChanged)
            .sensoryFeedback(.alignment, trigger: isOpen)
    }

    @ViewBuilder private var content: some View {
        if isOpen {
            OpenNotchView(state: state, effects: effects, notchSize: geometry.notchSize)
                .transition(.scale(scale: 0.85, anchor: .top).combined(with: .opacity))
        } else {
            ClosedNotchView(state: state, notchSize: geometry.notchSize)
                .transition(.opacity)
        }
    }

    private var radii: (top: CGFloat, bottom: CGFloat) {
        isOpen ? (top: 14, bottom: 24) : (top: 6, bottom: 12)
    }

    private var size: CGSize {
        if isOpen { return Config.Notch.openSize }
        let width = geometry.notchSize.width + Config.Notch.closedSideWidth * 2 + radii.top * 2
        return CGSize(width: width, height: geometry.notchSize.height)
    }

    /// Waits briefly before opening or closing so a mouse passing by doesn't flicker the notch.
    /// One cancellable task means only the latest hover change wins.
    private func hoverChanged(_ hovering: Bool) {
        hoverTask?.cancel()
        hoverTask = Task {
            try? await Task.sleep(for: hovering ? Config.Notch.hoverOpenDelay : Config.Notch.hoverCloseDelay)
            guard !Task.isCancelled, isOpen != hovering else { return }
            withAnimation(hovering ? .spring(response: 0.42, dampingFraction: 0.8)
                                   : .spring(response: 0.45, dampingFraction: 1.0)) {
                isOpen = hovering
            }
        }
    }
}
