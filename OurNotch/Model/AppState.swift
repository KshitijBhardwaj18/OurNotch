import AppKit
import CryptoKit
import Foundation
import Observation

/// Why a check of the partner's row ran. Logged with each check, so pings can be told apart from the timer.
enum SyncSource: String {
    case launch, poll, ping, wake
}

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
    /// Labels this identity's lines in the diagnostics log ("me", or "sim" for the Partner Simulator).
    @ObservationIgnored private let who: String
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var isSyncing = false
    /// A ping or wake that arrived mid-check; it runs right after, so a fresh change isn't missed.
    @ObservationIgnored private var queuedSync: SyncSource?
    @ObservationIgnored private var hasFetchedPartner = false

    /// Returns nil until this identity has paired.
    init?(store: LocalStore, mailbox: Mailbox, photosRoot: URL = PhotoCache.defaultRoot, who: String = "me") {
        guard let pairing = store.pairing,
              let key = try? Crypto.sharedKey(myPrivateKey: store.privateKey,
                                              partnerPublicKey: pairing.partnerKey,
                                              pairId: pairing.code) else { return nil }
        self.pairing = pairing
        self.key = key
        self.mailbox = mailbox
        self.store = store
        self.who = who
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

    private func note(_ message: String) {
        Diagnostics.shared.record(message, who: who)
    }

    /// Starts checking the partner's row: right away (anything missed while the app was closed shows then),
    /// whenever a ping or wake-up calls `syncNow`, and every `pollInterval` as a safety net.
    func start() {
        guard syncTask == nil else { return }
        note("started: paired with \(pairing.partnerName) as \(pairing.role.rawValue); checks every \(mailbox.pollInterval)")
        syncTask = Task { [weak self] in
            guard let self else { return }
            await self.mailbox.watchPartner(self.pairing.partnerId)
            var source = SyncSource.launch
            while !Task.isCancelled {
                await self.sync(source)
                source = .poll
                try? await Task.sleep(for: self.mailbox.pollInterval)
            }
        }
    }

    /// Checks now, e.g. after a ping or when the Mac wakes. If a check is already running,
    /// this one runs right after it instead of being dropped.
    func syncNow(_ source: SyncSource) {
        if isSyncing {
            queuedSync = source
        } else {
            Task { await sync(source) }
        }
    }

    // MARK: Sending

    /// Counts the emoji locally right away; rapid taps are bundled into one save.
    func sendEmoji(_ char: String, mode: EmojiMode) {
        myOutbox.emojisSent += 1
        myOutbox.lastEmoji = SentEmoji(char: char, mode: mode)
        store.myOutbox = myOutbox
        note("tap: emoji #\(myOutbox.emojisSent) \(char) (\(mode.rawValue))")
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
        note("tap: note (\(MessageRules.wordCount(clean)) words, \(mode.rawValue))")
        Task { await save() }
        return true
    }

    /// Uploads the photo (encrypted) first, then points my outbox at it, so my partner never sees
    /// a photo id whose image isn't there yet. Returns false if the upload failed.
    func sendPhoto(_ jpeg: Data) async -> Bool {
        note("tap: photo (\(jpeg.count / 1024) KB)")
        let started = Date.now
        do {
            try await mailbox.savePhoto(Crypto.seal(jpeg, with: key), owner: pairing.myId)
            try photos.save(jpeg, .mine)
        } catch {
            note("photo upload FAILED: \(error.diagnosticDescription)")
            return false
        }
        note("photo uploaded in \(Self.ms(since: started))")
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
        note("tap: mood \(emoji ?? "cleared")")
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
    func sync(_ source: SyncSource = .poll) async {
        isSyncing = true
        defer {
            isSyncing = false
            if let next = queuedSync {
                queuedSync = nil
                Task { await sync(next) }
            }
        }
        if saveTask == nil, myOutbox != savedOutbox { await save() }

        let started = Date.now
        let partner: Outbox
        do {
            guard let sealed = try await mailbox.fetchOutbox(owner: pairing.partnerId) else {
                if source != .poll { note("[\(source.rawValue)] partner has no outbox yet") }
                return
            }
            partner = try JSONDecoder().decode(Outbox.self, from: Crypto.open(sealed, with: key))
        } catch {
            note("[\(source.rawValue)] fetch FAILED: \(error.diagnosticDescription)")
            return
        }
        let fetchTime = Self.ms(since: started)
        let previous = partnerOutbox
        partnerOutbox = partner
        if hasFetchedPartner { logReceipts(old: previous, new: partner) }
        hasFetchedPartner = true
        if pairing.role == .joiner, let date = partner.togetherSince, date != togetherSince {
            togetherSince = date
            store.togetherSince = date
            note("[\(source.rawValue)] got together-since date")
        }

        var found: [String] = []
        if partner.mood != previous.mood, hasFetchedPartner { found.append("mood \(partner.mood ?? "cleared")") }
        let newEmojis = Arrival.newCount(partnerSent: partner.emojisSent, lastShown: myOutbox.seenEmojis)
        if newEmojis > 0, let emoji = partner.lastEmoji {
            myOutbox.seenEmojis = partner.emojisSent
            onEmojisArrived?(newEmojis, emoji)
            found.append("\(newEmojis) emoji \(emoji.char) (\(emoji.mode.rawValue))")
        }
        if let message = partner.message, message.id != myOutbox.seenMessageId {
            myOutbox.seenMessageId = message.id
            setBanner(message)
            found.append("note (\(message.mode.rawValue), sent \(Self.ms(since: message.sentAt)) ago)")
        }
        if let photo = partner.photo, photo.id != myOutbox.seenPhotoId, await downloadPartnerPhoto() {
            myOutbox.seenPhotoId = photo.id
            found.append("photo (sent \(Self.ms(since: photo.sentAt)) ago)")
        }

        if !found.isEmpty {
            note("[\(source.rawValue)] found \(found.joined(separator: ", ")); fetch \(fetchTime)")
        } else if source != .poll {
            note("[\(source.rawValue)] no change found; fetch \(fetchTime)")
        }
        let seenSomethingNew = myOutbox.seenEmojis != savedOutbox.seenEmojis
            || myOutbox.seenMessageId != savedOutbox.seenMessageId
            || myOutbox.seenPhotoId != savedOutbox.seenPhotoId
        guard seenSomethingNew else { return }
        store.myOutbox = myOutbox
        await save() // tells the partner "delivered"
    }

    /// Logs when my partner's Mac has shown what I sent: the "Delivered" moments.
    private func logReceipts(old: Outbox, new: Outbox) {
        if new.seenEmojis > old.seenEmojis { note("delivered: partner showed emojis up to #\(new.seenEmojis)") }
        if new.seenMessageId != old.seenMessageId, new.seenMessageId == myOutbox.message?.id {
            note("delivered: partner showed my note (sent \(Self.ms(since: myOutbox.message?.sentAt ?? .now)) ago)")
        }
        if new.seenPhotoId != old.seenPhotoId, new.seenPhotoId == myOutbox.photo?.id {
            note("delivered: partner downloaded my photo (sent \(Self.ms(since: myOutbox.photo?.sentAt ?? .now)) ago)")
        }
    }

    private func downloadPartnerPhoto() async -> Bool {
        let started = Date.now
        do {
            guard let sealed = try await mailbox.fetchPhoto(owner: pairing.partnerId) else { return false }
            let jpeg = try Crypto.open(sealed, with: key)
            try photos.save(jpeg, .partner)
            partnerPhoto = NSImage(data: jpeg)
            note("photo downloaded (\(jpeg.count / 1024) KB) in \(Self.ms(since: started))")
            return true
        } catch {
            note("photo download FAILED: \(error.diagnosticDescription)")
            return false
        }
    }

    private func save() async {
        let snapshot = myOutbox
        let changes = Self.changes(from: savedOutbox, to: snapshot)
        let started = Date.now
        do {
            let sealed = try Crypto.seal(JSONEncoder().encode(snapshot), with: key)
            try await mailbox.saveOutbox(sealed, owner: pairing.myId)
            savedOutbox = snapshot
            store.savedOutbox = snapshot
            note("saved outbox (\(changes)) in \(Self.ms(since: started))")
        } catch {
            note("save FAILED (\(changes)), will retry: \(error.diagnosticDescription)")
        }
    }

    /// What differs between two outboxes, for the log — never the note's text.
    private static func changes(from old: Outbox, to new: Outbox) -> String {
        var parts: [String] = []
        if new.emojisSent != old.emojisSent { parts.append("emojis \(old.emojisSent)→\(new.emojisSent)") }
        if new.message != old.message { parts.append("note") }
        if new.photo != old.photo { parts.append("photo") }
        if new.mood != old.mood { parts.append("mood \(new.mood ?? "cleared")") }
        if new.togetherSince != old.togetherSince { parts.append("date") }
        if new.seenEmojis != old.seenEmojis { parts.append("seen emojis \(new.seenEmojis)") }
        if new.seenMessageId != old.seenMessageId { parts.append("seen note") }
        if new.seenPhotoId != old.seenPhotoId { parts.append("seen photo") }
        return parts.isEmpty ? "no changes" : parts.joined(separator: ", ")
    }

    private static func ms(since date: Date) -> String {
        let seconds = Date.now.timeIntervalSince(date)
        return seconds < 10 ? "\(Int(seconds * 1000)) ms" : "\(Int(seconds)) s"
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
