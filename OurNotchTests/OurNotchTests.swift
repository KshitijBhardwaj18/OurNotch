import Foundation
import Testing
@testable import OurNotch

struct TogetherTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }

    @Test func countsWholeCalendarDays() {
        #expect(Together.days(since: date(2023, 2, 14), now: date(2023, 2, 14, 23, 59), calendar: calendar) == 0)
        #expect(Together.days(since: date(2023, 2, 14, 22), now: date(2023, 2, 15, 1), calendar: calendar) == 1)
        #expect(Together.days(since: date(2023, 2, 14), now: date(2024, 2, 14), calendar: calendar) == 365)
    }

    @Test func futureDateNeverGoesNegative() {
        #expect(Together.days(since: date(2030, 1, 1), now: date(2026, 1, 1), calendar: calendar) == 0)
    }

    @Test func liveCounterCountsFromStartOfDay() {
        let c = Together.elapsed(since: date(2023, 2, 14, 18), now: date(2023, 2, 16, 3, 4, 5), calendar: calendar)
        #expect([c.day, c.hour, c.minute, c.second] == [2, 3, 4, 5])
    }
}

struct HeartsTests {
    @Test func missedHeartsAreTheDifference() {
        #expect(Hearts.newCount(partnerSent: 12, lastShown: 9) == 3)
        #expect(Hearts.newCount(partnerSent: 9, lastShown: 9) == 0)
        #expect(Hearts.newCount(partnerSent: 2, lastShown: 9) == 0) // partner reinstalled; never negative
    }

    @Test func threeOrMoreSplashFewerPour() {
        #expect(Hearts.effect(forNew: 0) == nil)
        #expect(Hearts.effect(forNew: 1) == .pour)
        #expect(Hearts.effect(forNew: 2) == .pour)
        #expect(Hearts.effect(forNew: 3) == .splash)
        #expect(Hearts.effect(forNew: 12) == .splash)
    }

    @Test func heartsSentThenDelivered() {
        #expect(DeliveryStatus.hearts(sent: 0, saved: 0, partnerSeen: 0) == .none)
        #expect(DeliveryStatus.hearts(sent: 5, saved: 4, partnerSeen: 4) == .sending)
        #expect(DeliveryStatus.hearts(sent: 5, saved: 5, partnerSeen: 4) == .sent)
        #expect(DeliveryStatus.hearts(sent: 5, saved: 5, partnerSeen: 5) == .delivered)
    }

    @Test func messageSentThenDelivered() {
        let id = UUID(), older = UUID()
        #expect(DeliveryStatus.message(id: nil, savedId: nil, partnerSeenId: nil) == .none)
        #expect(DeliveryStatus.message(id: id, savedId: older, partnerSeenId: older) == .sending)
        #expect(DeliveryStatus.message(id: id, savedId: id, partnerSeenId: older) == .sent)
        #expect(DeliveryStatus.message(id: id, savedId: id, partnerSeenId: id) == .delivered)
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
        let sixtyOneChars = "aaaaaaaaaa aaaaaaaaaa aaaaaaaaaa aaaaaaaaaa aaaaaaaaaa aaaaaa"
        #expect(sixtyOneChars.count == 61)
        #expect(MessageRules.check(sixtyOneChars) == .invalid(hint: "a little shorter ♡"))
        #expect(MessageRules.check("sooooooooooooooo cute") == .invalid(hint: "one word is too long ♡"))
        #expect(MessageRules.check("soooooooooooooo cute") == .valid("soooooooooooooo cute")) // 15 letters is fine
    }
}

/// Two people on one temporary mailbox, each with its own local storage.
private struct TwoPartners {
    let mailbox = LocalFileMailbox(directory: .temporaryDirectory.appending(path: UUID().uuidString))
    let you = LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    let partner = LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

    var yourService: PairingService { PairingService(mailbox: mailbox, store: you) }
    var partnerService: PairingService { PairingService(mailbox: mailbox, store: partner) }

    /// You invite, your partner joins with the code.
    @MainActor
    func paired(togetherSince: Date? = nil) async throws -> (you: AppState, partner: AppState) {
        you.togetherSince = togetherSince
        let code = try await yourService.createInvite(name: "Kshitij")
        _ = try await partnerService.join(code: code.lowercased(), name: "Nikki")
        _ = try #require(try await yourService.checkForJoin(code: code))
        return (try #require(AppState(store: you, mailbox: mailbox)),
                try #require(AppState(store: partner, mailbox: mailbox)))
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

    @Test func joinShowsWhoInvitedAndPairsBothSides() async throws {
        let people = TwoPartners()
        let code = try await people.yourService.createInvite(name: "Kshitij")
        #expect(try await people.yourService.checkForJoin(code: code) == nil) // still waiting

        let joined = try await people.partnerService.join(code: code, name: "Nikki")
        #expect(joined.partnerName == "Kshitij")
        #expect(joined.role == .joiner)

        let inviter = try #require(try await people.yourService.checkForJoin(code: code))
        #expect(inviter.partnerName == "Nikki")
        #expect(inviter.partnerId == people.partner.myId)
    }

    @Test func madeUpAndUsedCodesAreRejected() async throws {
        let people = TwoPartners()
        await #expect(throws: PairingError.invalidCode) {
            try await people.partnerService.join(code: "ZZZZZZ", name: "Nikki")
        }
        let code = try await people.yourService.createInvite(name: "Kshitij")
        _ = try await people.partnerService.join(code: code, name: "Nikki")
        let stranger = PairingService(mailbox: people.mailbox, store: LocalStore(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        await #expect(throws: PairingError.usedCode) {
            try await stranger.join(code: code, name: "Stranger")
        }
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

    @Test func heartsArriveAndAreDelivered() async throws {
        let (you, partner) = try await TwoPartners().paired()
        var arrived = 0
        partner.onHeartsArrived = { arrived += $0 }
        (0..<3).forEach { _ in you.sendHeart() }
        #expect(you.heartStatus == .sending) // bundled, not saved yet
        try await Task.sleep(for: Config.heartBundleDelay + .milliseconds(200))

        await partner.sync()
        #expect(arrived == 3)
        await you.sync()
        #expect(you.heartStatus == .delivered)
    }

    @Test func invalidMessageIsNotSent() async throws {
        let (you, _) = try await TwoPartners().paired()
        #expect(!you.sendMessage("   ", mode: .three))
        #expect(you.myOutbox.message == nil)
    }
}
