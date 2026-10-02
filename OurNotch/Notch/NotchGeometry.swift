import AppKit

/// Where the notch is and how big it is.
struct NotchGeometry: Equatable {
    let screenFrame: CGRect
    /// Size of the real camera notch, or the pill on Macs without one.
    let notchSize: CGSize
    let hasNotch: Bool

    /// Measures the screen with a notch. `NSScreen.main` is the screen with the focused window,
    /// not the built-in display, so we look for the notch instead and fall back to the main screen.
    static func current() -> NotchGeometry? {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 })
                ?? NSScreen.main ?? NSScreen.screens.first else { return nil }

        if screen.safeAreaInsets.top > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let width = screen.frame.width - left.width - right.width
            return NotchGeometry(screenFrame: screen.frame,
                                 notchSize: CGSize(width: width, height: screen.safeAreaInsets.top),
                                 hasNotch: true)
        }
        return NotchGeometry(screenFrame: screen.frame, notchSize: Config.Notch.pillSize, hasNotch: false)
    }

    /// The panel's frame: fixed at the open size plus padding, pinned top-center.
    var panelFrame: CGRect {
        let size = CGSize(width: Config.Notch.openSize.width + Config.Notch.windowPadding * 2,
                          height: Config.Notch.openSize.height + Config.Notch.windowPadding)
        return CGRect(x: screenFrame.midX - size.width / 2,
                      y: screenFrame.maxY - size.height,
                      width: size.width, height: size.height)
    }
}
