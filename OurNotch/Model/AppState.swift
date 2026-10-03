import AppKit
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
    /// The latest photo my partner sent me, shown on Home.
    private(set) var partnerPhoto: NSImage?
    /// The latest photo I sent, shown on the Photo tab.
    private(set) var myPhoto: NSImage?
    /// The last outbox the mailbox accepted. Differs from `myOutbox` while a save is pending or failed.
    private var savedOutbox: Outbox

    var myName: String { store.myName ?? "" }
    var partnerName: String { pairing.partnerName }
    var emojisReceived: Int { myOutbox.seenEmojis }

    var emojiStatus: DeliveryStatus {
        .counted(sent: myOutbox.emojisSent, saved: savedOutbox.emojisSent, partnerSeen: partnerOutbox.seenEmojis)
    }

    var photoStatus: DeliveryStatus {
        .latest(id: myOutbox.photo?.id, savedId: savedOutbox.photo?.id, partnerSeenId: partnerOutbox.seenPhotoId)
    }

    var messageStatus: DeliveryStatus {
        .latest(id: myOutbox.message?.id, savedId: savedOutbox.message?.id, partnerSeenId: partnerOutbox.seenMessageId)
    }

    /// Called when emojis arrive: how many are new, and the latest one (which decides how they appear).
    @ObservationIgnored var onEmojisArrived: ((Int, SentEmoji) -> Void)?

    @ObservationIgnored private let key: SymmetricKey
    @ObservationIgnored private let mailbox: Mailbox
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let photos: PhotoCache
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private let log = Logger(subsystem: "OurNotch", category: "sync")

    /// Returns nil until this identity has paired.
    init?(store: LocalStore, mailbox: Mailbox, photosRoot: URL = PhotoCache.defaultRoot) {
        guard let pairing = store.pairing,
              let key = try? Crypto.sharedKey(myPrivateKey: store.privateKey,
                                              partnerPublicKey: pairing.partnerKey,
                                              pairId: pairing.code) else { return nil }
        self.pairing = pairing
        self.key = key
        self.mailbox = mailbox
        self.store = store
        photos = PhotoCache(ownerId: pairing.myId, root: photosRoot)
        myPhoto = photos.load(.mine).flatMap(NSImage.init(data:))
        partnerPhoto = photos.load(.partner).flatMap(NSImage.init(data:))
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

    /// Counts the emoji locally right away; rapid taps are bundled into one save.
    func sendEmoji(_ char: String, mode: EmojiMode) {
        myOutbox.emojisSent += 1
        myOutbox.lastEmoji = SentEmoji(char: char, mode: mode)
        store.myOutbox = myOutbox
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: Config.emojiBundleDelay)
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

    /// Uploads the photo (encrypted) first, then points my outbox at it, so my partner never sees
    /// a photo id whose image isn't there yet. Returns false if the upload failed.
    func sendPhoto(_ jpeg: Data) async -> Bool {
        do {
            try await mailbox.savePhoto(Crypto.seal(jpeg, with: key), owner: pairing.myId)
            try photos.save(jpeg, .mine)
        } catch {
            log.error("Sending photo failed: \(error.localizedDescription)")
            return false
        }
        myPhoto = NSImage(data: jpeg)
        myOutbox.photo = SentPhoto(id: UUID(), sentAt: .now)
        store.myOutbox = myOutbox
        await save()
        return true
    }

    /// Sets (or clears, with nil) my mood and saves it right away.
    func setMood(_ emoji: String?) {
        myOutbox.mood = emoji
        store.myOutbox = myOutbox
        Task { await save() }
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
        let newEmojis = Arrival.newCount(partnerSent: partner.emojisSent, lastShown: myOutbox.seenEmojis)
        if newEmojis > 0, let emoji = partner.lastEmoji {
            log.notice("\(newEmojis) new emoji(s) from partner")
            myOutbox.seenEmojis = partner.emojisSent
            onEmojisArrived?(newEmojis, emoji)
            shownSomething = true
        }
        if let message = partner.message, message.id != myOutbox.seenMessageId {
            log.notice("New message from partner (\(message.mode.rawValue))")
            myOutbox.seenMessageId = message.id
            setBanner(message)
            shownSomething = true
        }
        if let photo = partner.photo, photo.id != myOutbox.seenPhotoId, await downloadPartnerPhoto() {
            myOutbox.seenPhotoId = photo.id
            shownSomething = true
        }
        guard shownSomething else { return }
        store.myOutbox = myOutbox
        await save() // tells the partner "delivered"
    }

    private func downloadPartnerPhoto() async -> Bool {
        do {
            guard let sealed = try await mailbox.fetchPhoto(owner: pairing.partnerId) else { return false }
            let jpeg = try Crypto.open(sealed, with: key)
            try photos.save(jpeg, .partner)
            partnerPhoto = NSImage(data: jpeg)
            log.notice("New photo from partner")
            return true
        } catch {
            log.error("Fetching partner photo failed: \(error.localizedDescription)")
            return false
        }
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

    /// Seconds since the start of the together-since day.
    static func seconds(since start: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        max(0, Int(now.timeIntervalSince(calendar.startOfDay(for: start))))
    }

    static func hours(since start: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        seconds(since: start, now: now, calendar: calendar) / 3600
    }

    /// Saturdays from the together-since day through today, counting both ends.
    static func weekends(since start: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        let days = days(since: start, now: now, calendar: calendar)
        let toFirstSaturday = (14 - calendar.component(.weekday, from: start)) % 7 // weekday: Sunday 1 … Saturday 7
        return days >= toFirstSaturday ? (days - toFirstSaturday) / 7 + 1 : 0
    }
}
