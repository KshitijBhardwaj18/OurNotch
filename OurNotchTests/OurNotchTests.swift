import Foundation
import ImageIO
import Testing
@testable import OurNotch

struct TogetherTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }

    @Test func daysToAnniversaryCountsDownAndIsZeroOnTheDay() {
        let since = date(2022, 3, 14)
        #expect(Together.daysToAnniversary(since: since, now: date(2026, 3, 14, 18), calendar: calendar) == 0)
        #expect(Together.daysToAnniversary(since: since, now: date(2026, 3, 13), calendar: calendar) == 1)
        #expect(Together.daysToAnniversary(since: since, now: date(2026, 3, 15), calendar: calendar) == 364)
        // Together on 29 Feb: in other years the anniversary is kept on 1 March.
        #expect(Together.daysToAnniversary(since: date(2024, 2, 29), now: date(2026, 2, 27), calendar: calendar) == 2)
    }

    @Test func countsWholeCalendarDays() {
        #expect(Together.days(since: date(2023, 2, 14), now: date(2023, 2, 14, 23, 59), calendar: calendar) == 0)
        #expect(Together.days(since: date(2023, 2, 14, 22), now: date(2023, 2, 15, 1), calendar: calendar) == 1)
        #expect(Together.days(since: date(2023, 2, 14), now: date(2024, 2, 14), calendar: calendar) == 365)
    }

    @Test func futureDateNeverGoesNegative() {
        #expect(Together.days(since: date(2030, 1, 1), now: date(2026, 1, 1), calendar: calendar) == 0)
    }

    @Test func hoursAndSecondsCountFromStartOfDay() {
        let since = date(2023, 2, 14, 18), now = date(2023, 2, 16, 3, 4, 5)
        #expect(Together.seconds(since: since, now: now, calendar: calendar) == ((2 * 24 + 3) * 60 + 4) * 60 + 5)
        #expect(Together.hours(since: since, now: now, calendar: calendar) == 51)
    }

    @Test func weekendsCountSaturdays() {
        // 2023-02-14 was a Tuesday; the first Saturday is the 18th.
        #expect(Together.weekends(since: date(2023, 2, 14), now: date(2023, 2, 17), calendar: calendar) == 0)
        #expect(Together.weekends(since: date(2023, 2, 14), now: date(2023, 2, 18), calendar: calendar) == 1)
        #expect(Together.weekends(since: date(2023, 2, 14), now: date(2023, 2, 25), calendar: calendar) == 2)
        // Starting on a Saturday counts that day.
        #expect(Together.weekends(since: date(2023, 2, 18), now: date(2023, 2, 18), calendar: calendar) == 1)
    }
}

struct HideTests {
    private let calendar = Calendar(identifier: .gregorian)
    private func date(_ d: Int, _ h: Int, _ m: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: d, hour: h, minute: m))!
    }

    @Test func comesBackAtTheRightTime() {
        #expect(Hide.hour.until(now: date(5, 14), calendar: calendar) == date(5, 15))
        #expect(Hide.untilTomorrow.until(now: date(5, 14), calendar: calendar) == date(6, 6))  // afternoon → tomorrow 6 am
        #expect(Hide.untilTomorrow.until(now: date(5, 2), calendar: calendar) == date(5, 6))   // 2 am → this morning
        #expect(Hide.untilBack.until(now: date(5, 14), calendar: calendar) == .distantFuture)
        #expect(Hide.isHidden(until: date(5, 15), now: date(5, 14)))
        #expect(!Hide.isHidden(until: date(5, 15), now: date(5, 15, 1)))
        #expect(!Hide.isHidden(until: nil))
    }
}

struct ArrivalTests {
    @Test func missedEmojisAreTheDifference() {
        #expect(Arrival.newCount(partnerSent: 12, lastShown: 9) == 3)
        #expect(Arrival.newCount(partnerSent: 9, lastShown: 9) == 0)
        #expect(Arrival.newCount(partnerSent: 2, lastShown: 9) == 0) // partner reinstalled; never negative
    }

