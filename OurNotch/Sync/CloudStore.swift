import CloudKit
import os

/// The real mailbox: CloudKit's public database, hosted by Apple with no server of our own.
/// Each record has one writer (its creator); payloads arrive already encrypted.
///
/// | Record      | Name              | Fields                                 |
/// |-------------|-------------------|----------------------------------------|
/// | `Invite`    | `invite-<CODE>`   | inviterId, inviterName, inviterKey     |
/// | `Join`      | `join-<CODE>`     | joinerId, joinerName, joinerKey        |
/// | `Outbox`    | `outbox-<userId>` | ownerId (queryable), payload           |
/// | `Photo`     | `photo-<userId>`  | ownerId, image (asset)                 |
struct CloudStore: Mailbox {
    let pollInterval: Duration
    private let container: CKContainer
    private var database: CKDatabase { container.publicCloudDatabase }
    private let log = Logger(subsystem: "OurNotch", category: "cloud")

    init(containerId: String = Config.Cloud.containerId, pollInterval: Duration = Config.Cloud.pollInterval) {
        container = CKContainer(identifier: containerId)
        self.pollInterval = pollInterval
    }

    func accountAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    // MARK: Outbox

    func saveOutbox(_ payload: Data, owner: String) async throws {
        let record = CKRecord(recordType: "Outbox", recordID: .init(recordName: "outbox-\(owner)"))
        record["ownerId"] = owner
        record["payload"] = payload
        try await upsert(record)
    }

    func fetchOutbox(owner: String) async throws -> Data? {
        try await fetch("outbox-\(owner)")?["payload"] as? Data
    }

    // MARK: Photo

    func savePhoto(_ sealed: Data, owner: String) async throws {
        // Assets upload from a file.
        let file = URL.temporaryDirectory.appending(path: "photo-\(UUID().uuidString).bin")
        try sealed.write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }

        let record = CKRecord(recordType: "Photo", recordID: .init(recordName: "photo-\(owner)"))
        record["ownerId"] = owner
        record["image"] = CKAsset(fileURL: file)
        try await upsert(record)
    }

    func fetchPhoto(owner: String) async throws -> Data? {
        guard let asset = try await fetch("photo-\(owner)")?["image"] as? CKAsset, let url = asset.fileURL else { return nil }
        return try Data(contentsOf: url)
    }

    // MARK: Pairing

    func createInvite(_ invite: Invite, code: String) async throws {
        let record = CKRecord(recordType: "Invite", recordID: .init(recordName: "invite-\(code)"))
        record["inviterId"] = invite.inviterId
        record["inviterName"] = invite.inviterName
        record["inviterKey"] = invite.inviterKey
        try await create(record)
    }

    func fetchInvite(code: String) async throws -> Invite? {
        guard let record = try await fetch("invite-\(code)"),
              let id = record["inviterId"] as? String, let name = record["inviterName"] as? String,
              let key = record["inviterKey"] as? Data else { return nil }
        return Invite(inviterId: id, inviterName: name, inviterKey: key)
    }

    func createJoin(_ join: Join, code: String) async throws {
        let record = CKRecord(recordType: "Join", recordID: .init(recordName: "join-\(code)"))
        record["joinerId"] = join.joinerId
        record["joinerName"] = join.joinerName
        record["joinerKey"] = join.joinerKey
        try await create(record)
    }

    func fetchJoin(code: String) async throws -> Join? {
        guard let record = try await fetch("join-\(code)"),
              let id = record["joinerId"] as? String, let name = record["joinerName"] as? String,
              let key = record["joinerKey"] as? Data else { return nil }
        return Join(joinerId: id, joinerName: name, joinerKey: key)
    }

    // MARK: Pings

    /// A silent push whenever the partner's outbox is created or changed. Needs `ownerId` marked
    /// Queryable in CloudKit Console; until then this logs an error and the regular checks still deliver.
    func watchPartner(_ partnerId: String) async {
        let subscription = CKQuerySubscription(recordType: "Outbox",
                                               predicate: NSPredicate(format: "ownerId == %@", partnerId),
                                               subscriptionID: "outbox-\(partnerId)",
                                               options: [.firesOnRecordCreation, .firesOnRecordUpdate])
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true // silent: wakes the app, shows nothing
        subscription.notificationInfo = info
        do {
            _ = try await database.save(subscription)
            log.notice("Watching partner outbox for pings")
        } catch {
            log.error("Couldn't subscribe to partner pings: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Helpers

    /// Creates or overwrites the record. Only its creator may write it, which is always this app's user.
    private func upsert(_ record: CKRecord) async throws {
        try await retrying {
            let (saved, _) = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
            _ = try saved[record.recordID]?.get()
        }
    }

    /// Creates a record that must not exist yet (an invite code, or a join for a code).
    private func create(_ record: CKRecord) async throws {
        do {
            _ = try await retrying { try await database.save(record) }
        } catch let error as CKError where error.code == .serverRecordChanged {
            throw MailboxError.alreadyExists
        }
    }

    private func fetch(_ name: String) async throws -> CKRecord? {
        do {
            return try await retrying { try await database.record(for: .init(recordName: name)) }
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// Waits as long as CloudKit asks when it's busy or rate-limiting, then tries once more.
    private func retrying<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch let error as CKError where error.retryAfterSeconds != nil {
            log.notice("CloudKit asked to wait \(error.retryAfterSeconds ?? 0) s")
            try await Task.sleep(for: .seconds(error.retryAfterSeconds ?? 1))
            return try await work()
        }
    }
}
