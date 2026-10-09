import SwiftUI

/// Values that tune the app. Everything that might need adjusting lives here.
/// Sizes, colors and timings follow `devpost/design_handoff/README.md`.
enum Config {
    /// Rapid emoji taps within this pause are bundled into one save.
    static let emojiBundleDelay: Duration = .seconds(1)
    /// The one-tap emojis on the Emoji tab.
    static let emojis = ["❤️", "🥰", "😘", "💋", "🫶", "🤗", "🌹"]
    /// Moods for the Mood tab: the emoji travels; the label explains it.
    static let moods: [(emoji: String, label: String)] = [
        ("🥰", String(localized: "In love")), ("😊", String(localized: "Happy")), ("🥺", String(localized: "Missing you")), ("🎉", String(localized: "Excited")), ("☕️", String(localized: "On a break")), ("🍕", String(localized: "Hungry")),
        ("💻", String(localized: "Busy")), ("🎧", String(localized: "Focused")), ("🏃", String(localized: "Out")), ("😴", String(localized: "Sleepy")), ("😔", String(localized: "Low")), ("🤒", String(localized: "Unwell")),
    ]

    /// The word for a mood emoji, in this Mac's language (only the emoji travels between Macs).
    static func moodLabel(_ emoji: String) -> String? { moods.first { $0.emoji == emoji }?.label }

    enum Cloud {
        /// Throwaway container on the company team; swap for your own account's container before selling.
        static let containerId = "iCloud.app.ournotch.OurNotch"
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
        /// Upload this Mac's event log and measurements to CloudKit so both partners' logs can be read from
        /// either Mac. Debug and Beta (test couples) only: the sold Release build keeps its log on the Mac.
        #if DEBUG || BETA
        static let uploads = true
        #else
        static let uploads = false
        #endif
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
        /// Dodo's hosted checkout; it picks $4.50 / ₹499 / €3 from the buyer's currency, then returns to the
        /// thank-you page with `license_key`, whose Open OurNotch button activates this app.
        static let checkoutURL = URL(string: "https://test.checkout.dodopayments.com/buy/\(productId)?quantity=1&redirect_url=\(website)/thanks")!
        /// The price on the gate. The Mac doesn't know the buyer's country, so checkout shows the local price.
        static let priceLabel = "$4.50"
        /// Dodo's customer portal: the buyer enters their purchase email and sees their key.
        static let portalURL = URL(string: "https://test.customer.dodopayments.com/login/bus_0Np1laPQgg48PHzDsmzgI")!
        /// How often each Mac asks Dodo "still valid?" (also on launch, wake, and opening the notch), so a revoke
        /// lands within the hour. One small request per Mac per hour; Dodo's validate call is free.
        static let checkInterval: Duration = .seconds(60 * 60)
        /// Opening the notch checks too, at most this often.
        #if DEBUG
        static let openCheckGap: TimeInterval = 10
        #else
        static let openCheckGap: TimeInterval = 5 * 60
        #endif
        /// The terms (why a licence can be revoked), in the app's language.
        static var termsURL: URL {
            let lang = Bundle.main.preferredLocalizations.first ?? "en"
            return URL(string: "\(website)\(["fr", "de"].contains(lang) ? "/\(lang)" : "")/terms")!
        }
        /// Placeholder until the learner picks the support address.
        static let supportEmail = "hello@ournotch.app"
    }

    enum Pairing {
        /// How often the inviter checks whether their love has joined, while the waiting screen is open.
        static let joinCheckInterval: Duration = .seconds(3)
        static let codeLength = 6
        /// Codes work for a day, so an old code in an email can't pair someone later.
        static let codeLifetime: TimeInterval = 24 * 60 * 60
        /// Join requests one code can hold, so a wrong person can't use up a code (spare slots for the right one).
        static let joinSlots = 5
        /// Linked from the invite email.
        static let downloadURL = "\(Licence.website)/download"
    }

    enum Message {
        static let maxWords = 10
        static let maxCharacters = 60
        static let maxWordLength = 15
        /// Notes each of you keeps, so the Note tab reads as a tiny conversation (older ones drop off).
        static let historyCount = 10
        /// How fast the banner scrolls, in points per second.
        static let bannerSpeed: CGFloat = 40
        /// Height the closed notch grows by while a banner is showing.
        static let bannerHeight: CGFloat = 22
    }

    enum Notch {
        /// The tab content area inside the open notch.
        static let contentSize = CGSize(width: 580, height: 240)
        /// Space between the notch's black edge and its content, on every side.
        static let margin: CGFloat = 20
        /// The curved "ears" at the top corners of the open notch. They sit inside the frame,
        /// so the black body is this much narrower on each side.
        static let openEarRadius: CGFloat = 14
        static let openSize = CGSize(width: contentSize.width + (margin + openEarRadius) * 2, height: 350)
        /// Width of the slots on each side of the camera in the closed notch: avatar + mood on the left, ♥ on the right.
        static let closedSideWidth: CGFloat = 60
        /// The same slots while your love has a mood: it sits on the right ("🥺 missing you"), and both
        /// sides grow so the notch stays centred on the camera.
        static let closedSideWidthWithMood: CGFloat = 104
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

    // The open notch's pastel pages, in the website's colours (each tab has its own).
    static let pastelInk = Color(hex: 0x16141A)
    static let pastelInk2 = Color(hex: 0x5E5A66)
    static let pastelInk3 = Color(hex: 0x5E5A66).opacity(0.6)
    static let pastelCream = Color(hex: 0xFFF0E6)
    static let pastelBlush = Color(hex: 0xFFD3DC)
    static let pastelButter = Color(hex: 0xFFE9A6)
    static let pastelSky = Color(hex: 0xCFE3FF)
    static let pastelMint = Color(hex: 0xCFEFDF)
    static let pastelMist = Color(hex: 0xF5F4F1)

    init(hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
