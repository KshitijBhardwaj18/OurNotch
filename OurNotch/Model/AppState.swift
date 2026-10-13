import AppKit
import CryptoKit
import Foundation
import Observation

/// Why a check of the partner's row ran. Logged with each check, so pings can be told apart from the timer.
enum SyncSource: String {
    case launch, poll, ping, wake, live
}

/// The single source of truth for one partner: my outbox, what my partner sent, and what I've shown.
/// The notch and the Partner Simulator each own one.
@MainActor
@Observable
final class AppState {
    let pairing: Pairing
    /// Our anniversary: the inviter's onboarding answer, then whoever changed it last in Settings.
    private(set) var togetherSince: Date?
    /// Settings → Mood words: the word beside my love's mood emoji in the closed notch.
    var showsMoodWord = true { didSet { store.showsMoodWord = showsMoodWord } }
    private(set) var myOutbox: Outbox
    private(set) var partnerOutbox = Outbox()

    /// Width of each slot beside the camera in the closed notch: wider while my love's mood has a word to show.
    var closedSideWidth: CGFloat {
        partnerOutbox.mood == nil || !showsMoodWord ? Config.Notch.closedSideWidth : Config.Notch.closedSideWidthWithMood
    }
    /// The message currently scrolling under the notch, if any. Saved so `untilOpened` survives a restart.
    private(set) var banner: Message?
    /// When `banner` first scrolled on screen; nil until it does.
    private(set) var bannerStartedAt: Date?
    /// Tabs with something new that arrived out of sight (a pink dot in the tab bar), cleared when shown.
    private(set) var unseen: Set<NotchTab> = []
    /// The tab on screen while the notch is open; nil while closed or in Settings.
    @ObservationIgnored private var visibleTab: NotchTab?
    /// While set and in the future, OurNotch is hidden: no notch, and arrivals wait.
    private(set) var hiddenUntil: Date?
    var isHidden: Bool { Hide.isHidden(until: hiddenUntil) }
    /// The banner, held back while hidden so it scrolls when OurNotch comes back.
    var visibleBanner: Message? { isHidden ? nil : banner }
    /// How my love is, for the line beside the gear: hidden, their Mac asleep or off, or around (nil).
    enum PartnerStatus: Equatable {
        case hidden(until: Date?)
        case asleep(since: Date)

        static func of(_ outbox: Outbox, now: Date = .now) -> PartnerStatus? {
            if Hide.isHidden(until: outbox.awayUntil, now: now) {
                return .hidden(until: outbox.awayUntil == .distantFuture ? nil : outbox.awayUntil)
            }
            // Builds before 1.0.13 never say "I'm here": no status rather than a wrong one.
            if let seen = outbox.lastSeen, now.timeIntervalSince(seen) > Config.Presence.asleepAfter { return .asleep(since: seen) }
            return nil
        }
    }

    func partnerStatus(now: Date = .now) -> PartnerStatus? { PartnerStatus.of(partnerOutbox, now: now) }

    /// Whether my love has hidden their OurNotch ("away" in my closed notch).
    func partnerIsAway(now: Date = .now) -> Bool { Hide.isHidden(until: partnerOutbox.awayUntil, now: now) }
    /// The latest photo my partner sent me, shown on Home.
    private(set) var partnerPhoto: NSImage?
    #if DEBUG
    /// Stage mode opens the notch on a tab, or closes it (nil), for filming (`PartnerSimulator.startStage`).
    var stageTab: NotchTab?
    #endif
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
    @ObservationIgnored var onEmojisArrived: ((Int, [SentEmoji]) -> Void)?
    /// Called when this Mac's licence changed here (received from the partner, or removed), so it gets checked.
    @ObservationIgnored var onLicenceChanged: (() -> Void)?
    /// Called when the notch opens, so the licence gets re-checked if it's been a while.
    @ObservationIgnored var onOpened: (() -> Void)?
    /// Called when OurNotch is hidden or shown, so the notch window follows.
    @ObservationIgnored var onHiddenChanged: (() -> Void)?
    /// Emojis that arrived while hidden: they play once, together, when OurNotch comes back.
    @ObservationIgnored private var heldEmojis: (count: Int, emojis: [SentEmoji])?
    @ObservationIgnored private var returnTask: Task<Void, Never>?

