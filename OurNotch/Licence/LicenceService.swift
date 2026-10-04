import Foundation

/// This Mac's licence and Dodo's last answer about it. Kept in the Keychain.
struct Licence: Codable, Equatable {
    enum Status: String, Codable {
        case active
        /// Dodo said "not valid": revoked by us, or refunded. Both Macs of the pair lock.
        case revoked
        /// The buyer chose Remove from This Mac, freeing the slot for another Mac.
        case removed
    }

    var key: String
    /// Dodo's id for this Mac's activation. Only the buyer's Mac has one; the partner's Mac only validates.
    var activationId: String?
    var status = Status.active
    var lastGoodCheck: Date?

    /// The notch is hidden behind the licence window until a good key is pasted.
    var isLocked: Bool { status != .active }
    /// The buyer's Mac holds the key's one slot; it shares the key with the partner and has licence settings.
    var isBuyer: Bool { activationId != nil }

    /// Whether a key arriving from the partner should replace this Mac's licence. A Mac that activated
    /// its own key, or removed it, keeps its own; otherwise the buyer's newest key wins.
    static func adopts(_ key: String, over current: Licence?) -> Bool {
        guard let current else { return true }
        return !current.isBuyer && current.status != .removed && current.key != key
    }
}

enum LicenceError: LocalizedError, Equatable {
    case notFound, inUse, revoked, unreachable

    var errorDescription: String? {
        switch self {
        case .notFound: String(localized: "That key doesn't look right. Check your receipt email and try again.")
        case .inUse: String(localized: "This key is already in use on another Mac. Choose Remove from This Mac there, or write to us at \(Config.Licence.supportEmail).")
        case .revoked: String(localized: "This key is no longer active. Get a new one, or write to us at \(Config.Licence.supportEmail) if you think this is a mistake.")
        case .unreachable: String(localized: "Can't reach the shop right now. Check your internet and try again.")
        }
    }
}

/// Talks to Dodo's public licence endpoints, which need no API key (`spec-m2.md > Licence Service`).
/// Dodo is the licence book; this Mac only remembers its last answer, so it works offline forever.
struct LicenceService {
    let store: LocalStore
    var baseURL = Config.Licence.baseURL

    /// Switches the key on for this Mac (uses the key's one slot) and remembers it.
    @discardableResult
    func activate(key: String, macName: String = Host.current().localizedName ?? "Mac") async throws -> Licence {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let (status, body) = await post("licenses/activate", ["license_key": key, "name": macName])
        let licence = Licence(key: key, activationId: try Self.activationId(status: status, body: body), lastGoodCheck: Date.now)
        store.licence = licence
        return licence
    }

    /// Asks Dodo whether the stored key is still good. Uses no slot.
    /// Only an explicit "not valid" revokes; no answer keeps the last one.
    func check() async {
        guard let licence = store.licence, licence.status != .removed else { return }
        let (status, body) = await post("licenses/validate", ["license_key": licence.key])
        store.licence = Self.applying(Self.validity(status: status, body: body), to: licence)
    }

    /// Frees this Mac's slot so the key can move to a new Mac. Throws if Dodo can't be reached,
    /// so the slot is never left taken by a Mac that thinks it let go.
    func removeFromThisMac() async throws {
        guard var licence = store.licence, let id = licence.activationId else { return }
        let (status, _) = await post("licenses/deactivate", ["license_key": licence.key, "license_key_instance_id": id])
        // 404: the slot was already freed (e.g. from the admin page).
        guard let status, (200..<300).contains(status) || status == 404 else { throw LicenceError.unreachable }
        licence.activationId = nil
        licence.status = .removed
        store.licence = licence
    }

    /// Dodo's answer applied to the stored licence. No answer, or a removed licence, changes nothing.
    static func applying(_ valid: Bool?, to licence: Licence, now: Date = .now) -> Licence {
        guard let valid, licence.status != .removed else { return licence }
        var licence = licence
        licence.status = valid ? .active : .revoked
        if valid { licence.lastGoodCheck = now }
        return licence
    }

    // MARK: Dodo's answers

    /// 201 `{id}` → the activation id; 404 / 422 / 403 → why not; anything else → unreachable.
    static func activationId(status: Int?, body: Data) throws -> String {
        switch status {
        case .some(200..<300):
            guard let id = (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["id"] as? String else {
                throw LicenceError.unreachable
            }
            return id
        case 404: throw LicenceError.notFound
        case 422: throw LicenceError.inUse
        case 403: throw LicenceError.revoked
        default: throw LicenceError.unreachable
        }
    }

    /// `{valid}` on 200; 403 / 404 mean the key is gone; nil means no answer (offline, timeout, 5xx).
    static func validity(status: Int?, body: Data) -> Bool? {
        switch status {
        case 200: (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["valid"] as? Bool
        case 403, 404: false
        default: nil
        }
    }

    /// Nil status means the request never got an answer.
    private func post(_ path: String, _ json: [String: String]) async -> (Int?, Data) {
        var request = URLRequest(url: baseURL.appending(path: path), timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        guard let (data, response) = try? await URLSession.shared.data(for: request) else { return (nil, Data()) }
        return ((response as? HTTPURLResponse)?.statusCode, data)
    }
}
