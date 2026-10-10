import AppKit

/// Where the notch is and how big it is.
struct NotchGeometry: Equatable {
    let screenFrame: CGRect
    /// Size of the real camera notch, or the pill on Macs without one.
    let notchSize: CGSize
    let hasNotch: Bool
    /// The closed notch's height: covers the camera, but never reaches below the menu bar onto app windows.
    let closedHeight: CGFloat

    /// Measures the screen with a notch. `NSScreen.main` is the screen with the focused window,
    /// not the built-in display, so we look for the notch instead and fall back to the main screen.
    static func current() -> NotchGeometry? {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 })
                ?? NSScreen.main ?? NSScreen.screens.first else { return nil }

        // 0 while the menu bar hides itself (full screen, or "automatically hide").
        let menuBar = screen.frame.maxY - screen.visibleFrame.maxY
        if screen.safeAreaInsets.top > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let width = screen.frame.width - left.width - right.width
            let notch = screen.safeAreaInsets.top
            let covering = notch + Config.Notch.closedExtraHeight
            return NotchGeometry(screenFrame: screen.frame,
                                 notchSize: CGSize(width: width, height: notch),
                                 hasNotch: true,
                                 closedHeight: menuBar > 0 ? min(covering, max(menuBar, notch)) : covering)
        }
        // No camera to cover: the pill is exactly as tall as the menu bar (24 pt on most Macs).
        let pill = CGSize(width: Config.Notch.pillSize.width, height: menuBar > 0 ? menuBar : Config.Notch.pillSize.height)
        return NotchGeometry(screenFrame: screen.frame, notchSize: pill, hasNotch: false, closedHeight: pill.height)
    }

    /// The panel's frame: fixed at the open size plus padding and room for pouring hearts, pinned top-center.
    /// The extra area is transparent, so clicks pass through it.
    var panelFrame: CGRect {
        let size = CGSize(width: Config.Notch.openSize.width + Config.Notch.windowPadding * 2,
                          height: Config.Notch.openSize.height + Config.Notch.pourRoom)
        return CGRect(x: screenFrame.midX - size.width / 2,
                      y: screenFrame.maxY - size.height,
                      width: size.width, height: size.height)
    }
}