    @Test func senderChoosesUnlessThreeOrMoreArrive() {
        #expect(Arrival.effect(forNew: 0, mode: .notch) == nil)
        #expect(Arrival.effect(forNew: 1, mode: .notch) == .pour)
        #expect(Arrival.effect(forNew: 2, mode: .notch) == .pour)
        #expect(Arrival.effect(forNew: 1, mode: .fullScreen) == .splash)
        #expect(Arrival.effect(forNew: 3, mode: .notch) == .splash) // missed while away
        #expect(Arrival.effect(forNew: 12, mode: .notch) == .splash)
    }

    @Test func emojisSentThenDelivered() {
        #expect(DeliveryStatus.counted(sent: 0, saved: 0, partnerSeen: 0) == .none)
        #expect(DeliveryStatus.counted(sent: 5, saved: 4, partnerSeen: 4) == .sending)
        #expect(DeliveryStatus.counted(sent: 5, saved: 5, partnerSeen: 4) == .sent)
        #expect(DeliveryStatus.counted(sent: 5, saved: 5, partnerSeen: 5) == .delivered)
    }

    @Test func messageSentThenDelivered() {
        let id = UUID(), older = UUID()
        #expect(DeliveryStatus.latest(id: nil, savedId: nil, partnerSeenId: nil) == .none)
        #expect(DeliveryStatus.latest(id: id, savedId: older, partnerSeenId: older) == .sending)
        #expect(DeliveryStatus.latest(id: id, savedId: id, partnerSeenId: older) == .sent)
        #expect(DeliveryStatus.latest(id: id, savedId: id, partnerSeenId: id) == .delivered)
    }
}

struct MessageRulesTests {
    @Test func acceptsTheSampleMessageTrimmed() {
        #expect(MessageRules.check("  hi babe how are you? love you \n") == .valid("hi babe how are you? love you"))
    }

    @Test func emptyOrWhitespaceCannotBeSent() {
        #expect(MessageRules.check("") == .empty)
        #expect(MessageRules.check("   \n ") == .empty)
    }

    @Test func rejectsOverTheLimits() {
        let elevenWords = Array(repeating: "hi", count: 11).joined(separator: " ")
        #expect(MessageRules.check(elevenWords) == .invalid(hint: "10 words max ♡"))
        #expect(MessageRules.wordCount("hi babe  how ") == 3)
        let sixtyOneChars = "aaaaaaaaaa aaaaaaaaaa aaaaaaaaaa aaaaaaaaaa aaaaaaaaaa aaaaaa"
        #expect(sixtyOneChars.count == 61)
        #expect(MessageRules.check(sixtyOneChars) == .invalid(hint: "A little shorter ♡"))
        #expect(MessageRules.check("sooooooooooooooo cute") == .invalid(hint: "One word is too long ♡"))
        #expect(MessageRules.check("soooooooooooooo cute") == .valid("soooooooooooooo cute")) // 15 letters is fine
        #expect(MessageRules.check("see you soon ♡ ♥ ❤ ❤️") == .valid("see you soon ❤️ ❤️ ❤️ ❤️")) // text hearts turn red
    }
}

/// Two people on one temporary mailbox, each with its own local storage.
private struct TwoPartners {
    let mailbox = LocalFileMailbox(directory: .temporaryDirectory.appending(path: UUID().uuidString))
    let photosRoot = URL.temporaryDirectory.appending(path: UUID().uuidString)
    let you = LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    let partner = LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

    var yourService: PairingService { PairingService(mailbox: mailbox, store: you) }
    var partnerService: PairingService { PairingService(mailbox: mailbox, store: partner) }

