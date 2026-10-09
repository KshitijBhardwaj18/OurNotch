import Foundation
import Security

/// Small wrapper over the data-protection Keychain for this app's secrets (private key, licence).
enum Keychain {
    static func read(service: String, account: String) -> Data? {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData] = true
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func save(_ data: Data, service: String, account: String) throws {
        let query = baseQuery(service: service, account: account)
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData] = data
        item[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock // readable at login, before the notch starts
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    static func delete(service: String, account: String) {
        SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
    }

    static func delete(service: String) {
        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service,
                       kSecUseDataProtectionKeychain: true] as CFDictionary)
    }

    private static func baseQuery(service: String, account: String) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword,
         kSecAttrService: service,
         kSecAttrAccount: account,
         kSecUseDataProtectionKeychain: true]
    }
}
