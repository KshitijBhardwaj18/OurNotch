import CryptoKit
import Foundation

/// The lock on each outbox. Each partner makes a key pair and they swap only the public halves
/// through the invite. Each Mac then works out the same secret key, which never travels anywhere.
enum Crypto {
    typealias PrivateKey = Curve25519.KeyAgreement.PrivateKey

    /// X25519 key agreement, then HKDF-SHA256 (salt = pair id) into a 256-bit key.
    static func sharedKey(myPrivateKey: PrivateKey, partnerPublicKey: Data, pairId: String) throws -> SymmetricKey {
        let partnerKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: partnerPublicKey)
        let secret = try myPrivateKey.sharedSecretFromKeyAgreement(with: partnerKey)
        return secret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                              salt: Data(pairId.utf8),
                                              sharedInfo: Data("OurNotch v1".utf8),
                                              outputByteCount: 32)
    }

    /// Encrypts and authenticates, so a changed byte fails to open instead of decoding garbage.
    static func seal(_ plaintext: Data, with key: SymmetricKey) throws -> Data {
        try ChaChaPoly.seal(plaintext, using: key).combined
    }

    static func open(_ sealed: Data, with key: SymmetricKey) throws -> Data {
        try ChaChaPoly.open(ChaChaPoly.SealedBox(combined: sealed), using: key)
    }
}