    /// You invite, your partner joins with the code.
    @MainActor
    func paired(togetherSince: Date? = nil) async throws -> (you: AppState, partner: AppState) {
        you.togetherSince = togetherSince
        let code = try await yourService.createInvite(name: "Kshitij")
        let invite = try await partnerService.lookUpInvite(code: code.lowercased())
        try await partnerService.requestJoin(code: code.lowercased(), name: "Nikki")
        let join = try #require(try await yourService.pendingJoins(code: code, declined: []).first)
        _ = try await yourService.approve(join, code: code)
        _ = try #require(try await partnerService.checkAnswer(code: code, invite: invite))
        return (try #require(AppState(store: you, mailbox: mailbox, photosRoot: photosRoot)),
                try #require(AppState(store: partner, mailbox: mailbox, photosRoot: photosRoot)))
    }
}

struct CryptoTests {
    @Test func bothPartnersDeriveTheSameKeyAndOnlyItOpens() throws {
        let mine = Crypto.PrivateKey(), theirs = Crypto.PrivateKey()
        let myKey = try Crypto.sharedKey(myPrivateKey: mine, partnerPublicKey: theirs.publicKey.rawRepresentation, pairId: "ABC234")
        let theirKey = try Crypto.sharedKey(myPrivateKey: theirs, partnerPublicKey: mine.publicKey.rawRepresentation, pairId: "ABC234")

        let sealed = try Crypto.seal(Data("love you".utf8), with: myKey)
        #expect(try Crypto.open(sealed, with: theirKey) == Data("love you".utf8))
        #expect(sealed.range(of: Data("love you".utf8)) == nil)

        let stranger = try Crypto.sharedKey(myPrivateKey: Crypto.PrivateKey(), partnerPublicKey: theirs.publicKey.rawRepresentation, pairId: "ABC234")
        #expect(throws: (any Error).self) { try Crypto.open(sealed, with: stranger) }
    }
}

struct PairingTests {
    @Test func codesAvoidLookalikeCharacters() {
        for _ in 0..<200 {
            let code = PairingService.makeCode()
            #expect(code.count == 6)
            #expect(!code.contains { "0O1I".contains($0) })
        }
        #expect(PairingService.normalize(" abc-234 ") == "ABC234")
    }

    @Test func bothSidesSayYesBeforePairing() async throws {
        let people = TwoPartners()
        let code = try await people.yourService.createInvite(name: "Kshitij")
        #expect(try await people.yourService.pendingJoins(code: code, declined: []).isEmpty) // still waiting

        let invite = try await people.partnerService.lookUpInvite(code: code)
        #expect(invite.inviterName == "Kshitij") // "Kshitij invited you, is that right?"
        try await people.partnerService.requestJoin(code: code, name: "Nikki")
        #expect(try await people.partnerService.checkAnswer(code: code, invite: invite) == nil)
        #expect(people.you.pairing == nil && people.partner.pairing == nil) // nothing until the inviter says yes

        let join = try #require(try await people.yourService.pendingJoins(code: code, declined: []).first)
        #expect(join.joinerName == "Nikki") // "Nikki wants to join, is this your love?"
        let inviter = try await people.yourService.approve(join, code: code)
        #expect(inviter.partnerId == people.partner.myId && inviter.role == .inviter)

        let joined = try #require(try await people.partnerService.checkAnswer(code: code, invite: invite))
        #expect(joined.partnerName == "Kshitij" && joined.role == .joiner)
    }

