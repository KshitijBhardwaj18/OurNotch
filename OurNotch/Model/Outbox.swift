import Foundation

/// One partner's row in the shared mailbox. Only its owner writes it; the partner reads it.
struct Outbox: Codable, Equatable {
    /// Our anniversary: set by the inviter in onboarding, changeable by either of us in Settings.
    var togetherSince: Date?
    /// When `togetherSince` was last changed in Settings, so the newer change wins on both Macs.
    /// Nil for the onboarding answer (and outboxes from older builds).
    var togetherSinceSetAt: Date?
    /// Running total of emojis this partner has sent. Never goes down.
    var emojisSent = 0
    /// The most recent emoji and how it should appear. Earlier ones aren't kept.
    var lastEmoji: SentEmoji?
    /// The last `Config.recentEmojis` sent, oldest first, so a burst plays in full. Builds before 1.0.22 send only `lastEmoji`.
    var recentEmojis: [SentEmoji]?
    /// The partner's `emojisSent` value this Mac has already shown. Tells the sender "delivered".
    var seenEmojis = 0
    /// The latest note sent. This is the one that scrolls across the partner's notch.
    var message: Message?
    /// The notes sent before `message`, oldest first, so together they make the last
    /// `Config.Message.historyCount`. Optional, so outboxes from older builds still decode.
    var earlierMessages: [Message]?
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
    /// While I've hidden OurNotch: my partner's notch shows "away" until then, or until I'm back.
    var awayUntil: Date?
    /// Our pet (`Pet`): set by whoever adopted it, its look as I last chose it, and my latest care.
    var petAdoption: PetAdoption?
    var petLook: PetLook?
    var petCare: [PetAction]?
    /// When this Mac last started OurNotch. Part of the outbox (so it pings): both Macs then check every 2 s
    /// for a while (`Config.Cloud.launchBoostWindow`).
    var launchedAt: Date?
    /// When this Mac last said "I'm here" (every few minutes while OurNotch runs), so my partner can tell
    /// when it's asleep or off.
    var lastSeen: Date?
}

/// What doesn't need a ping, saved apart from my outbox (see `Mailbox.saveReceipts`): what I've seen of my
/// partner's things, and our pet, which they see on their next check (every 3 s while their notch is open).
/// Apple allows only a few silent pings an hour; Beta 1.0.10's pet play spent them all.
struct Receipts: Codable, Equatable {
    var seenEmojis = 0
    var seenMessageId: UUID?
    var seenPhotoId: UUID?
    var petAdoption: PetAdoption?
    var petLook: PetLook?
    var petCare: [PetAction]?
    var lastSeen: Date?
}

extension Outbox {
    var receipts: Receipts {
        Receipts(seenEmojis: seenEmojis, seenMessageId: seenMessageId, seenPhotoId: seenPhotoId,
                 petAdoption: petAdoption, petLook: petLook, petCare: petCare, lastSeen: lastSeen)
    }

    /// Everything but the receipts: what's worth saving (and pinging the partner for).
    var content: Outbox {
        var content = self
        content.seenEmojis = 0
        content.seenMessageId = nil
        content.seenPhotoId = nil
        content.petAdoption = nil
        content.petLook = nil
        content.petCare = nil
        content.lastSeen = nil
        return content
    }

    /// The partner's outbox with their newest receipts. Builds before 1.0.7 keep receipts in the outbox only,
    /// and before 1.0.11 the pet too.
    func with(_ receipts: Receipts?) -> Outbox {
        guard let receipts else { return self }
        var merged = self
        merged.seenEmojis = max(seenEmojis, receipts.seenEmojis)
        merged.seenMessageId = receipts.seenMessageId ?? seenMessageId
        merged.seenPhotoId = receipts.seenPhotoId ?? seenPhotoId
        merged.petAdoption = receipts.petAdoption ?? petAdoption
        merged.petLook = receipts.petLook ?? petLook
        merged.petCare = receipts.petCare ?? petCare
        merged.lastSeen = [lastSeen, receipts.lastSeen].compactMap { $0 }.max()
        return merged
    }

    /// My last notes, oldest first.
    var notes: [Message] { (earlierMessages ?? []) + (message.map { [$0] } ?? []) }

    /// Makes `new` the latest note and keeps the previous ones, up to the history limit.
    mutating func send(_ new: Message) {
        earlierMessages = message.map { Array(((earlierMessages ?? []) + [$0]).suffix(Config.Message.historyCount - 1)) } ?? earlierMessages
        message = new
    }
}

/// Both partners' last notes as one conversation, oldest first.
enum Conversation {
    struct Line: Identifiable, Equatable {
        let message: Message
        let isMine: Bool
        var id: UUID { message.id }
    }

    static func lines(mine: Outbox, theirs: Outbox) -> [Line] {
        (mine.notes.map { Line(message: $0, isMine: true) } + theirs.notes.map { Line(message: $0, isMine: false) })
            .sorted { $0.message.sentAt < $1.message.sentAt }
    }
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
        case .notch: String(localized: "Out of the notch")
        case .fullScreen: String(localized: "Full screen")
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

    /// The text as shown: hearts typed as ♡ (even in notes from older builds) show as a red ❤️.
    var shown: String { MessageRules.redHearts(text) }
}

/// How the note scrolls on the partner's notch. The sender chooses.
enum BannerMode: String, Codable, CaseIterable {
    /// Scrolls 3 times, then disappears (sooner if the partner opens the notch).
    case three
    /// Keeps scrolling until the partner opens the notch.
    case untilOpened

    var label: String {
        switch self {
        case .three: String(localized: "3 times")
        case .untilOpened: String(localized: "Until opened")
        }
    }

    var symbol: String {
        switch self {
        case .three: "repeat"
        case .untilOpened: "envelope.open"
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

    /// The emojis to play for `count` new ones: the newest of the partner's recent list, oldest first.
    /// An older build sends only its last emoji, which then stands for the lot.
    static func emojis(forNew count: Int, recent: [SentEmoji]?, last: SentEmoji?) -> [SentEmoji] {
        guard count > 0 else { return [] }
        if let recent, !recent.isEmpty { return Array(recent.suffix(count)) }
        return last.map { [$0] } ?? []
    }

    /// The sender's choice decides, except that 3 or more arriving at once (a burst, or missed while away) always splash.
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
        case .sending: String(localized: "Sending…")
        case .sent: String(localized: "Sent ♡")
        case .delivered: String(localized: "Delivered ♡")
        }
    }
}
