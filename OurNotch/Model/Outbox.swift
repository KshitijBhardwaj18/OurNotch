import Foundation

/// One partner's row in the shared mailbox. Only its owner writes it; the partner reads it.
struct Outbox: Codable, Equatable {
    /// Set by the inviter only; the joiner reads it from here.
    var togetherSince: Date?
    /// Running total of hearts this partner has sent. Never goes down.
    var heartsSent = 0
    /// The partner's `heartsSent` value this Mac has already shown. Tells the sender "delivered".
    var seenHearts = 0
    /// The latest message sent. Only the last one is kept; there's no history.
    var message: Message?
    /// The partner's message this Mac has already shown.
    var seenMessageId: UUID?
}

struct Message: Codable, Equatable {
    let id: UUID
    let text: String
    let mode: BannerMode
    let sentAt: Date
}

/// How the message scrolls on the partner's notch. The sender chooses.
enum BannerMode: String, Codable {
    /// Scrolls 3 times, then disappears.
    case three
    /// Keeps scrolling until the partner opens the notch.
    case untilOpened

    var label: String {
        switch self {
        case .three: "scroll 3×"
        case .untilOpened: "until opened"
        }
    }

    var toggled: BannerMode { self == .three ? .untilOpened : .three }
}

/// Missed-hearts math (`spec.md > Decisions and Open Issues`), kept pure for tests.
enum Hearts {
    enum Effect: Equatable { case pour, splash }

    /// Hearts the partner sent that this Mac hasn't shown yet.
    static func newCount(partnerSent: Int, lastShown: Int) -> Int {
        max(0, partnerSent - lastShown)
    }

    /// Fewer than 3 new hearts pour from the notch; 3 or more fill the screen.
    static func effect(forNew count: Int) -> Effect? {
        switch count {
        case ..<1: nil
        case 1..<3: .pour
        default: .splash
        }
    }
}

enum DeliveryStatus: Equatable {
    case none, sending, sent, delivered

    /// - Parameters:
    ///   - sent: hearts sent from this Mac (counted locally first).
    ///   - saved: the highest `sent` value the mailbox has accepted.
    ///   - partnerSeen: the partner's `seenHearts`.
    static func hearts(sent: Int, saved: Int, partnerSeen: Int) -> DeliveryStatus {
        if sent == 0 { return .none }
        if saved < sent { return .sending }
        return partnerSeen >= sent ? .delivered : .sent
    }

    /// - Parameters:
    ///   - id: my latest message.
    ///   - savedId: the latest message the mailbox has accepted.
    ///   - partnerSeenId: the partner's `seenMessageId`.
    static func message(id: UUID?, savedId: UUID?, partnerSeenId: UUID?) -> DeliveryStatus {
        guard let id else { return .none }
        if savedId != id { return .sending }
        return partnerSeenId == id ? .delivered : .sent
    }

    var label: String {
        switch self {
        case .none: ""
        case .sending: "sending…"
        case .sent: "sent ♡"
        case .delivered: "delivered ♡"
        }
    }
}
