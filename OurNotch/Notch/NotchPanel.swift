import AppKit

/// A transparent, borderless window that floats above the menu bar, right over the notch.
/// It never resizes; only the SwiftUI shape inside it grows and shrinks.
final class NotchPanel: NSPanel {
    init(frame: CGRect) {
        super.init(contentRect: frame,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        appearance = NSAppearance(named: .darkAqua)
    }

    // Lets the message field take typing later (slice 3) while staying non-activating,
    // so the user's current app stays in front.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
