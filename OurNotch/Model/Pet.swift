import Foundation

/// The pet you share: adopted once by either of you, cared for from both Macs. Each Mac only records what it
/// did (in its own outbox); both work out the same pet from the two records, so nothing can clash.
enum PetKind: String, Codable, CaseIterable {
    case cat, dog

    var label: String {
        switch self {
        case .cat: String(localized: "Cat")
        case .dog: String(localized: "Dog")
        }
    }
}

struct PetAdoption: Codable, Equatable {
    let kind: PetKind
    let name: String
    let adoptedAt: Date
}

enum PetCoat: String, Codable, CaseIterable {
    case peach, cream, grey, choco
}

enum PetAccessory: String, Codable, CaseIterable {
    case none, bow, flower, scarf, cap
}

/// How it looks. Either of you can change it; the newer change shows on both Macs.
struct PetLook: Codable, Equatable {
    var coat: PetCoat = .peach
    var accessory: PetAccessory = .none
    var setAt: Date = .distantPast
}

enum PetCare: String, Codable {
    case feed, pet, play, trick
}

struct PetAction: Codable, Equatable {
    let care: PetCare
    let at: Date
}

/// How it's doing right now, worst first.
enum PetFeeling: Equatable {
    case sick, recovering, sleeping, hungry, lonely, content, happy
}

/// Grows up with the days since you adopted it.
enum PetStage: Equatable {
    case baby, young, grown, wise
}

struct Pet: Equatable {
    let adoption: PetAdoption
    let look: PetLook
    /// Both of your care, oldest first; `mine` says whose it was.
    let care: [(action: PetAction, mine: Bool)]

    static func == (a: Pet, b: Pet) -> Bool {
        a.adoption == b.adoption && a.look == b.look && a.care.map(\.action) == b.care.map(\.action)
    }

    /// The pet from both outboxes; the earlier adoption wins if you both adopted at once.
    static func from(mine: Outbox, theirs: Outbox) -> Pet? {
        let adoptions = [mine.petAdoption, theirs.petAdoption].compactMap { $0 }
        guard let adoption = adoptions.min(by: { $0.adoptedAt < $1.adoptedAt }) else { return nil }
        let looks = [mine.petLook, theirs.petLook].compactMap { $0 }
        let ours: [(action: PetAction, mine: Bool)] = (mine.petCare ?? []).map { ($0, true) }
        let partners: [(action: PetAction, mine: Bool)] = (theirs.petCare ?? []).map { ($0, false) }
        let care = (ours + partners)
            .filter { $0.action.at >= adoption.adoptedAt }
            .sorted { $0.action.at < $1.action.at }
        return Pet(adoption: adoption, look: looks.max { $0.setAt < $1.setAt } ?? PetLook(), care: care)
    }

    var lastFed: Date { care.last { $0.action.care == .feed }?.action.at ?? adoption.adoptedAt }
    /// Petting, playing and tricks all count as love.
    var lastLove: Date { care.last { $0.action.care != .feed }?.action.at ?? adoption.adoptedAt }

    /// 1 just fed, 0 after `Config.Pet.hungerTime`.
    func fullness(now: Date = .now) -> Double { fade(since: lastFed, over: Config.Pet.hungerTime, now: now) }
    func love(now: Date = .now) -> Double { fade(since: lastLove, over: Config.Pet.lonelyTime, now: now) }

    func stage(now: Date = .now, calendar: Calendar = .current) -> PetStage {
        let days = Together.days(since: adoption.adoptedAt, now: now, calendar: calendar)
        let (young, grown, wise) = Config.Pet.stageDays
        return days < young ? .baby : days < grown ? .young : days < wise ? .grown : .wise
    }

    func ageInDays(now: Date = .now, calendar: Calendar = .current) -> Int {
        Together.days(since: adoption.adoptedAt, now: now, calendar: calendar)
    }

    func feeling(now: Date = .now, calendar: Calendar = .current) -> PetFeeling {
        if now.timeIntervalSince(lastFed) > Config.Pet.sickAfter { return .sick }
        if wasSick, now.timeIntervalSince(lastFed) < Config.Pet.recoveringFor { return .recovering }
        let hour = calendar.component(.hour, from: now)
        if hour >= Config.Pet.bedtime || hour < Config.Pet.wakeUp { return .sleeping }
        let fullness = fullness(now: now), love = love(now: now)
        if fullness < 0.3 { return .hungry }
        if love < 0.3 { return .lonely }
        return fullness > 0.6 && love > 0.6 ? .happy : .content
    }

    /// Whether the last meal ended a stretch long enough to have made it sick.
    private var wasSick: Bool {
        let feeds = [adoption.adoptedAt] + care.filter { $0.action.care == .feed }.map(\.action.at)
        guard feeds.count >= 2 else { return false }
        return feeds[feeds.count - 1].timeIntervalSince(feeds[feeds.count - 2]) > Config.Pet.sickAfter
    }

    private func fade(since date: Date, over span: TimeInterval, now: Date) -> Double {
        min(1, max(0, 1 - now.timeIntervalSince(date) / span))
    }
}
