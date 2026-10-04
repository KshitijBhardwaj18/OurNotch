import Foundation

enum MailboxError: Error {
    /// A record that may only be created once already exists (an invite code in use, or a code already joined).
    case alreadyExists
}

/// Where the two partners' records live: invites, joins, and one outbox per partner.
/// The app only talks to this interface, so the local file version can be swapped for CloudKit (slice 5)
/// without other changes.
protocol Mailbox: Sendable {
    /// How often to re-read the partner's row when nothing pings us.
    var pollInterval: Duration { get }

    func saveOutbox(_ payload: Data, owner: String) async throws
    func fetchOutbox(owner: String) async throws -> Data?

    /// The owner's latest photo, already encrypted. One per owner; a new one replaces the old.
    func savePhoto(_ sealed: Data, owner: String) async throws
    func fetchPhoto(owner: String) async throws -> Data?

    /// Throws `MailboxError.alreadyExists` if the code is taken.
    func createInvite(_ invite: Invite, code: String) async throws
    func fetchInvite(code: String) async throws -> Invite?
    /// One request per joiner per code. Throws `MailboxError.alreadyExists` if this joiner already asked.
    func createJoin(_ join: Join, code: String) async throws
    func fetchJoins(code: String) async throws -> [Join]
    /// The inviter's yes, once per code. Throws `MailboxError.alreadyExists` if the code was already approved.
    func createApproval(joinerId: String, code: String) async throws
    func fetchApproval(code: String) async throws -> String?
    /// The inviter's no to one joiner.
    func createDecline(joinerId: String, code: String) async throws
    func fetchDecline(joinerId: String, code: String) async throws -> Bool

    /// The owner's latest diagnostics log (plain text, no message content). One per owner.
    func saveDiagnostics(_ text: String, owner: String) async throws
    func fetchDiagnostics(owner: String) async throws -> String?
    /// Measurements for analysis; each is kept, never overwritten.
    func saveMetrics(_ metrics: [Metric]) async throws
    func fetchMetrics(owner: String) async throws -> [Metric]

    /// Whether the mailbox can be used right now (CloudKit needs an iCloud sign-in).
    func accountAvailable() async -> Bool
    /// Asks to be pinged when the partner's row changes, so checks happen within seconds.
    func watchPartner(_ partnerId: String) async
}

extension Mailbox {
    func accountAvailable() async -> Bool { true }
    func watchPartner(_ partnerId: String) async {}
}

/// Stand-in mailbox: one file per record in Application Support, shared by every identity on this Mac.
/// One file per record mirrors CloudKit's one-writer-per-row model.
struct LocalFileMailbox: Mailbox {
    let directory: URL
    let pollInterval: Duration = .seconds(1)

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "OurNotch/Mailbox")) {
        self.directory = directory
    }

    func saveOutbox(_ payload: Data, owner: String) async throws {
        try write(payload, name: "outbox-\(owner)")
    }

    func fetchOutbox(owner: String) async throws -> Data? {
        try read(name: "outbox-\(owner)")
    }

    func savePhoto(_ sealed: Data, owner: String) async throws {
        try write(sealed, name: "photo-\(owner)", ext: "bin")
    }

    func fetchPhoto(owner: String) async throws -> Data? {
        try read(name: "photo-\(owner)", ext: "bin")
    }

    func saveDiagnostics(_ text: String, owner: String) async throws {
        try write(Data(text.utf8), name: "diag-\(owner)", ext: "log")
    }

    func fetchDiagnostics(owner: String) async throws -> String? {
        try read(name: "diag-\(owner)", ext: "log").map { String(decoding: $0, as: UTF8.self) }
    }

    func saveMetrics(_ metrics: [Metric]) async throws {
        for (owner, new) in Dictionary(grouping: metrics, by: \.owner) {
            let all = try await fetchMetrics(owner: owner) + new
            try write(try JSONEncoder().encode(all), name: "metrics-\(owner)")
        }
    }

    func fetchMetrics(owner: String) async throws -> [Metric] {
        try decode(name: "metrics-\(owner)") ?? []
    }

    func createInvite(_ invite: Invite, code: String) async throws {
        try create(invite, name: "invite-\(code)")
    }

    func fetchInvite(code: String) async throws -> Invite? {
        try decode(name: "invite-\(code)")
    }

    func createJoin(_ join: Join, code: String) async throws {
        try create(join, name: "join-\(code)-\(join.joinerId)")
    }

    func fetchJoins(code: String) async throws -> [Join] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        let mine = files.filter { $0.lastPathComponent.hasPrefix("join-\(code)-") }
        let created = { (url: URL) in (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast }
        return try mine.sorted { created($0) < created($1) }
            .compactMap { try decode(name: $0.deletingPathExtension().lastPathComponent) }
    }

    func createApproval(joinerId: String, code: String) async throws {
        try create(joinerId, name: "approval-\(code)")
    }

    func fetchApproval(code: String) async throws -> String? {
        try decode(name: "approval-\(code)")
    }

    func createDecline(joinerId: String, code: String) async throws {
        try create(true, name: "decline-\(code)-\(joinerId)")
    }

    func fetchDecline(joinerId: String, code: String) async throws -> Bool {
        try read(name: "decline-\(code)-\(joinerId)") != nil
    }

    // MARK: Files

    private func create<T: Encodable>(_ record: T, name: String) throws {
        guard try read(name: name) == nil else { throw MailboxError.alreadyExists }
        try write(try JSONEncoder().encode(record), name: name)
    }

    private func decode<T: Decodable>(name: String) throws -> T? {
        try read(name: name).map { try JSONDecoder().decode(T.self, from: $0) }
    }

    private func write(_ data: Data, name: String, ext: String = "json") throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appending(path: "\(name).\(ext)"), options: .atomic)
    }

    private func read(name: String, ext: String = "json") throws -> Data? {
        let url = directory.appending(path: "\(name).\(ext)")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }
}
