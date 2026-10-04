import Foundation

/// Hide OurNotch for a while (`spec-m2.md > Hide and Pause`), kept pure for tests.
enum Hide: CaseIterable {
    case hour, untilTomorrow, untilBack

    var label: String {
        switch self {
        case .hour: "1 Hour"
        case .untilTomorrow: "Until Tomorrow"
        case .untilBack: "Until I'm Back"
        }
    }

    /// When OurNotch comes back by itself. "Until tomorrow" means the next 6 am; "until I'm back" never.
    func until(now: Date = .now, calendar: Calendar = .current) -> Date {
        switch self {
        case .hour: return now.addingTimeInterval(3600)
        case .untilBack: return .distantFuture
        case .untilTomorrow:
            let sixToday = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
            return sixToday > now ? sixToday : calendar.date(byAdding: .day, value: 1, to: sixToday)!
        }
    }

    static func isHidden(until: Date?, now: Date = .now) -> Bool {
        until.map { $0 > now } ?? false
    }
}
