import SwiftUI

/// Values that tune the app. Everything that might need adjusting lives here.
/// Sizes, colors and timings follow `devpost/design_handoff/README.md`.
enum Config {
    /// Rapid emoji taps within this pause are bundled into one save.
    static let emojiBundleDelay: Duration = .seconds(1)
    /// The one-tap emojis on the Emoji tab.
    static let emojis = ["❤️", "🥰", "😘", "🫶", "🤗", "🌹"]

    enum Pairing {
        /// How often the inviter checks whether their love has joined, while the waiting screen is open.
        static let joinCheckInterval: Duration = .seconds(3)
        static let codeLength = 6
        /// Linked from the invite email. Placeholder until the website exists.
        static let downloadURL = "https://github.com/KshitijBhardwaj18/OurNotch/releases"
    }

    enum Message {
        static let maxWords = 10
        static let maxCharacters = 60
        static let maxWordLength = 15
        /// How fast the banner scrolls, in points per second.
        static let bannerSpeed: CGFloat = 40
        /// Height the closed notch grows by while a banner is showing.
        static let bannerHeight: CGFloat = 22
    }

    enum Notch {
        /// The tab content area inside the open notch.
        static let contentSize = CGSize(width: 500, height: 200)
        /// Space between the notch's black edge and its content, on every side.
        static let margin: CGFloat = 20
        /// The curved "ears" at the top corners of the open notch. They sit inside the frame,
        /// so the black body is this much narrower on each side.
        static let openEarRadius: CGFloat = 14
        static let openSize = CGSize(width: contentSize.width + (margin + openEarRadius) * 2, height: 296)
        /// Width of the slots on each side of the camera in the closed notch, for the days count and ♥.
        static let closedSideWidth: CGFloat = 52
        /// How far the closed shape reaches below the menu bar, so it fully covers the camera housing.
        static let closedExtraHeight: CGFloat = 2
        /// Used on Macs without a notch.
        static let pillSize = CGSize(width: 180, height: 32)
        /// Extra transparent room around the open shape, so springs can overshoot without clipping.
        static let windowPadding: CGFloat = 20
        /// Transparent room below the open shape where hearts and emojis pour out.
        static let pourRoom: CGFloat = 160

        static let hoverOpenDelay: Duration = .milliseconds(300)
        /// Hover intent: the notch waits this long after the pointer leaves before closing.
        static let hoverCloseDelay: Duration = .milliseconds(350)
        static let spring = Animation.spring(response: 0.45, dampingFraction: 0.7)
    }
}

/// Colors inside the notch, which is always dark (`design_handoff/README.md > Design tokens`).
extension Color {
    static let notchPink = Color(hex: 0xFF375F)
    static let notchPinkPressed = Color(hex: 0xD92D50)
    static let notchBlush = Color(hex: 0xFFB3C2)
    static let notchCard = Color(hex: 0x1C1C1E)
    static let notchField = Color(hex: 0x2C2C2E)
    static let notchPressed = Color(hex: 0x3A3A3C)
    static let segmentTrack = Color(hex: 0x767680).opacity(0.24)
    static let segmentSelected = Color(hex: 0x636366)
    static let separator = Color.white.opacity(0.08)
    static let secondaryLabel = Color(hex: 0xEBEBF5).opacity(0.6)
    static let tertiaryLabel = Color(hex: 0xEBEBF5).opacity(0.3)

    init(hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
