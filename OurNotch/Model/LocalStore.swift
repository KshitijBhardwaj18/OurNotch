import CryptoKit
import Foundation

/// Everything this Mac remembers for one identity, so it all survives restarts.
/// The Partner Simulator passes its own `UserDefaults` suite and Keychain service to stay a separate person.
struct LocalStore {
    let defaults: UserDefaults
    /// Where the private key lives. Nil keeps it in `defaults`, which tests use so they don't touch the Keychain.
    var keychainService: String? = nil

    /// A random id per install, not the iCloud account, so two identities can share one Mac for testing.
    var myId: String {
        if let id = defaults.string(forKey: "myId") { return id }
        let id = UUID().uuidString
        defaults.set(id, forKey: "myId")
        return id
    }

    /// Created on first use and kept in the Keychain (or `defaults` for tests).
    var privateKey: Crypto.PrivateKey {
        if let raw = loadKey(), let key = try? Crypto.PrivateKey(rawRepresentation: raw) { return key }
        let key = Crypto.PrivateKey()
        storeKey(key.rawRepresentation)
        return key
    }

    private func loadKey() -> Data? {
        guard let keychainService else { return defaults.data(forKey: "privateKey") }
        return Keychain.read(service: keychainService, account: "privateKey")
    }

    private func storeKey(_ raw: Data) {
        guard let keychainService else { return defaults.set(raw, forKey: "privateKey") }
        do {
            try Keychain.save(raw, service: keychainService, account: "privateKey")
        } catch {
            // Without a saved key, pairing couldn't survive a restart; fail loudly in development.
            assertionFailure("Couldn't save the private key to the Keychain: \(error)")
        }
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