    @Test func aDeclinedStrangerDoesntUseUpTheCode() async throws {
        let people = TwoPartners()
        let code = try await people.yourService.createInvite(name: "Kshitij")
        let stranger = PairingService(mailbox: people.mailbox, store: LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        let invite = try await stranger.lookUpInvite(code: code)
        try await stranger.requestJoin(code: code, name: "Stranger")
        try await people.partnerService.requestJoin(code: code, name: "Nikki")

        let first = try #require(try await people.yourService.pendingJoins(code: code, declined: []).first)
        #expect(first.joinerName == "Stranger")
        try await people.yourService.decline(first, code: code)
        await #expect(throws: PairingError.declined) { try await stranger.checkAnswer(code: code, invite: invite) }

        let next = try #require(try await people.yourService.pendingJoins(code: code, declined: [first.joinerId]).first)
        #expect(next.joinerName == "Nikki") // the code still works for the right person
        _ = try await people.yourService.approve(next, code: code)
        #expect(try await people.partnerService.checkAnswer(code: code, invite: invite) != nil)

        let late = PairingService(mailbox: people.mailbox, store: LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        try await late.requestJoin(code: code, name: "Late")
        await #expect(throws: PairingError.usedCode) { try await late.checkAnswer(code: code, invite: invite) }
    }

    @Test func madeUpAndExpiredCodesAreRejected() async throws {
        let people = TwoPartners()
        await #expect(throws: PairingError.invalidCode) {
            try await people.partnerService.lookUpInvite(code: "ZZZZZZ")
        }
        let code = try await people.yourService.createInvite(name: "Kshitij")
        let tomorrow = Date.now.addingTimeInterval(Config.Pairing.codeLifetime + 60)
        await #expect(throws: PairingError.expiredCode) {
            try await people.partnerService.lookUpInvite(code: code, now: tomorrow)
        }
        _ = try await people.partnerService.lookUpInvite(code: code, now: .now.addingTimeInterval(23 * 3600)) // still fine
    }
}

@MainActor
struct PartnersTests {
    @Test func outboxesAreEncryptedInTheMailbox() async throws {
        let people = TwoPartners()
        let (you, _) = try await people.paired()
        you.sendMessage("hi babe how are you? love you", mode: .three)
        try await Task.sleep(for: .milliseconds(100))
        let stored = try #require(try await people.mailbox.fetchOutbox(owner: people.you.myId))
        #expect(stored.range(of: Data("hi babe".utf8)) == nil)
        #expect((try? JSONDecoder().decode(Outbox.self, from: stored)) == nil)
    }

    @Test func partnerIsCoveredByTheBuyersKey() async throws {
        let people = TwoPartners()
        people.you.licence = Licence(key: "BUYER-KEY", activationId: "lki_1")
        let (you, partner) = try await people.paired()
        var changed = 0
        partner.onLicenceChanged = { changed += 1 }
        await you.sync()     // saves the buyer's outbox, key included (encrypted)
        await partner.sync()
        #expect(people.partner.licence == Licence(key: "BUYER-KEY"))
        #expect(people.partner.licence?.isBuyer == false) // the partner uses no slot
        #expect(changed == 1)
        await partner.sync()
        #expect(changed == 1) // only once
        let stored = try #require(try await people.mailbox.fetchOutbox(owner: people.you.myId))
        #expect(stored.range(of: Data("BUYER-KEY".utf8)) == nil)
    }

    @Test func arrivalsWaitWhileHiddenAndPlayOnce() async throws {
        let people = TwoPartners()
        let (you, partner) = try await people.paired()
        var played: [Int] = []
        partner.onEmojisArrived = { count, _ in played.append(count) }

        partner.hide(until: Hide.hour.until())
        #expect(partner.isHidden)
        you.sendEmoji("❤️", mode: .notch)
        you.sendEmoji("❤️", mode: .notch)
        #expect(you.sendMessage("miss you", mode: .three))
        try await Task.sleep(for: .milliseconds(1200)) // emoji taps are bundled for a second
        await you.sync()
        #expect(you.partnerIsAway()) // my notch shows "away"

        await partner.sync()
        #expect(played.isEmpty)               // nothing plays while hidden
        #expect(partner.visibleBanner == nil) // the note waits too
        #expect(partner.banner?.text == "miss you")

        partner.show()
        #expect(played == [2])                // both, once, on return
        #expect(partner.visibleBanner?.text == "miss you")
        try await Task.sleep(for: .milliseconds(100))
        await you.sync()
        #expect(!you.partnerIsAway())
    }

