import SwiftUI

/// Values that tune the app. Everything that might need adjusting lives here.
enum Config {
    /// Placeholder until onboarding asks "How long have you been together?" (slice 4).
    static let placeholderTogetherSince = Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 14))!

    enum Notch {
        /// Size of the black shape when the notch is open.
        static let openSize = CGSize(width: 440, height: 150)
        /// Width added on each side of the camera in the closed notch, for the days count and ♡.
        static let closedSideWidth: CGFloat = 44
        /// Used on Macs without a notch.
        static let pillSize = CGSize(width: 185, height: 32)
        /// Extra transparent room around the open shape, so springs can overshoot without clipping.
        static let windowPadding: CGFloat = 20

        static let hoverOpenDelay: Duration = .milliseconds(300)
        static let hoverCloseDelay: Duration = .milliseconds(100)
    }
}

/// OurNotch's colors (`spec.md > Look and Feel`).
extension Color {
    static let rose = Color(red: 1.0, green: 0x7A / 255, blue: 0xA2 / 255)
    static let blush = Color(red: 1.0, green: 0xC2 / 255, blue: 0xD4 / 255)
}
