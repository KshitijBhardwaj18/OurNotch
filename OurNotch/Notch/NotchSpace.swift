import AppKit

// WindowServer's private space calls (SkyLight), the technique notch apps use to stay on top.
// Fine for a Developer ID app; the App Store wouldn't allow them.
private typealias CGSConnectionID = UInt
private typealias CGSSpaceID = UInt64
@_silgen_name("_CGSDefaultConnection") private func _CGSDefaultConnection() -> CGSConnectionID
@_silgen_name("CGSSpaceCreate") private func CGSSpaceCreate(_ cid: CGSConnectionID, _ flags: Int, _ options: NSDictionary?) -> CGSSpaceID
@_silgen_name("CGSSpaceSetAbsoluteLevel") private func CGSSpaceSetAbsoluteLevel(_ cid: CGSConnectionID, _ space: CGSSpaceID, _ level: Int)
@_silgen_name("CGSShowSpaces") private func CGSShowSpaces(_ cid: CGSConnectionID, _ spaces: NSArray)
@_silgen_name("CGSAddWindowsToSpaces") private func CGSAddWindowsToSpaces(_ cid: CGSConnectionID, _ windows: NSArray, _ spaces: NSArray)

/// A space of our own above every other space, the menu bar and full-screen apps. A window in it stays
/// put whichever app is in front: an ordinary floating panel can vanish when another app (WhatsApp, or
/// anything full screen) takes over its Space.
// ponytail: private API; if a macOS update breaks it, the panel still has its own level and Spaces
// behavior, and only full-screen apps can cover it again.
@MainActor
enum NotchSpace {
    private static let connection = _CGSDefaultConnection()
    private static let id: CGSSpaceID = {
        let space = CGSSpaceCreate(connection, 0x1, nil) // flag 1: a plain space (no desktop icons drawn in it)
        CGSSpaceSetAbsoluteLevel(connection, space, Int(Int32.max))
        CGSShowSpaces(connection, [space] as NSArray)
        return space
    }()

    /// Moves the window into the notch space. Safe to call again.
    static func add(_ window: NSWindow) {
        guard window.windowNumber > 0 else { return }
        CGSAddWindowsToSpaces(connection, [window.windowNumber] as NSArray, [id] as NSArray)
    }
}
