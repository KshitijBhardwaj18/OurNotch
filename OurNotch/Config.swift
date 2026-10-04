import SwiftUI

/// Values that tune the app. Everything that might need adjusting lives here.
/// Sizes, colors and timings follow `devpost/design_handoff/README.md`.
enum Config {
    /// Rapid emoji taps within this pause are bundled into one save.
    static let emojiBundleDelay: Duration = .seconds(1)
    /// The one-tap emojis on the Emoji tab.
    static let emojis = ["❤️", "🥰", "😘", "🫶", "🤗", "🌹"]
    /// Moods for the Mood tab: the emoji travels; the label explains it.
    static let moods: [(emoji: String, label: String)] = [
        ("🥰", "In love"), ("😊", "Happy"), ("🥺", "Missing you"), ("🎉", "Excited"), ("☕️", "On a break"), ("🍕", "Hungry"),
        ("💻", "Busy"), ("🎧", "Focused"), ("🏃", "Out"), ("😴", "Sleepy"), ("😔", "Low"), ("🤒", "Unwell"),
    ]

    enum Cloud {
        /// Throwaway container on the company team; swap for your own account's container before selling.
        static let containerId = "iCloud.com.kshitijbhardwaj.OurNotch.dev"
        /// Safety-net check when no ping arrives. Debug builds check every 3 s, because pings don't reach
        /// the Mac that made the change, so the notch and Partner Simulator on one Mac must poll each other.
        #if DEBUG
        static let pollInterval: Duration = .seconds(3)
        #else
        // Pings should deliver within seconds; this catches lost ones. One request per check.
        static let pollInterval: Duration = .seconds(60)
        #endif
        /// Checks while the notch is open or within `activeWindow` of sending or receiving, because pings
        /// often don't arrive. At 1,000 users with ~10 % active: 900/60 + 100/10 ≈ 25 requests/s,
        /// under CloudKit's ~40/s free starting allowance.
        static let activePollInterval: Duration = .seconds(10)
        static let activeWindow: TimeInterval = 180
    }

    enum Diagnostics {
        /// Upload this Mac's event log to CloudKit so both partners' logs can be read from either Mac.
        static let uploads = true
        /// Lines kept in memory and uploaded (~150 KB; a CloudKit record holds 1 MB).
        static let maxLines = 1000
        /// The on-disk log starts fresh past this size, keeping one previous file.
        static let maxFileBytes = 5_000_000
        static let uploadInterval: Duration = .seconds(15)
        /// How often both Macs' logs and metrics are downloaded into ~/Library/Logs/OurNotch/.
        static let exportInterval: Duration = .seconds(120)
    }

    enum Licence {
        // ponytail: every build uses Dodo's test mode until slice 9 adds the sold Release build with live values.
        /// Dodo's public licence endpoints (activate / validate / deactivate need no API key).
        static let baseURL = URL(string: "https://test.dodopayments.com")!
        static let productId = "pdt_0Np1n3lC4hykWhTwMaNVV"
        #if DEBUG
        static let website = "http://localhost:3000"
        #else
        static let website = "https://ournotch.app"
        #endif
        /// Dodo's hosted checkout; it picks $4.50 / ₹200 / €3 from the buyer's currency, then returns to the
        /// thank-you page with `license_key`, whose Open OurNotch button activates this app.
        static let checkoutURL = URL(string: "https://test.checkout.dodopayments.com/buy/\(productId)?quantity=1&redirect_url=\(website)/thanks")!
        /// The price on the gate. The Mac doesn't know the buyer's country, so checkout shows the local price.
        static let priceLabel = "$4.50"
        /// Dodo's customer portal: the buyer enters their purchase email and sees their key.
        static let portalURL = URL(string: "https://test.customer.dodopayments.com/login/bus_0Np1laPQgg48PHzDsmzgI")!
        /// How often each Mac asks Dodo "still valid?" (also on launch and wake). Revocation lands within a day.
        static let checkInterval: Duration = .seconds(24 * 60 * 60)
        /// Placeholder until the learner picks the support address.
        static let supportEmail = "hello@ournotch.app"
    }

    enum Pairing {
        /// How often the inviter checks whether their love has joined, while the waiting screen is open.
        static let joinCheckInterval: Duration = .seconds(3)
        static let codeLength = 6
        /// Codes work for a day, so an old code in an email can't pair someone later.
        static let codeLifetime: TimeInterval = 24 * 60 * 60
        /// Linked from the invite email.
        static let downloadURL = "\(Licence.website)/download"
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
        /// Width of the slots on each side of the camera in the closed notch: avatar + mood on the left, ♥ on the right.
        static let closedSideWidth: CGFloat = 60
        /// Space between the closed notch's curved edge and its content.
        static let closedInset: CGFloat = 10
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
