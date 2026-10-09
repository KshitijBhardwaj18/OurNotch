import CloudKit


/// The real mailbox: CloudKit's public database, hosted by Apple with no server of our own.
/// Each record has one writer (its creator); payloads arrive already encrypted.
///
/// | Record      | Name              | Fields                                 |
/// |-------------|-------------------|----------------------------------------|
/// | `Invite`    | `invite-<CODE>`   | inviterId, inviterName, inviterKey (`creationDate` sets the 24 h expiry) |
/// | `Join`      | `join-<CODE>-<slot>` | joinerId, joinerName, joinerKey (slots 0…4: read by name, no index needed) |
/// | `Approval`  | `approval-<CODE>` | joinerId (created once: the inviter's yes) |
/// | `Decline`   | `decline-<CODE>-<joinerId>` | code (the inviter's no)      |
/// | `Outbox`    | `outbox-<userId>` | ownerId (queryable), payload           |
/// | `Photo`     | `photo-<userId>`  | ownerId, image (asset)                 |
/// | `Diagnostics` | `diag-<userId>` | ownerId, text (event log, no content)  |
/// | `Metric`    | random            | ownerId (queryable), measuredAt, kind, name, ms, frames, dropped, detail, device |
struct CloudStore: Mailbox {
    let pollInterval: Duration
    private let container: CKContainer
    private var database: CKDatabase { container.publicCloudDatabase }

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

    // MARK: Diagnostics

    func saveDiagnostics(_ text: String, owner: String) async throws {
        let record = CKRecord(recordType: "Diagnostics", recordID: .init(recordName: "diag-\(owner)"))
        record["ownerId"] = owner
        record["text"] = text
        try await upsert(record)
    }

    func fetchDiagnostics(owner: String) async throws -> String? {
        try await fetch("diag-\(owner)")?["text"] as? String
    }

    /// Many records in one request (at most 400).
    func saveMetrics(_ metrics: [Metric]) async throws {
        let records = metrics.map { metric in
            let record = CKRecord(recordType: "Metric")
            record["ownerId"] = metric.owner
            record["measuredAt"] = metric.at
            record["kind"] = metric.kind.rawValue
            record["name"] = metric.name
            record["ms"] = metric.ms
            record["frames"] = metric.frames
            record["dropped"] = metric.dropped
            record["detail"] = metric.detail
            record["device"] = metric.device
            return record
        }
        try await retrying {
            let (saved, _) = try await database.modifyRecords(saving: records, deleting: [], atomically: false)
            for result in saved.values { _ = try result.get() }
        }
    }

    /// Needs `Metric.ownerId` marked Queryable in CloudKit Console.
    func fetchMetrics(owner: String) async throws -> [Metric] {
        let query = CKQuery(recordType: "Metric", predicate: NSPredicate(format: "ownerId == %@", owner))
        var (results, cursor) = try await database.records(matching: query)
        var metrics = results.compactMap { try? $0.1.get() }.compactMap(Self.metric)
        while let next = cursor {
            (results, cursor) = try await database.records(continuingMatchFrom: next)
            metrics += results.compactMap { try? $0.1.get() }.compactMap(Self.metric)
        }
        return metrics.sorted { $0.at < $1.at }
    }

    private static func metric(_ record: CKRecord) -> Metric? {
        guard let kind = (record["kind"] as? String).flatMap(Metric.Kind.init), let name = record["name"] as? String else { return nil }
        return Metric(at: record["measuredAt"] as? Date ?? .distantPast, owner: record["ownerId"] as? String ?? "",
                      kind: kind, name: name, ms: record["ms"] as? Double ?? 0,
                      frames: record["frames"] as? Int, dropped: record["dropped"] as? Int,
                      detail: record["detail"] as? String, device: record["device"] as? String ?? "")
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
        // The server's clock, not the inviter's, decides when the code expires.
        return Invite(inviterId: id, inviterName: name, inviterKey: key, createdAt: record.creationDate ?? .now)
    }

    /// Join requests sit in a few numbered slots per code, so the inviter reads them by name: no query, so no
    /// Queryable index to set up in CloudKit Console. A joiner takes the first free slot.
    private static func joinIDs(_ code: String) -> [CKRecord.ID] {
        (0..<Config.Pairing.joinSlots).map { CKRecord.ID(recordName: "join-\(code)-\($0)") }
    }

    func createJoin(_ join: Join, code: String) async throws {
        for id in Self.joinIDs(code) {
            let record = CKRecord(recordType: "Join", recordID: id)
            record["joinerId"] = join.joinerId
            record["joinerName"] = join.joinerName
            record["joinerKey"] = join.joinerKey
            do {
                return try await create(record)
            } catch MailboxError.alreadyExists {
                // Taken. If it's my own earlier request, it still stands; otherwise try the next slot.
                if try await fetch(id.recordName)?["joinerId"] as? String == join.joinerId { throw MailboxError.alreadyExists }
            }
        }
        throw PairingError.usedCode // every slot taken by others
    }

    func fetchJoins(code: String) async throws -> [Join] {
        let results = try await retrying { try await database.records(for: Self.joinIDs(code)) }
        return Self.joinIDs(code).compactMap { id in
            guard let record = try? results[id]?.get(),
                  let joinerId = record["joinerId"] as? String, let name = record["joinerName"] as? String,
                  let key = record["joinerKey"] as? Data else { return nil }
            return Join(joinerId: joinerId, joinerName: name, joinerKey: key)
        }
    }

    func createApproval(joinerId: String, code: String) async throws {
        let record = CKRecord(recordType: "Approval", recordID: .init(recordName: "approval-\(code)"))
        record["joinerId"] = joinerId
        try await create(record)
    }

    func fetchApproval(code: String) async throws -> String? {
        try await fetch("approval-\(code)")?["joinerId"] as? String
    }

    func createDecline(joinerId: String, code: String) async throws {
        let record = CKRecord(recordType: "Decline", recordID: .init(recordName: "decline-\(code)-\(joinerId)"))
        record["code"] = code
        try await create(record)
    }

    func fetchDecline(joinerId: String, code: String) async throws -> Bool {
        try await fetch("decline-\(code)-\(joinerId)") != nil
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
            let all = (try? await database.allSubscriptions().map(\.subscriptionID)) ?? []
            await Diagnostics.shared.record("ping subscription saved: \(subscription.subscriptionID); this iCloud user has \(all.count): \(all.joined(separator: ", "))")
        } catch {
            await Diagnostics.shared.record("ping subscription FAILED: \(error.diagnosticDescription)")
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
        let config = CKOperation.Configuration()
        config.timeoutIntervalForRequest = Config.Cloud.requestTimeout
        do {
            return try await retrying {
                try await database.configuredWith(configuration: config) { try await $0.record(for: .init(recordName: name)) }
            }
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// Waits as long as CloudKit asks when it's busy or rate-limiting, then tries once more.
    private func retrying<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch let error as CKError where error.retryAfterSeconds != nil {
            await Diagnostics.shared.record("CloudKit busy (\(error.code.rawValue)); waiting \(error.retryAfterSeconds ?? 0) s")
            try await Task.sleep(for: .seconds(error.retryAfterSeconds ?? 1))
            return try await work()
        }
    }
}
