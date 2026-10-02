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

    @Test func sentThenDelivered() {
        #expect(DeliveryStatus.of(sent: 0, saved: 0, partnerSeen: 0) == .none)
        #expect(DeliveryStatus.of(sent: 5, saved: 4, partnerSeen: 4) == .sending)
        #expect(DeliveryStatus.of(sent: 5, saved: 5, partnerSeen: 4) == .sent)
        #expect(DeliveryStatus.of(sent: 5, saved: 5, partnerSeen: 5) == .delivered)
    }
}
