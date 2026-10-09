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

    private func loadKey() -> Data? { readSecret("privateKey") }

    private func storeKey(_ raw: Data) { writeSecret(raw, "privateKey") }

    /// The licence key and Dodo's last answer, in the Keychain (or `defaults` for tests).
    var licence: Licence? {
        get { readSecret("licence").flatMap { try? JSONDecoder().decode(Licence.self, from: $0) } }
        nonmutating set { writeSecret(newValue.flatMap { try? JSONEncoder().encode($0) }, "licence") }
    }

    private func readSecret(_ account: String) -> Data? {
        guard let keychainService else { return defaults.data(forKey: account) }
        return Keychain.read(service: keychainService, account: account)
    }

    /// Nil removes it.
    private func writeSecret(_ data: Data?, _ account: String) {
        guard let keychainService else { return defaults.set(data, forKey: account) }
        guard let data else { return Keychain.delete(service: keychainService, account: account) }
        do {
            try Keychain.save(data, service: keychainService, account: account)
        } catch {
            // Without a saved key, pairing or the licence couldn't survive a restart; fail loudly in development.
            assertionFailure("Couldn't save \(account) to the Keychain: \(error)")
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
    /// Hide OurNotch: when it comes back by itself (`Date.distantFuture` for "until I'm back").
    var hiddenUntil: Date? {
        get { defaults.object(forKey: "hiddenUntil") as? Date }
        nonmutating set { defaults.set(newValue, forKey: "hiddenUntil") }
    }
    var banner: Message? {
        get { decode("banner") }
        nonmutating set { encode(newValue, "banner") }
    }
    /// When the banner first scrolled on screen, so relaunching carries on its 3 passes instead of restarting them.
    var bannerStartedAt: Date? {
        get { defaults.object(forKey: "bannerStartedAt") as? Date }
        nonmutating set { defaults.set(newValue, forKey: "bannerStartedAt") }
    }

    private func decode<T: Decodable>(_ key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
    private func encode<T: Encodable>(_ value: T?, _ key: String) {
        defaults.set(value.flatMap { try? JSONEncoder().encode($0) }, forKey: key)
    }
}
