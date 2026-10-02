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

@MainActor
struct PartnersTests {
    /// Two partners on one temporary mailbox, each with its own local storage.
    private func pair() -> (you: AppState, partner: AppState) {
        let mailbox = LocalFileMailbox(directory: .temporaryDirectory.appending(path: UUID().uuidString))
        func defaults() -> UserDefaults { UserDefaults(suiteName: UUID().uuidString)! }
        return (AppState(pairing: .devYou, mailbox: mailbox, defaults: defaults()),
                AppState(pairing: .devPartner, mailbox: mailbox, defaults: defaults()))
    }

    @Test func messageArrivesAndIsDelivered() async throws {
        let (you, partner) = pair()
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
        let (you, partner) = pair()
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

    @Test func invalidMessageIsNotSent() {
        let (you, _) = pair()
        #expect(!you.sendMessage("   ", mode: .three))
        #expect(you.myOutbox.message == nil)
    }
}
