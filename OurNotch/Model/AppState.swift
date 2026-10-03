import Foundation
import Observation

/// The single source of truth the notch reads from.
@Observable
final class AppState {
    var togetherSince: Date = Config.placeholderTogetherSince
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
