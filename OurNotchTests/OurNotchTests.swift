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
