import SwiftUI

/// Values that tune the app. Everything that might need adjusting lives here.
enum Config {
    /// Placeholder until onboarding asks "How long have you been together?" (slice 4).
    static let placeholderTogetherSince = Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 14))!

    /// Rapid heart taps within this pause are bundled into one save.
    static let heartBundleDelay: Duration = .seconds(1)

    enum Message {
        static let maxWords = 10
        static let maxCharacters = 60
        static let maxWordLength = 15
        /// How fast the banner scrolls, in points per second.
        static let bannerSpeed: CGFloat = 35
        /// Height the closed notch grows by while a banner is showing.
        static let bannerHeight: CGFloat = 22
    }

    enum Notch {
        /// Size of the black shape when the notch is open.
        static let openSize = CGSize(width: 440, height: 196)
        /// Width added on each side of the camera in the closed notch, for the days count and ♡.
        static let closedSideWidth: CGFloat = 44
        /// How far the closed shape reaches below the menu bar, so it fully covers the camera housing.
        static let closedExtraHeight: CGFloat = 2
        /// Used on Macs without a notch.
        static let pillSize = CGSize(width: 185, height: 32)
        /// Extra transparent room around the open shape, so springs can overshoot without clipping.
        static let windowPadding: CGFloat = 20
        /// Transparent room below the open shape where hearts pour out.
        static let pourRoom: CGFloat = 160

        static let hoverOpenDelay: Duration = .milliseconds(300)
        static let hoverCloseDelay: Duration = .milliseconds(100)
    }
}

/// OurNotch's colors (`spec.md > Look and Feel`).
extension Color {
    static let rose = Color(red: 1.0, green: 0x7A / 255, blue: 0xA2 / 255)
    static let blush = Color(red: 1.0, green: 0xC2 / 255, blue: 0xD4 / 255)
}
