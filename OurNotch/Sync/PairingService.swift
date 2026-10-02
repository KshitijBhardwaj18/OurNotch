import Foundation

/// Posted by the inviter: who they are and their public key.
struct Invite: Codable, Equatable {
    let inviterId: String
    let inviterName: String
    let inviterKey: Data
}

/// Posted by the partner who typed the code. One per code; a second one means the code is used.
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
    case invalidCode, usedCode

    var errorDescription: String? {
        switch self {
        case .invalidCode: "that code doesn't look right ♡ check it and try again"
        case .usedCode: "that code was already used ♡ ask your love for a new one"
        }
    }
}

/// Pairs two partners through the mailbox with a short invite code (`spec.md > Pairing Service`).
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

    /// Checks once whether my love has joined. Saves and returns the pairing when they have.
    func checkForJoin(code: String) async throws -> Pairing? {
        guard let join = try await mailbox.fetchJoin(code: code) else { return nil }
        let pairing = Pairing(myId: store.myId, partnerId: join.joinerId, partnerName: join.joinerName,
                              code: code, role: .inviter, partnerKey: join.joinerKey)
        store.pairing = pairing
        return pairing
    }

    /// Keeps checking until my love joins, or the task is cancelled (the waiting screen closed).
    func waitForJoin(code: String) async throws -> Pairing {
        while true {
            if let pairing = try await checkForJoin(code: code) { return pairing }
            try await Task.sleep(for: Config.Pairing.joinCheckInterval)
        }
    }

    /// Joins with a typed code. Saves and returns the pairing, whose `partnerName` is who invited me.
    func join(code typed: String, name: String) async throws -> Pairing {
        let code = Self.normalize(typed)
        guard code.count == Config.Pairing.codeLength,
              let invite = try await mailbox.fetchInvite(code: code) else { throw PairingError.invalidCode }

        let join = Join(joinerId: store.myId, joinerName: name,
                        joinerKey: store.privateKey.publicKey.rawRepresentation)
        do {
            try await mailbox.createJoin(join, code: code)
        } catch MailboxError.alreadyExists {
            throw PairingError.usedCode
        }

        let pairing = Pairing(myId: store.myId, partnerId: invite.inviterId, partnerName: invite.inviterName,
                              code: code, role: .joiner, partnerKey: invite.inviterKey)
        store.myName = name
        store.pairing = pairing
        return pairing
    }
}
