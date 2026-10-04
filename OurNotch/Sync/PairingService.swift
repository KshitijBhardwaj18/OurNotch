import Foundation

/// Posted by the inviter: who they are and their public key.
struct Invite: Codable, Equatable {
    let inviterId: String
    let inviterName: String
    let inviterKey: Data
    /// When the code was made; codes expire after `Config.Pairing.codeLifetime`.
    /// CloudKit fills this from the record's own creation date.
    var createdAt = Date.now
}

/// Posted by someone who typed the code and confirmed who invited them: a request, not yet a pairing.
/// Several can exist per code, so a wrong person can't use up the code.
struct Join: Codable, Equatable {
    let joinerId: String
    let joinerName: String
    let joinerKey: Data
}

/// Who I'm paired with, saved once pairing completes on this Mac.
struct Pairing: Codable, Equatable {
    enum Role: String, Codable { case inviter, joiner }

    let myId: String
    let partnerId: String
    let partnerName: String
    /// The invite code, which doubles as the pair id.
    let code: String
    let role: Role
    let partnerKey: Data
}

enum PairingError: LocalizedError, Equatable {
    case invalidCode, usedCode, expiredCode, declined

    var errorDescription: String? {
        switch self {
        case .invalidCode: "that code doesn't look right ♡ check it and try again"
        case .usedCode: "that code was already used ♡ ask your love for a new one"
        case .expiredCode: "this code has expired ♡ ask your love for a new one"
        case .declined: "that didn't work ♡ ask your love for a new code"
        }
    }
}

/// Pairs two partners through the mailbox with a short invite code (`spec.md > Pairing Service`).
/// Both sides say yes (`spec-m2.md > Pairing Confirmation`): the joiner confirms who invited them and asks;
/// the inviter sees the joiner's name and approves (once per code) or declines.
struct PairingService {
    let mailbox: Mailbox
    let store: LocalStore

    /// No 0/O or 1/I, so a code read aloud or typed from an email can't be misread.
    static let codeAlphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func makeCode() -> String {
        String((0..<Config.Pairing.codeLength).map { _ in codeAlphabet.randomElement()! })
    }

    /// Accepts lowercase and stray spaces or dashes from a pasted code.
    static func normalize(_ typed: String) -> String {
        typed.uppercased().filter { !$0.isWhitespace && $0 != "-" }
    }

    /// Posts an invite with my name and public key. Returns the code to share.
    func createInvite(name: String) async throws -> String {
        let invite = Invite(inviterId: store.myId, inviterName: name,
                            inviterKey: store.privateKey.publicKey.rawRepresentation)
        // A clash among 32^6 codes is very unlikely; try a few before giving up.
        for _ in 0..<3 {
            let code = Self.makeCode()
            do {
                try await mailbox.createInvite(invite, code: code)
                store.myName = name
                return code
            } catch MailboxError.alreadyExists {
                continue
            }
        }
        throw MailboxError.alreadyExists
    }

    // MARK: Joiner

    /// Finds the invite behind a typed code, so the joiner can see who invited them before asking to join.
    func lookUpInvite(code typed: String, now: Date = .now) async throws -> Invite {
        let code = Self.normalize(typed)
        guard code.count == Config.Pairing.codeLength,
              let invite = try await mailbox.fetchInvite(code: code) else { throw PairingError.invalidCode }
        guard now.timeIntervalSince(invite.createdAt) < Config.Pairing.codeLifetime else { throw PairingError.expiredCode }
        return invite
    }

    /// Asks to join after the joiner said "yes, that's my love". Nothing is paired until the inviter says yes too.
    func requestJoin(code typed: String, name: String) async throws {
        let code = Self.normalize(typed)
        _ = try await lookUpInvite(code: code)
        let join = Join(joinerId: store.myId, joinerName: name, joinerKey: store.privateKey.publicKey.rawRepresentation)
        do {
            try await mailbox.createJoin(join, code: code)
        } catch MailboxError.alreadyExists {
            // I asked before (e.g. after a restart); the same request still stands.
        }
        store.myName = name
    }

    /// Checks once for the inviter's answer. On yes, saves and returns the pairing.
    func checkAnswer(code typed: String, invite: Invite) async throws -> Pairing? {
        let code = Self.normalize(typed)
        if let approved = try await mailbox.fetchApproval(code: code) {
            guard approved == store.myId else { throw PairingError.usedCode }
            let pairing = Pairing(myId: store.myId, partnerId: invite.inviterId, partnerName: invite.inviterName,
                                  code: code, role: .joiner, partnerKey: invite.inviterKey)
            store.pairing = pairing
            return pairing
        }
        if try await mailbox.fetchDecline(joinerId: store.myId, code: code) { throw PairingError.declined }
        return nil
    }

    /// Keeps checking until the inviter answers, or the task is cancelled.
    func waitForAnswer(code: String, invite: Invite) async throws -> Pairing {
        while true {
            if let pairing = try await checkAnswer(code: code, invite: invite) { return pairing }
            try await Task.sleep(for: Config.Pairing.joinCheckInterval)
        }
    }

    // MARK: Inviter

    /// Requests to join that haven't been declined yet, oldest first.
    func pendingJoins(code: String, declined: Set<String>) async throws -> [Join] {
        try await mailbox.fetchJoins(code: code).filter { !declined.contains($0.joinerId) }
    }

    /// Keeps checking until someone asks to join, or the task is cancelled (the waiting screen closed).
    func waitForJoinRequest(code: String, declined: Set<String>) async throws -> Join {
        while true {
            if let join = try await pendingJoins(code: code, declined: declined).first { return join }
            try await Task.sleep(for: Config.Pairing.joinCheckInterval)
        }
    }

    /// "Yes, this is my love": the code's one approval goes to this joiner, and both Macs pair.
    func approve(_ join: Join, code: String) async throws -> Pairing {
        do {
            try await mailbox.createApproval(joinerId: join.joinerId, code: code)
        } catch MailboxError.alreadyExists {
            guard try await mailbox.fetchApproval(code: code) == join.joinerId else { throw PairingError.usedCode }
        }
        let pairing = Pairing(myId: store.myId, partnerId: join.joinerId, partnerName: join.joinerName,
                              code: code, role: .inviter, partnerKey: join.joinerKey)
        store.pairing = pairing
        return pairing
    }

    /// "No": the joiner is told gently; the code stays open for the right person.
    func decline(_ join: Join, code: String) async throws {
        do {
            try await mailbox.createDecline(joinerId: join.joinerId, code: code)
        } catch MailboxError.alreadyExists {}
    }
}
