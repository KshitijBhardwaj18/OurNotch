import SwiftUI

/// The black shape at the top of the screen. Hovering opens it; leaving closes it.
///
/// Animation approach (learned from Boring Notch): the header row stays in place in both states,
/// and the open content is added below it. The spring is attached to the notch itself, and the
/// whole notch is flattened into one layer, so only the shape's size and corners animate.
struct NotchView: View {
    let state: AppState
    let effects: EmojiEffect
    let geometry: NotchGeometry

    @State private var isOpen = false
    @State private var tab: NotchTab = .home
    @State private var showsSettings = false
    @State private var isHovering = false
    /// True while the note field has focus; the notch stays open so typing isn't cut off.
    @State private var isEditing = false
    @State private var hoverTask: Task<Void, Never>?

    private typealias Radii = (top: CGFloat, bottom: CGFloat)
    private static let openRadii: Radii = (Config.Notch.openEarRadius, 24)
    private static let closedRadii: Radii = (6, 12)
    private static let bannerRadii: Radii = (6, 16)

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(effects.pours) { pour in
                PourView(floaters: pour.floaters).padding(.top, size.height)
            }
            notch
        }
        // Pin everything to the top-center of the (larger, transparent) panel.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.colorScheme, .dark)
    }

    private var notch: some View {
        VStack(spacing: 0) {
            NotchHeaderView(state: state, notchSize: geometry.notchSize, isOpen: isOpen, showsSettings: $showsSettings)
                .frame(height: closedHeight)

            if isOpen {
                OpenNotchView(state: state, tab: $tab, showsSettings: $showsSettings, isEditing: $isEditing)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94, anchor: .top)
                            .combined(with: .opacity)
                            .animation(.easeOut(duration: 0.22).delay(0.08)),
                        removal: .opacity.animation(.easeOut(duration: 0.12))))
            } else if let banner = state.visibleBanner {
                MessageBanner(message: banner, senderName: state.partnerName, onFinished: state.bannerFinished)
                    .id(banner.id) // a new note restarts the scroll
                    .frame(height: 20)
                    .padding(.horizontal, 12) // + the 6 pt ear = 18 pt from the edges
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, radii.top) // keep content clear of the curved ears
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(.black)
        .clipShape(NotchShape(topRadius: radii.top, bottomRadius: radii.bottom))
        .compositingGroup()
        .animation(Config.Notch.spring, value: isOpen)
        .animation(Config.Notch.spring, value: state.visibleBanner?.id)
        .contentShape(Rectangle())
        .onHover(perform: hoverChanged)
        .sensoryFeedback(.alignment, trigger: isOpen)
        .onChange(of: isOpen) { _, open in
            PerfMonitor.shared.track(open ? "notch open" : "notch close", seconds: 0.7)
            if open { state.notchOpened() } else { state.notchClosed(); showsSettings = false }
        }
        .onChange(of: tab) { _, tab in PerfMonitor.shared.track("\(tab) tab", seconds: 0.5) }
        .onChange(of: isEditing) { _, editing in
            if !editing && !isHovering { isOpen = false }
        }
    }

    private var radii: Radii {
        if isOpen { return Self.openRadii }
        return state.visibleBanner == nil ? Self.closedRadii : Self.bannerRadii
    }

    private var closedHeight: CGFloat { geometry.notchSize.height + Config.Notch.closedExtraHeight }

    private var size: CGSize {
        if isOpen { return Config.Notch.openSize }
        let width = geometry.notchSize.width + Config.Notch.closedSideWidth * 2 + Self.closedRadii.top * 2
        let bannerRoom = state.visibleBanner == nil ? 0 : Config.Message.bannerHeight
        return CGSize(width: width, height: closedHeight + bannerRoom)
    }

    /// Waits briefly before opening or closing so a mouse passing by doesn't flicker the notch.
    /// One cancellable task means only the latest hover change wins.
    private func hoverChanged(_ hovering: Bool) {
        isHovering = hovering
        hoverTask?.cancel()
        hoverTask = Task {
            try? await Task.sleep(for: hovering ? Config.Notch.hoverOpenDelay : Config.Notch.hoverCloseDelay)
            guard !Task.isCancelled, hovering || !isEditing else { return }
            isOpen = hovering
        }
    }
}
