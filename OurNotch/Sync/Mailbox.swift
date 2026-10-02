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

    /// Throws `MailboxError.alreadyExists` if the code is taken.
    func createInvite(_ invite: Invite, code: String) async throws
    func fetchInvite(code: String) async throws -> Invite?
    /// Throws `MailboxError.alreadyExists` if someone already joined with this code.
    func createJoin(_ join: Join, code: String) async throws
    func fetchJoin(code: String) async throws -> Join?
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

    func createInvite(_ invite: Invite, code: String) async throws {
        try create(invite, name: "invite-\(code)")
    }

    func fetchInvite(code: String) async throws -> Invite? {
        try decode(name: "invite-\(code)")
    }

    func createJoin(_ join: Join, code: String) async throws {
        try create(join, name: "join-\(code)")
    }

    func fetchJoin(code: String) async throws -> Join? {
        try decode(name: "join-\(code)")
    }

    // MARK: Files

    private func create<T: Encodable>(_ record: T, name: String) throws {
        guard try read(name: name) == nil else { throw MailboxError.alreadyExists }
        try write(try JSONEncoder().encode(record), name: name)
    }

    private func decode<T: Decodable>(name: String) throws -> T? {
        try read(name: name).map { try JSONDecoder().decode(T.self, from: $0) }
    }

    private func write(_ data: Data, name: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appending(path: "\(name).json"), options: .atomic)
    }

    private func read(name: String) throws -> Data? {
        let url = directory.appending(path: "\(name).json")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }
}