    var licence: Licence? { store.licence }

    @ObservationIgnored private let key: SymmetricKey
    @ObservationIgnored private let mailbox: Mailbox
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let photos: PhotoCache
    /// Labels this identity's lines in the diagnostics log ("me", or "sim" for the Partner Simulator).
    @ObservationIgnored private let who: String
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var quietTask: Task<Void, Never>?
    /// When the last emoji save started, so a burst of taps goes out as one save every few seconds.
    @ObservationIgnored private var lastEmojiSave = Date.distantPast
    /// The receipts the mailbox has; starts as the outbox's (builds before 1.0.7 kept them there).
    @ObservationIgnored private var savedReceipts = Receipts()
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var isSyncing = false
    /// A ping or wake that arrived mid-check; it runs right after, so a fresh change isn't missed.
    @ObservationIgnored private var queuedSync: SyncSource?
    @ObservationIgnored private var hasFetchedPartner = false
    /// Checks every 2 s until then: 10 minutes from either Mac starting OurNotch.
    @ObservationIgnored private var boostUntil: Date?
    /// Checks speed up while the notch is open and for a few minutes after sending or receiving.
    @ObservationIgnored private var isNotchOpen = false
    @ObservationIgnored private var lastActivity: Date?
    @ObservationIgnored private var lastCheck = Date.distantPast
    @ObservationIgnored private var isSaving = false
    @ObservationIgnored private var saveAgain = false
    @ObservationIgnored private let live: LiveBell?

    private var checkInterval: Duration {
        CheckPace.interval(notchOpen: isNotchOpen, lastActivity: lastActivity, boostUntil: boostUntil,
                           partnerLive: live?.partnerHere == true, idle: mailbox.pollInterval)
    }

    /// Returns nil until this identity has paired.
    init?(store: LocalStore, mailbox: Mailbox, photosRoot: URL = PhotoCache.defaultRoot, who: String = "me",
          live: Bool = false) {
        guard let pairing = store.pairing,
              let key = try? Crypto.sharedKey(myPrivateKey: store.privateKey,
                                              partnerPublicKey: pairing.partnerKey,
                                              pairId: pairing.code) else { return nil }
        self.pairing = pairing
        self.key = key
        self.mailbox = mailbox
        self.store = store
        self.who = who
        self.live = live ? LiveBell(key: key, role: pairing.role) : nil
        photos = PhotoCache(ownerId: pairing.myId, root: photosRoot)
        myPhoto = photos.load(.mine).flatMap(NSImage.init(data:))
        partnerPhoto = photos.load(.partner).flatMap(NSImage.init(data:))
        myOutbox = store.myOutbox ?? Outbox()
        savedOutbox = store.savedOutbox ?? Outbox()
        savedReceipts = savedOutbox.receipts
        banner = store.banner
        bannerStartedAt = store.bannerStartedAt
        // Quit mid-scroll and reopened after its passes would have ended: it's done, don't flash it.
        if banner?.mode == .three, let started = bannerStartedAt,
           Date.now.timeIntervalSince(started) > Config.Message.bannerThreePassesAtMost {
            setBanner(nil)
        }
        hiddenUntil = Hide.isHidden(until: store.hiddenUntil) ? store.hiddenUntil : nil
        if hiddenUntil == nil { myOutbox.awayUntil = nil } // came back while the app was closed
        togetherSince = store.togetherSince
        if togetherSince != nil { myOutbox.togetherSince = togetherSince } // shared on the next save
        showsMoodWord = store.showsMoodWord
        myOutbox.licenceKey = Self.sharedKey(store.licence) ?? myOutbox.licenceKey
    }

    /// The buyer shares their key with the partner; a partner shares nothing.
    private static func sharedKey(_ licence: Licence?) -> String? {
        guard let licence, licence.isBuyer, licence.status == .active else { return nil }
        return licence.key
    }

    /// After the buyer activates a (new) key on this Mac: hand it to the partner on the next save.
    func shareLicence() {
        guard let key = Self.sharedKey(store.licence), key != myOutbox.licenceKey else { return }
        myOutbox.licenceKey = key
        store.myOutbox = myOutbox
        Task { await save() }
    }

