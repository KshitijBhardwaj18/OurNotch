import Foundation

/// Where the two partners' outbox rows live. The app only talks to this interface,
/// so the local file version can be swapped for CloudKit (slice 5) without other changes.
protocol Mailbox: Sendable {
    /// How often to re-read the partner's row when nothing pings us.
    var pollInterval: Duration { get }
    func saveOutbox(_ payload: Data, owner: String) async throws
    func fetchOutbox(owner: String) async throws -> Data?
}

/// Stand-in mailbox: one file per outbox in Application Support, shared by every identity on this Mac.
/// One file per owner mirrors CloudKit's one-writer-per-row model.
struct LocalFileMailbox: Mailbox {
    let directory: URL
    let pollInterval: Duration = .seconds(1)

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "OurNotch/Mailbox")) {
        self.directory = directory
    }

    func saveOutbox(_ payload: Data, owner: String) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try payload.write(to: fileURL(owner), options: .atomic)
    }

    func fetchOutbox(owner: String) async throws -> Data? {
        let url = fileURL(owner)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    private func fileURL(_ owner: String) -> URL {
        directory.appending(path: "outbox-\(owner).json")
    }
}
