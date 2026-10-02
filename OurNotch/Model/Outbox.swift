import Foundation

/// One partner's row in the shared mailbox. Only its owner writes it; the partner reads it.
struct Outbox: Codable, Equatable {
    /// Running total of hearts this partner has sent. Never goes down.
    var heartsSent = 0
    /// The partner's `heartsSent` value this Mac has already shown. Tells the sender "delivered".
    var seenHearts = 0
}

/// Missed-hearts and delivery math (`spec.md > Decisions and Open Issues`), kept pure for tests.
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
    ///   - sent: hearts sent from this Mac (saved locally first).
    ///   - saved: the highest `sent` value the mailbox has accepted.
    ///   - partnerSeen: the partner's `seenHearts`.
    static func of(sent: Int, saved: Int, partnerSeen: Int) -> DeliveryStatus {
        if sent == 0 { return .none }
        if saved < sent { return .sending }
        return partnerSeen >= sent ? .delivered : .sent
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