    @Test func hiddenSurvivesARestartUntilItsTime() async throws {
        let people = TwoPartners()
        let (_, partner) = try await people.paired()
        partner.hide(until: Hide.untilBack.until())
        let relaunched = try #require(AppState(store: people.partner, mailbox: people.mailbox, photosRoot: people.photosRoot))
        #expect(relaunched.isHidden)
        people.partner.hiddenUntil = .now.addingTimeInterval(-1) // the hour passed while the app was closed
        let later = try #require(AppState(store: people.partner, mailbox: people.mailbox, photosRoot: people.photosRoot))
        #expect(!later.isHidden && later.myOutbox.awayUntil == nil)
    }

    @Test func onlyTheBuyerCanInvite() {
        let store = LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let model = OnboardingModel(store: store, mailbox: LocalFileMailbox(directory: .temporaryDirectory.appending(path: UUID().uuidString))) {}
        #expect(model.step == .gate)
        model.go(to: .invite)
        #expect(model.inviteCode == nil)
        #expect(model.error?.hasPrefix("Only the person who bought") == true)
    }

    @Test func joinerReceivesTogetherSince() async throws {
        let date = Date(timeIntervalSince1970: 1_676_332_800) // 2023-02-14
        let (you, partner) = try await TwoPartners().paired(togetherSince: date)
        #expect(you.togetherSince == date)
        #expect(partner.togetherSince == nil)
        await you.sync()      // saves the inviter's outbox with the date
        await partner.sync()
        #expect(partner.togetherSince == date)
    }

    @Test func messageArrivesAndIsDelivered() async throws {
        let (you, partner) = try await TwoPartners().paired()
        #expect(you.sendMessage("hi babe how are you? love you", mode: .untilOpened))
        try await Task.sleep(for: .milliseconds(100)) // the save runs in its own task
        #expect(you.messageStatus == .sent)

        await partner.sync()
        #expect(partner.banner?.text == "hi babe how are you? love you")

        await you.sync()
        #expect(you.messageStatus == .delivered)

        partner.notchOpened()
        #expect(partner.banner == nil)
    }

    @Test func emojisArriveAndAreDelivered() async throws {
        let (you, partner) = try await TwoPartners().paired()
        var arrived = 0
        var latest: SentEmoji?
        partner.onEmojisArrived = { arrived += $0; latest = $1 }
        you.sendEmoji("❤️", mode: .notch)
        you.sendEmoji("😘", mode: .fullScreen)
        you.sendEmoji("🌹", mode: .notch)
        #expect(you.emojiStatus == .sending) // bundled, not saved yet
        try await Task.sleep(for: Config.emojiBundleDelay + .milliseconds(200))

        await partner.sync()
        #expect(arrived == 3)
        await you.sync()
        #expect(latest?.char == "🌹" && latest?.mode == .notch && latest?.sentAt != nil)
        #expect(you.emojiStatus == .delivered)
    }

    @Test func invalidMessageIsNotSent() async throws {
        let (you, _) = try await TwoPartners().paired()
        #expect(!you.sendMessage("   ", mode: .three))
        #expect(you.myOutbox.message == nil)
    }
}

struct PhotoTests {
    /// Writes a solid-color PNG of the given size to a temporary file.
    private func imageFile(width: Int, height: Int) throws -> URL {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 1, green: 0.4, blue: 0.6, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).png")
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        CGImageDestinationFinalize(destination)
        return url
    }

    private func pixelSize(_ jpeg: Data) -> (Int, Int) {
        let image = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithData(jpeg as CFData, nil)!, 0, nil)!
        return (image.width, image.height)
    }

    @Test func photosBecomeSmallSquareJPEGs() throws {
        let big = try PhotoProcessing.squareJPEG(from: imageFile(width: 3000, height: 2000))
        #expect(pixelSize(big) == (512, 512))
        #expect(big.prefix(2) == Data([0xFF, 0xD8])) // JPEG
        let small = try PhotoProcessing.squareJPEG(from: imageFile(width: 300, height: 400))
        #expect(pixelSize(small) == (300, 300)) // never scaled up
    }
}

