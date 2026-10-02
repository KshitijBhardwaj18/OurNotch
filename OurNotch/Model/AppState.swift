import CryptoKit
import Foundation
import Observation
import os

/// The single source of truth for one partner: my outbox, what my partner sent, and what I've shown.
/// The notch and the Partner Simulator each own one.
@MainActor
@Observable
final class AppState {
    let pairing: Pairing
    /// The inviter's answer to "How long have you been together?". The joiner receives it from the inviter's outbox.
    private(set) var togetherSince: Date?
    private(set) var myOutbox: Outbox
    private(set) var partnerOutbox = Outbox()
    /// The message currently scrolling under the notch, if any. Saved so `untilOpened` survives a restart.
    private(set) var banner: Message?
    /// The last outbox the mailbox accepted. Differs from `myOutbox` while a save is pending or failed.
    private var savedOutbox: Outbox

    var heartsReceived: Int { myOutbox.seenHearts }

    var heartStatus: DeliveryStatus {
        .hearts(sent: myOutbox.heartsSent, saved: savedOutbox.heartsSent, partnerSeen: partnerOutbox.seenHearts)
    }

    var messageStatus: DeliveryStatus {
        .message(id: myOutbox.message?.id, savedId: savedOutbox.message?.id, partnerSeenId: partnerOutbox.seenMessageId)
    }

    /// Called with the number of new hearts each time some arrive.
    @ObservationIgnored var onHeartsArrived: ((Int) -> Void)?

    @ObservationIgnored private let key: SymmetricKey
    @ObservationIgnored private let mailbox: Mailbox
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private let log = Logger(subsystem: "OurNotch", category: "sync")

    /// Returns nil until this identity has paired.
    init?(store: LocalStore, mailbox: Mailbox) {
        guard let pairing = store.pairing,
              let key = try? Crypto.sharedKey(myPrivateKey: store.privateKey,
                                              partnerPublicKey: pairing.partnerKey,
                                              pairId: pairing.code) else { return nil }
        self.pairing = pairing
        self.key = key
        self.mailbox = mailbox
        self.store = store
        myOutbox = store.myOutbox ?? Outbox()
        savedOutbox = store.savedOutbox ?? Outbox()
        banner = store.banner
        togetherSince = store.togetherSince
        if pairing.role == .inviter {
            myOutbox.togetherSince = togetherSince // shared on the next save
        }
    }

    /// Starts checking the partner's row. Anything missed while the app was closed shows on the first check.
    func start() {
        guard syncTask == nil else { return }
        syncTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.sync()
                try? await Task.sleep(for: self.mailbox.pollInterval)
            }
        }
    }

    // MARK: Sending

    /// Counts the heart locally right away; rapid taps are bundled into one save.
    func sendHeart() {
        myOutbox.heartsSent += 1
        store.myOutbox = myOutbox
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: Config.heartBundleDelay)
            guard !Task.isCancelled, let self else { return }
            await self.save()
            self.saveTask = nil
        }
    }

    /// Replaces my latest message and saves it right away. Returns false if the text breaks the message rules.
    @discardableResult
    func sendMessage(_ text: String, mode: BannerMode) -> Bool {
        guard case .valid(let clean) = MessageRules.check(text) else { return false }
        myOutbox.message = Message(id: UUID(), text: clean, mode: mode, sentAt: .now)
        store.myOutbox = myOutbox
        Task { await save() }
        return true
    }

    // MARK: Banner

    /// The banner finished its 3 passes.
    func bannerFinished() {
        setBanner(nil)
    }

    /// Opening the notch dismisses an `untilOpened` banner; the message stays readable inside.
    func notchOpened() {
        if banner?.mode == .untilOpened { setBanner(nil) }
    }

    private func setBanner(_ message: Message?) {
        banner = message
        store.banner = message
    }

    // MARK: Syncing

    /// Reads the partner's row, shows anything new, and retries an outbox that didn't save.
    func sync() async {
        if saveTask == nil, myOutbox != savedOutbox { await save() }

        let partner: Outbox
        do {
            guard let sealed = try await mailbox.fetchOutbox(owner: pairing.partnerId) else { return }
            partner = try JSONDecoder().decode(Outbox.self, from: Crypto.open(sealed, with: key))
        } catch {
            log.error("Fetching partner outbox failed: \(error.localizedDescription)")
            return
        }
        partnerOutbox = partner
        if pairing.role == .joiner, let date = partner.togetherSince, date != togetherSince {
            togetherSince = date
            store.togetherSince = date
        }

        var shownSomething = false
        let newHearts = Hearts.newCount(partnerSent: partner.heartsSent, lastShown: myOutbox.seenHearts)
        if newHearts > 0 {
            log.notice("\(newHearts) new heart(s) from partner")
            myOutbox.seenHearts = partner.heartsSent
            onHeartsArrived?(newHearts)
            shownSomething = true
        }
        if let message = partner.message, message.id != myOutbox.seenMessageId {
            log.notice("New message from partner (\(message.mode.rawValue))")
            myOutbox.seenMessageId = message.id
            setBanner(message)
            shownSomething = true
        }
        guard shownSomething else { return }
        store.myOutbox = myOutbox
        await save() // tells the partner "delivered"
    }

    private func save() async {
        let snapshot = myOutbox
        do {
            let sealed = try Crypto.seal(JSONEncoder().encode(snapshot), with: key)
            try await mailbox.saveOutbox(sealed, owner: pairing.myId)
            savedOutbox = snapshot
            store.savedOutbox = snapshot
        } catch {
            log.error("Saving outbox failed, will retry: \(error.localizedDescription)")
        }
    }
}

/// Time-together math, kept pure so it can be tested.
enum Together {
    /// Whole calendar days since the together-since date (day one counts as 0).
    static func days(since start: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        let from = calendar.startOfDay(for: start)
        let to = calendar.startOfDay(for: now)
        return max(0, calendar.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    /// Days, hours, minutes and seconds since the start of the together-since day.
    static func elapsed(since start: Date, now: Date = .now, calendar: Calendar = .current) -> DateComponents {
        calendar.dateComponents([.day, .hour, .minute, .second], from: calendar.startOfDay(for: start), to: now)
    }
}