    /// Settings → Remove from This Mac (buyer only).
    func removeLicence() async throws {
        try await LicenceService(store: store).removeFromThisMac()
        note("licence removed from this Mac")
        onLicenceChanged?()
    }

    private func note(_ message: String, metric: Metric? = nil) {
        var metric = metric
        metric?.owner = pairing.myId
        Diagnostics.shared.record(message, who: who, metric: metric)
    }

    /// Starts checking the partner's row: right away (anything missed while the app was closed shows then),
    /// whenever a ping or wake-up calls `syncNow`, and as a safety net every `checkInterval` since the last check.
    /// Ticking each second (no network) means opening the notch or sending speeds up the very next check.
    func start() {
        guard syncTask == nil else { return }
        scheduleReturn()
        // Started: check fast for a while, and tell my love's Mac to do the same (saved with the first check).
        boostUntil = Date.now.addingTimeInterval(Config.Cloud.launchBoostWindow)
        myOutbox.launchedAt = .now
        store.myOutbox = myOutbox
        note("started: paired with \(pairing.partnerName) as \(pairing.role.rawValue); checks every \(checkInterval) for a while, then every \(mailbox.pollInterval) when idle")
        live?.onCheck = { [weak self] in self?.syncNow(.live) }
        live?.onNote = { [weak self] in self?.note("live: \($0)") }
        live?.start()
        syncTask = Task { [weak self] in
            guard let self else { return }
            await self.mailbox.watchPartner(self.pairing.partnerId)
            await self.sync(.launch)
            var interval = self.checkInterval
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Date.now.timeIntervalSince(self.myOutbox.lastSeen ?? .distantPast) >= Config.Presence.heartbeat {
                    self.myOutbox.lastSeen = .now // saved quietly with the receipts below
                    self.store.myOutbox = self.myOutbox
                    self.syncNow(.poll)
                }
                if self.checkInterval != interval {
                    interval = self.checkInterval
                    self.note("checks now every \(interval)\(interval == self.mailbox.pollInterval ? " (idle)" : " (active)")")
                }
                if Date.now.timeIntervalSince(self.lastCheck) >= Double(interval.components.seconds) {
                    await self.sync(.poll)
                }
            }
        }
    }

    /// Checks now, e.g. after a ping or when the Mac wakes. If a check is already running,
    /// this one runs right after it instead of being dropped.
    func syncNow(_ source: SyncSource) {
        if source == .wake { live?.reconnect() } // the socket rarely survives sleep
        if isSyncing {
            queuedSync = source
        } else {
            Task { await sync(source) }
        }
    }

    // MARK: Sending

    /// Counts the emoji locally right away, then `saveSoon`.
    func sendEmoji(_ char: String, mode: EmojiMode) {
        lastActivity = .now
        myOutbox.emojisSent += 1
        let sent = SentEmoji(char: char, mode: mode, sentAt: .now)
        myOutbox.lastEmoji = sent
        myOutbox.recentEmojis = Array(((myOutbox.recentEmojis ?? []) + [sent]).suffix(Config.recentEmojis))
        store.myOutbox = myOutbox
        note("tap: emoji #\(myOutbox.emojisSent) \(char) (\(mode.rawValue))")
        saveSoon()
    }

    /// The pet goes in the receipts record, which doesn't ping the partner; taps within a second save once.
    private func saveQuietSoon() {
        guard quietTask == nil else { return }
        quietTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard let self else { return }
            self.quietTask = nil
            await self.saveReceipts()
        }
    }

    /// For taps that come in bursts (emojis): the first saves at once; taps within
    /// `Config.emojiSaveGap` of that save go out together in the next one. Every save pings the partner, and
    /// Apple holds silent pings back when an app sends too many (Beta 1.0.6: none delivered for 30 min).
    private func saveSoon() {
        guard saveTask == nil else { return } // the save already waiting carries this tap too
        let gap = live?.partnerHere == true ? Config.liveEmojiSaveGap : Config.emojiSaveGap
        let wait = gap - Date.now.timeIntervalSince(lastEmojiSave)
        saveTask = Task { [weak self] in
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            guard let self else { return }
            self.lastEmojiSave = .now
            self.saveTask = nil // taps from here on wait for the next save
            await self.save()
        }
    }

    /// Makes this my latest message (earlier ones stay as history) and saves it right away. Returns false if the text breaks the message rules.
    @discardableResult
    func sendMessage(_ text: String, mode: BannerMode) -> Bool {
        guard case .valid(let clean) = MessageRules.check(text) else { return false }
        lastActivity = .now
        myOutbox.send(Message(id: UUID(), text: clean, mode: mode, sentAt: .now))
        store.myOutbox = myOutbox
        note("tap: note (\(MessageRules.wordCount(clean)) words, \(mode.rawValue))")
        Task { await save() }
        return true
    }

    /// Uploads the photo (encrypted) first, then points my outbox at it, so my partner never sees
    /// a photo id whose image isn't there yet. Returns false if the upload failed.
    func sendPhoto(_ jpeg: Data) async -> Bool {
        lastActivity = .now
        note("tap: photo (\(jpeg.count / 1024) KB)")
        let started = Date.now
        do {
            try await mailbox.savePhoto(Crypto.seal(jpeg, with: key), owner: pairing.myId)
            try photos.save(jpeg, .mine)
        } catch {
            note("photo upload FAILED: \(error.diagnosticDescription)",
                 metric: Metric(kind: .cloud, name: "photo upload", ms: Metric.ms(since: started), detail: "FAILED \(error.diagnosticDescription)"))
            return false
        }
        note("photo uploaded in \(Self.ms(since: started))",
             metric: Metric(kind: .cloud, name: "photo upload", ms: Metric.ms(since: started), detail: "\(jpeg.count / 1024) KB"))
        myPhoto = NSImage(data: jpeg)
        myOutbox.photo = SentPhoto(id: UUID(), sentAt: .now)
        store.myOutbox = myOutbox
        await save()
        return true
    }

    /// Sets (or clears, with nil) my mood and saves it right away.
    func setMood(_ emoji: String?) {
        lastActivity = .now
        myOutbox.mood = emoji
        store.myOutbox = myOutbox
        note("tap: mood \(emoji ?? "cleared")")
        Task { await save() }
    }

    // MARK: Pet

    /// Ours, from both outboxes; nil until one of us adopts.
    var pet: Pet? { Pet.from(mine: myOutbox, theirs: partnerOutbox) }

    func adoptPet(_ kind: PetKind, name: String) {
        guard pet == nil else { return }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        myOutbox.petAdoption = PetAdoption(kind: kind, name: name.isEmpty ? Config.Pet.names[kind]! : name, adoptedAt: .now)
        store.myOutbox = myOutbox
        note("tap: adopted a \(kind.rawValue)")
        saveQuietSoon()
    }

    func care(_ care: PetCare) {
        guard pet != nil else { return }
        lastActivity = .now
        myOutbox.petCare = Array(((myOutbox.petCare ?? []) + [PetAction(care: care, at: .now)]).suffix(Config.Pet.careKept))
        store.myOutbox = myOutbox
        note("tap: pet \(care.rawValue)")
        saveQuietSoon()
    }

    func setPetLook(coat: PetCoat? = nil, accessory: PetAccessory? = nil) {
        guard let current = pet?.look else { return }
        myOutbox.petLook = PetLook(coat: coat ?? current.coat, accessory: accessory ?? current.accessory, setAt: .now)
        store.myOutbox = myOutbox
        note("tap: pet look")
        saveQuietSoon()
    }

    // MARK: Anniversary

    /// Settings → Our anniversary. Both Macs show the newer change.
    func setTogetherSince(_ date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        guard day != togetherSince else { return }
        togetherSince = day
        store.togetherSince = day
        myOutbox.togetherSince = day
        myOutbox.togetherSinceSetAt = .now
        store.myOutbox = myOutbox
        note("changed together-since date")
        Task { await save() }
    }

    // MARK: Hide

    /// Hides OurNotch until `date`; my love sees "away" meanwhile.
    func hide(until date: Date) {
        hiddenUntil = date
        store.hiddenUntil = date
        myOutbox.awayUntil = date
        store.myOutbox = myOutbox
        note("hidden until \(date == .distantFuture ? "I'm back" : date.formatted(date: .omitted, time: .shortened))")
        Task { await save() }
        scheduleReturn()
        onHiddenChanged?()
    }

    /// Brings OurNotch back; anything that arrived meanwhile plays once.
    func show() {
        returnTask?.cancel()
        guard hiddenUntil != nil else { return }
        hiddenUntil = nil
        store.hiddenUntil = nil
        myOutbox.awayUntil = nil
        store.myOutbox = myOutbox
        note("shown again")
        setBannerStart(nil) // a whisper held back while hidden plays its passes in full
        Task { await save() }
        onHiddenChanged?()
        if let held = heldEmojis {
            heldEmojis = nil
            onEmojisArrived?(held.count, held.emojis)
        }
    }

    private func scheduleReturn() {
        returnTask?.cancel()
        guard let hiddenUntil, hiddenUntil != .distantFuture else { return }
        returnTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, hiddenUntil.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            self?.show()
        }
    }

    // MARK: Banner

    /// The banner finished its 3 passes.
    func bannerFinished() {
        setBanner(nil)
    }

    /// Opening the notch dismisses the banner, whichever mode: the whisper is read, and stays readable inside.
    /// (Left up, a `.three` banner would start its 3 passes over when the notch closes.)
    func notchOpened() {
        isNotchOpen = true
        onOpened?()
        setBanner(nil)
    }

    func notchClosed() {
        isNotchOpen = false
    }

    /// The open notch shows this tab (nil: Settings, or closed). Showing a tab clears its dot;
    /// showing Whispers also ends a banner waiting for the notch to close.
    func show(tab: NotchTab?) {
        visibleTab = tab
        guard let tab else { return }
        unseen.remove(tab)
        if tab == .note { setBanner(nil) }
    }

    /// The banner is on screen: its passes count from the first time it was, even across relaunches.
    func bannerAppeared() {
        guard banner != nil, bannerStartedAt == nil else { return }
        setBannerStart(.now)
    }

    private func setBanner(_ message: Message?) {
        banner = message
        store.banner = message
        setBannerStart(nil)
    }

    private func setBannerStart(_ date: Date?) {
        bannerStartedAt = date
        store.bannerStartedAt = date
    }

    // MARK: Syncing

    /// Reads the partner's row, shows anything new, and retries an outbox that didn't save.
    func sync(_ source: SyncSource = .poll) async {
        isSyncing = true
        lastCheck = .now
        defer {
            isSyncing = false
            if let next = queuedSync {
                queuedSync = nil
                Task { await sync(next) }
            }
        }
        if saveTask == nil, myOutbox.content != savedOutbox.content { await save() }

        let started = Date.now
        let partner: Outbox
        do {
            let fetched = try await mailbox.fetchOutboxAndReceipts(owner: pairing.partnerId)
            guard fetched.outbox != nil || fetched.receipts != nil else {
                if source != .poll { note("[\(source.rawValue)] partner has no outbox yet") }
                return
            }
            let receipts = try fetched.receipts.map { try JSONDecoder().decode(Receipts.self, from: Crypto.open($0, with: key)) }
            let outbox = try fetched.outbox.map { try JSONDecoder().decode(Outbox.self, from: Crypto.open($0, with: key)) }
            partner = (outbox ?? Outbox()).with(receipts)
        } catch {
            note("[\(source.rawValue)] fetch FAILED: \(error.diagnosticDescription)",
                 metric: Metric(kind: .cloud, name: "fetch", ms: Metric.ms(since: started), detail: "\(source.rawValue) FAILED \(error.diagnosticDescription)"))
            return
        }
        let fetchTime = Self.ms(since: started)
        let fetchMetric = Metric(kind: .cloud, name: "fetch", ms: Metric.ms(since: started), detail: source.rawValue)
        let previous = partnerOutbox
        partnerOutbox = partner
        if hasFetchedPartner { logReceipts(old: previous, new: partner, source: source) }
        hasFetchedPartner = true
        // My love's Mac just started OurNotch: check fast here too, until 10 minutes after their start.
        if let launched = partner.launchedAt, launched != previous.launchedAt {
            let until = launched.addingTimeInterval(Config.Cloud.launchBoostWindow)
            if until > Date.now, until > (boostUntil ?? .distantPast) {
                boostUntil = until
                note("[\(source.rawValue)] partner started OurNotch: checking every \(Config.Cloud.launchBoostInterval) for a while")
            }
        }
        if let date = partner.togetherSince, date != togetherSince,
           togetherSince == nil || (partner.togetherSinceSetAt ?? .distantPast) > (myOutbox.togetherSinceSetAt ?? .distantPast) {
            togetherSince = date
            store.togetherSince = date
            myOutbox.togetherSince = date
            myOutbox.togetherSinceSetAt = partner.togetherSinceSetAt
            store.myOutbox = myOutbox
            note("[\(source.rawValue)] got together-since date")
            Task { await save() }
        }

        if let key = partner.licenceKey, Licence.adopts(key, over: store.licence) {
            store.licence = Licence(key: key)
            note("[\(source.rawValue)] got licence from partner")
            onLicenceChanged?()
        }

        var found: [String] = []
        if hasFetchedPartner, partner.petAdoption != previous.petAdoption || partner.petCare != previous.petCare || partner.petLook != previous.petLook {
            found.append("pet")
            if !(isNotchOpen && visibleTab == .pet) { unseen.insert(.pet) }
        }
        if partner.mood != previous.mood, hasFetchedPartner {
            found.append("mood \(partner.mood ?? "cleared")")
            // Closed, the mood shows beside the camera; open, only on Home and Mood.
            if isNotchOpen, partner.mood != nil, visibleTab != .home, visibleTab != .mood { unseen.insert(.home) }
        }
        let newEmojis = Arrival.newCount(partnerSent: partner.emojisSent, lastShown: myOutbox.seenEmojis)
        let arrivedEmojis = Arrival.emojis(forNew: newEmojis, recent: partner.recentEmojis, last: partner.lastEmoji)
        if let emoji = arrivedEmojis.last {
            myOutbox.seenEmojis = partner.emojisSent
            if isHidden {
                heldEmojis = ((heldEmojis?.count ?? 0) + newEmojis,
                              Array(((heldEmojis?.emojis ?? []) + arrivedEmojis).suffix(Config.recentEmojis)))
            } else {
                onEmojisArrived?(newEmojis, arrivedEmojis)
            }
            let age = emoji.sentAt.map { ", sent \(Self.ms(since: $0)) ago" } ?? ""
            found.append("\(newEmojis) emoji \(arrivedEmojis.map(\.char).joined()) (\(emoji.mode.rawValue)\(age))")
            if let sentAt = emoji.sentAt { arrived("emoji", sentAt: sentAt, source: source) }
        }
        if let message = partner.message, message.id != myOutbox.seenMessageId {
            myOutbox.seenMessageId = message.id
            if isNotchOpen, visibleTab == .note || visibleTab == .home {
                // Read as it arrived: no banner afterwards.
            } else {
                setBanner(message) // scrolls once the notch closes
                if isNotchOpen { unseen.insert(.note) }
            }
            found.append("note (\(message.mode.rawValue), sent \(Self.ms(since: message.sentAt)) ago)")
            arrived("note", sentAt: message.sentAt, source: source)
        }
        if let photo = partner.photo, photo.id != myOutbox.seenPhotoId, await downloadPartnerPhoto() {
            myOutbox.seenPhotoId = photo.id
            // It shows on Home, and nowhere in the closed notch.
            if !(isNotchOpen && visibleTab == .home) { unseen.insert(.home) }
            found.append("photo (sent \(Self.ms(since: photo.sentAt)) ago)")
            arrived("photo", sentAt: photo.sentAt, source: source)
        }

        // Quiet polls aren't measured: Debug checks every 3 s.
        if !found.isEmpty {
            if source != .launch { lastActivity = .now } // what was waiting at launch isn't a conversation
            note("[\(source.rawValue)] found \(found.joined(separator: ", ")); fetch \(fetchTime)", metric: fetchMetric)
        } else if source != .poll {
            note("[\(source.rawValue)] no change found; fetch \(fetchTime)", metric: fetchMetric)
        }
        guard myOutbox.receipts != savedReceipts else { return }
        store.myOutbox = myOutbox
        await saveReceipts() // tells the partner "delivered"
    }

    /// The partner's tap → shown on this Mac.
    /// Only a metric: the "found" line already says it in words.
    private func arrived(_ name: String, sentAt: Date, source: SyncSource) {
        Diagnostics.shared.measure(Metric(owner: pairing.myId, kind: .arrival, name: name, ms: Metric.ms(since: sentAt), detail: source.rawValue))
    }

    /// Logs when my partner's Mac has shown what I sent: the "Delivered" moments.
    private func logReceipts(old: Outbox, new: Outbox, source: SyncSource) {
        if new.seenEmojis > old.seenEmojis {
            let sentAt = new.seenEmojis == myOutbox.emojisSent ? myOutbox.lastEmoji?.sentAt : nil
            note("delivered: partner showed emojis up to #\(new.seenEmojis)\(sentAt.map { " (last sent \(Self.ms(since: $0)) ago)" } ?? "")",
                 metric: sentAt.map { Metric(kind: .delivered, name: "emoji", ms: Metric.ms(since: $0), detail: source.rawValue) })
        }
        if new.seenMessageId != old.seenMessageId, let sent = myOutbox.message, new.seenMessageId == sent.id {
            note("delivered: partner showed my note (sent \(Self.ms(since: sent.sentAt)) ago)",
                 metric: Metric(kind: .delivered, name: "note", ms: Metric.ms(since: sent.sentAt), detail: source.rawValue))
        }
        if new.seenPhotoId != old.seenPhotoId, let sent = myOutbox.photo, new.seenPhotoId == sent.id {
            note("delivered: partner downloaded my photo (sent \(Self.ms(since: sent.sentAt)) ago)",
                 metric: Metric(kind: .delivered, name: "photo", ms: Metric.ms(since: sent.sentAt), detail: source.rawValue))
        }
    }

    private func downloadPartnerPhoto() async -> Bool {
        let started = Date.now
        do {
            guard let sealed = try await mailbox.fetchPhoto(owner: pairing.partnerId) else { return false }
            let jpeg = try Crypto.open(sealed, with: key)
            try photos.save(jpeg, .partner)
            partnerPhoto = NSImage(data: jpeg)
            note("photo downloaded (\(jpeg.count / 1024) KB) in \(Self.ms(since: started))",
                 metric: Metric(kind: .cloud, name: "photo download", ms: Metric.ms(since: started), detail: "\(jpeg.count / 1024) KB"))
            return true
        } catch {
            note("photo download FAILED: \(error.diagnosticDescription)",
                 metric: Metric(kind: .cloud, name: "photo download", ms: Metric.ms(since: started), detail: "FAILED \(error.diagnosticDescription)"))
            return false
        }
    }

    /// One save at a time: a save asked for while another runs (a mood change mid-burst) goes out right after it,
    /// so the same change isn't saved, and rung, twice.
    private func save() async {
        if isSaving { saveAgain = true; return }
        isSaving = true
        defer { isSaving = false }
        repeat {
            saveAgain = false
            await saveOnce()
        } while saveAgain && myOutbox.content != savedOutbox.content
    }

    private func saveOnce() async {
        let snapshot = myOutbox
        let changes = Self.changes(from: savedOutbox, to: snapshot)
        let started = Date.now
        do {
            let sealed = try Crypto.seal(JSONEncoder().encode(snapshot), with: key)
            try await mailbox.saveOutbox(sealed, owner: pairing.myId)
            savedOutbox = snapshot
            store.savedOutbox = snapshot
            live?.ring()
            note("saved outbox (\(changes)) in \(Self.ms(since: started))\(live?.partnerHere == true ? ", rang" : "")",
                 metric: Metric(kind: .cloud, name: "save", ms: Metric.ms(since: started), detail: changes))
        } catch {
            note("save FAILED (\(changes)), will retry: \(error.diagnosticDescription)",
                 metric: Metric(kind: .cloud, name: "save", ms: Metric.ms(since: started), detail: "FAILED \(error.diagnosticDescription)"))
        }
    }

    /// "Seen" goes in its own record, which doesn't ping the partner (Apple's budget); the doorbell rings instead.
    private func saveReceipts() async {
        let receipts = myOutbox.receipts
        let started = Date.now
        do {
            let sealed = try Crypto.seal(JSONEncoder().encode(receipts), with: key)
            try await mailbox.saveReceipts(sealed, owner: pairing.myId)
            // Ring for anything but the 5-minute "still here", so "delivered" shows within a second or two.
            var heard = receipts
            heard.lastSeen = savedReceipts.lastSeen
            let rang = heard != savedReceipts && live?.partnerHere == true
            if rang { live?.ring() }
            savedReceipts = receipts
            note("saved receipts (seen emojis \(receipts.seenEmojis)\(receipts.petAdoption == nil ? "" : ", pet")) in \(Self.ms(since: started))\(rang ? ", rang" : "")",
                 metric: Metric(kind: .cloud, name: "save", ms: Metric.ms(since: started), detail: "receipts"))
        } catch {
            note("receipts save FAILED, will retry: \(error.diagnosticDescription)",
                 metric: Metric(kind: .cloud, name: "save", ms: Metric.ms(since: started), detail: "receipts FAILED \(error.diagnosticDescription)"))
        }
    }

    /// What differs between two outboxes, for the log, never the note's text.
    private static func changes(from old: Outbox, to new: Outbox) -> String {
        var parts: [String] = []
        if new.emojisSent != old.emojisSent { parts.append("emojis \(old.emojisSent)→\(new.emojisSent)") }
        if new.message != old.message { parts.append("note") }
        if new.photo != old.photo { parts.append("photo") }
        if new.mood != old.mood { parts.append("mood \(new.mood ?? "cleared")") }
        if new.togetherSince != old.togetherSince { parts.append("date") }
        if new.licenceKey != old.licenceKey { parts.append("licence") }
        if new.awayUntil != old.awayUntil { parts.append(new.awayUntil == nil ? "back" : "away") }
        if new.launchedAt != old.launchedAt { parts.append("started") }
        if new.petAdoption != old.petAdoption || new.petCare != old.petCare || new.petLook != old.petLook { parts.append("pet") }
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

/// How often to check the partner's row, kept pure for tests.
enum CheckPace {
    /// Fastest just after either Mac started OurNotch, fast while the notch is open or soon after sending or
    /// receiving (a reply is likely), otherwise `idle`. While both Macs are at the doorbell (`partnerLive`), rings
    /// bring changes, so the fast checks relax to a backup pace.
    static func interval(notchOpen: Bool, lastActivity: Date?, boostUntil: Date? = nil, partnerLive: Bool = false,
                         idle: Duration, now: Date = .now) -> Duration {
        let recent = lastActivity.map { now.timeIntervalSince($0) < Config.Cloud.activeWindow } ?? false
        let fast: Duration
        if let boostUntil, now < boostUntil { fast = Config.Cloud.launchBoostInterval }
        else if notchOpen { fast = Config.Cloud.openPollInterval }
        else if recent { fast = Config.Cloud.activePollInterval }
        else { return idle }
        return min(idle, partnerLive ? Config.Live.backupInterval : fast)
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

    /// Days until the next anniversary of the together-since date; 0 on the day itself.
    static func daysToAnniversary(since start: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        let parts = calendar.dateComponents([.month, .day], from: start)
        if parts.month == calendar.component(.month, from: today), parts.day == calendar.component(.day, from: today) { return 0 }
        guard let next = calendar.nextDate(after: today, matching: parts, matchingPolicy: .nextTimePreservingSmallerComponents) else { return 0 }
        return calendar.dateComponents([.day], from: today, to: next).day ?? 0
    }

    /// Saturdays from the together-since day through today, counting both ends.
    static func weekends(since start: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        let days = days(since: start, now: now, calendar: calendar)
        let toFirstSaturday = (14 - calendar.component(.weekday, from: start)) % 7 // weekday: Sunday 1 … Saturday 7
        return days >= toFirstSaturday ? (days - toFirstSaturday) / 7 + 1 : 0
    }
}