@MainActor
struct PhotoDeliveryTests {
    @Test func photoArrivesEncryptedAndIsDelivered() async throws {
        let people = TwoPartners()
        let (you, partner) = try await people.paired()
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0]) + Data("pretend photo".utf8)

        #expect(await you.sendPhoto(jpeg))
        #expect(you.photoStatus == .sent)
        let stored = try #require(try await people.mailbox.fetchPhoto(owner: people.you.myId))
        #expect(stored.prefix(2) != Data([0xFF, 0xD8])) // not a readable JPEG in the mailbox
        #expect(stored.range(of: Data("pretend photo".utf8)) == nil)

        await partner.sync()
        #expect(partner.partnerOutbox.photo != nil)
        #expect(PhotoCache(ownerId: people.partner.myId, root: people.photosRoot).load(.partner) == jpeg)

        await you.sync()
        #expect(you.photoStatus == .delivered)
    }
}

@MainActor
struct MoodTests {
    @Test func moodReachesPartnerAndClears() async throws {
        let (you, partner) = try await TwoPartners().paired()
        you.setMood("😴")
        try await Task.sleep(for: .milliseconds(100))
        await partner.sync()
        #expect(partner.partnerOutbox.mood == "😴")
        #expect(Config.moodLabel("😴") == "Sleepy")
        #expect(partner.closedSideWidth == Config.Notch.closedSideWidthWithMood) // room for "😴 sleepy"

        you.setMood(nil)
        try await Task.sleep(for: .milliseconds(100))
        await partner.sync()
        #expect(partner.partnerOutbox.mood == nil)
        #expect(partner.closedSideWidth == Config.Notch.closedSideWidth)
    }
}

@MainActor
struct MetricsTests {
    @Test func deliveryIsMeasuredOnBothSidesAndStored() async throws {
        let people = TwoPartners()
        let (you, partner) = try await people.paired()
        partner.setMood("😊") // gives the partner an outbox, so receipts are tracked from your first fetch
        try await Task.sleep(for: .milliseconds(200))
        await you.sync()
        you.sendMessage("hi", mode: .three)
        try await Task.sleep(for: .milliseconds(200))
        await partner.sync()
        await you.sync()

        let queued = Diagnostics.shared.pendingMetrics
        #expect(queued.contains { $0.owner == partner.pairing.myId && $0.kind == .arrival && $0.name == "note" })
        #expect(queued.contains { $0.owner == you.pairing.myId && $0.kind == .delivered && $0.name == "note" })

        let mine = queued.filter { $0.owner == you.pairing.myId }
        try await people.mailbox.saveMetrics(mine)
        #expect(try await people.mailbox.fetchMetrics(owner: you.pairing.myId) == mine)
    }
}

struct CheckPaceTests {
    @Test func fastWhileOpenOrRecentlyActive() {
        let now = Date.now, idle = Duration.seconds(60)
        #expect(CheckPace.interval(notchOpen: false, lastActivity: nil, idle: idle, now: now) == .seconds(60))
        #expect(CheckPace.interval(notchOpen: true, lastActivity: nil, idle: idle, now: now) == .seconds(10))
        #expect(CheckPace.interval(notchOpen: false, lastActivity: now.addingTimeInterval(-179), idle: idle, now: now) == .seconds(10))
        #expect(CheckPace.interval(notchOpen: false, lastActivity: now.addingTimeInterval(-181), idle: idle, now: now) == .seconds(60))
        // Never slower than the idle pace (Debug's 3 s).
        #expect(CheckPace.interval(notchOpen: true, lastActivity: nil, idle: .seconds(3), now: now) == .seconds(3))
    }
}

struct LicenceTests {
    private func json(_ s: String) -> Data { Data(s.utf8) }

