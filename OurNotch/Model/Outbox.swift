import Foundation

/// One partner's row in the shared mailbox. Only its owner writes it; the partner reads it.
struct Outbox: Codable, Equatable {
    /// Set by the inviter only; the joiner reads it from here.
    var togetherSince: Date?
    /// Running total of emojis this partner has sent. Never goes down.
    var emojisSent = 0
    /// The most recent emoji and how it should appear. Earlier ones aren't kept.
    var lastEmoji: SentEmoji?
    /// The partner's `emojisSent` value this Mac has already shown. Tells the sender "delivered".
    var seenEmojis = 0
    /// The latest note sent. Only the last one is kept; there's no history.
    var message: Message?
    /// The partner's note this Mac has already shown.
    var seenMessageId: UUID?
    /// The latest photo sent. The image itself travels separately, encrypted, as its own record.
    var photo: SentPhoto?
    /// The partner's photo this Mac has already downloaded.
    var seenPhotoId: UUID?
    /// My current mood emoji, shown beside my avatar in my partner's closed notch. Nil when cleared.
    var mood: String?
    /// The buyer's licence key, so the partner's Mac can ask Dodo whether it's still valid (no slot used).
    var licenceKey: String?
}

struct SentPhoto: Codable, Equatable {
    let id: UUID
    let sentAt: Date
}

struct SentEmoji: Codable, Equatable {
    let char: String
    let mode: EmojiMode
    /// When it was tapped, so the log can show how long delivery took. Nil from older builds.
    var sentAt: Date?
}

/// Where an emoji appears on the partner's screen. The sender chooses.
enum EmojiMode: String, Codable, CaseIterable {
    case notch, fullScreen

    var label: String {
        switch self {
        case .notch: "Out of the notch"
        case .fullScreen: "Full screen"
        }
    }

    var symbol: String {
        switch self {
        case .notch: "chevron.down"
        case .fullScreen: "arrow.up.left.and.arrow.down.right"
        }
    }
}

struct Message: Codable, Equatable {
    let id: UUID
    let text: String
    let mode: BannerMode
    let sentAt: Date
}

/// How the note scrolls on the partner's notch. The sender chooses.
enum BannerMode: String, Codable, CaseIterable {
    /// Scrolls 3 times, then disappears.
    case three
    /// Keeps scrolling until the partner opens the notch.
    case untilOpened

    var label: String {
        switch self {
        case .three: "3 times"
        case .untilOpened: "Until opened"
        }
    }
}

/// How arriving emojis are shown, kept pure for tests.
enum Arrival {
    enum Effect: Equatable { case pour, splash }

    /// Emojis the partner sent that this Mac hasn't shown yet.
    static func newCount(partnerSent: Int, lastShown: Int) -> Int {
        max(0, partnerSent - lastShown)
    }

    /// The sender's choice decides, except that 3 or more arriving at once (missed while away) always splash.
    static func effect(forNew count: Int, mode: EmojiMode) -> Effect? {
        if count < 1 { return nil }
        if count >= 3 { return .splash }
        return mode == .fullScreen ? .splash : .pour
    }
}

enum DeliveryStatus: Equatable {
    case none, sending, sent, delivered

    /// For counted things like emojis.
    /// - Parameters:
    ///   - sent: emojis sent from this Mac (counted locally first).
    ///   - saved: the highest `sent` value the mailbox has accepted.
    ///   - partnerSeen: the partner's `seenEmojis`.
    static func counted(sent: Int, saved: Int, partnerSeen: Int) -> DeliveryStatus {
        if sent == 0 { return .none }
        if saved < sent { return .sending }
        return partnerSeen >= sent ? .delivered : .sent
    }

    /// For "latest only" things like the note and the photo.
    /// - Parameters:
    ///   - id: my latest one.
    ///   - savedId: the latest one the mailbox has accepted.
    ///   - partnerSeenId: the latest one my partner has shown.
    static func latest(id: UUID?, savedId: UUID?, partnerSeenId: UUID?) -> DeliveryStatus {
        guard let id else { return .none }
        if savedId != id { return .sending }
        return partnerSeenId == id ? .delivered : .sent
    }

    var label: String {
        switch self {
        case .none: ""
        case .sending: "Sending…"
        case .sent: "Sent ♡"
        case .delivered: "Delivered ♡"
        }
    }
}
