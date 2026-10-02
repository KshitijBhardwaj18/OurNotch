import CryptoKit
import Foundation

/// Everything this Mac remembers for one identity, so it all survives restarts.
/// The Partner Simulator passes its own `UserDefaults` suite to stay a separate person.
struct LocalStore {
    let defaults: UserDefaults

    /// A random id per install, not the iCloud account, so two identities can share one Mac for testing.
    var myId: String {
        if let id = defaults.string(forKey: "myId") { return id }
        let id = UUID().uuidString
        defaults.set(id, forKey: "myId")
        return id
    }

    /// Created on first use.
    // ponytail: kept in UserDefaults while builds are ad-hoc signed ("Sign to Run Locally"), because the
    // Keychain re-prompts for the login password after every rebuild. Move to the Keychain in slice 5,
    // when the app is signed with the company team.
    var privateKey: Crypto.PrivateKey {
        if let raw = defaults.data(forKey: "privateKey"), let key = try? Crypto.PrivateKey(rawRepresentation: raw) {
            return key
        }
        let key = Crypto.PrivateKey()
        defaults.set(key.rawRepresentation, forKey: "privateKey")
        return key
    }

    var myName: String? {
        get { defaults.string(forKey: "myName") }
        nonmutating set { defaults.set(newValue, forKey: "myName") }
    }
    var pairing: Pairing? {
        get { decode("pairing") }
        nonmutating set { encode(newValue, "pairing") }
    }
    var togetherSince: Date? {
        get { defaults.object(forKey: "togetherSince") as? Date }
        nonmutating set { defaults.set(newValue, forKey: "togetherSince") }
    }
    var myOutbox: Outbox? {
        get { decode("myOutbox") }
        nonmutating set { encode(newValue, "myOutbox") }
    }
    var savedOutbox: Outbox? {
        get { decode("savedOutbox") }
        nonmutating set { encode(newValue, "savedOutbox") }
    }
    var banner: Message? {
        get { decode("banner") }
        nonmutating set { encode(newValue, "banner") }
    }

    private func decode<T: Decodable>(_ key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
    private func encode<T: Encodable>(_ value: T?, _ key: String) {
        defaults.set(value.flatMap { try? JSONEncoder().encode($0) }, forKey: key)
    }
}