    @Test func activationAnswers() throws {
        #expect(try LicenceService.activationId(status: 201, body: json(#"{"id":"lki_123","name":"Mac"}"#)) == "lki_123")
        #expect(throws: LicenceError.notFound) { try LicenceService.activationId(status: 404, body: Data()) }
        #expect(throws: LicenceError.inUse) { try LicenceService.activationId(status: 422, body: Data()) }
        #expect(throws: LicenceError.revoked) { try LicenceService.activationId(status: 403, body: Data()) }
        #expect(throws: LicenceError.unreachable) { try LicenceService.activationId(status: 503, body: Data()) }
        #expect(throws: LicenceError.unreachable) { try LicenceService.activationId(status: nil, body: Data()) }
    }

    @Test func onlyAnExplicitNoRevokes() {
        #expect(LicenceService.validity(status: 200, body: json(#"{"valid":true}"#)) == true)
        #expect(LicenceService.validity(status: 200, body: json(#"{"valid":false}"#)) == false)
        #expect(LicenceService.validity(status: 403, body: Data()) == false)
        #expect(LicenceService.validity(status: 404, body: Data()) == false)
        #expect(LicenceService.validity(status: 500, body: Data()) == nil) // Dodo down: keep the last answer
        #expect(LicenceService.validity(status: nil, body: Data()) == nil) // offline: keep the last answer
    }

    @Test func dodosAnswerSetsTheStatus() {
        let active = Licence(key: "K", activationId: "lki_1")
        #expect(LicenceService.applying(false, to: active).status == .revoked)
        #expect(LicenceService.applying(true, to: Licence(key: "K", status: .revoked)).status == .active) // restored
        #expect(LicenceService.applying(nil, to: Licence(key: "K", status: .revoked)).status == .revoked) // offline: unchanged
        #expect(LicenceService.applying(true, to: Licence(key: "K", status: .removed)).status == .removed) // removed stays removed
        #expect(Licence(key: "K", status: .revoked).isLocked && Licence(key: "K", status: .removed).isLocked && !active.isLocked)
    }

    @Test func partnerAdoptsTheBuyersNewestKeyButNeverReplacesItsOwn() {
        #expect(Licence.adopts("A", over: nil))
        #expect(Licence.adopts("B", over: Licence(key: "A", status: .revoked))) // buyer bought a new key
        #expect(!Licence.adopts("A", over: Licence(key: "A")))                  // already have it
        #expect(!Licence.adopts("B", over: Licence(key: "A", activationId: "lki_1"))) // bought their own
        #expect(!Licence.adopts("B", over: Licence(key: "A", status: .removed)))
    }

    @Test func licenceSurvivesInTheStore() {
        let store = LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(store.licence == nil)
        store.licence = Licence(key: "ABC", activationId: "lki_1", lastGoodCheck: .now)
        #expect(store.licence?.key == "ABC")
        store.licence = nil
        #expect(store.licence == nil)
    }
}

@MainActor
struct NoteHistoryTests {
    @Test func keepsTheLastTenAndInterleavesBothSides() async throws {
        let (you, partner) = try await TwoPartners().paired()
        for i in 1...12 { you.sendMessage("note \(i)", mode: .three) }
        #expect(you.myOutbox.notes.map(\.text) == (3...12).map { "note \($0)" }) // oldest two dropped
        #expect(you.myOutbox.message?.text == "note 12") // still the one that scrolls

        partner.sendMessage("hi back", mode: .three)
        try await Task.sleep(for: .milliseconds(200))
        await partner.sync()
        await you.sync()
        let lines = Conversation.lines(mine: partner.myOutbox, theirs: partner.partnerOutbox)
        #expect(lines.count == 11)
        #expect(lines.last?.message.text == "hi back" && lines.last?.isMine == true)
        #expect(lines.filter { !$0.isMine }.map(\.message.text) == (3...12).map { "note \($0)" })
    }
}
