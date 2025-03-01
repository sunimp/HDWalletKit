//
//  HDKeychain.swift
//  HDWalletKit
//
//  Created by Sun on 2022/1/19.
//

import Foundation

import SWCryptoKit
import SWExtensions

public final class HDKeychain {
    // MARK: Properties

    public let curve: DerivationCurve

    let privateKey: HDPrivateKey

    // MARK: Lifecycle

    public init(privateKey: HDPrivateKey, curve: DerivationCurve = .secp256k1) {
        self.privateKey = privateKey
        self.curve = curve
    }

    public convenience init(seed: Data, xPrivKey: UInt32, curve: DerivationCurve) {
        self.init(privateKey: HDPrivateKey(seed: seed, xPrivKey: xPrivKey, salt: curve.bip32SeedSalt), curve: curve)
    }

    // MARK: Functions

    /// Parses the BIP32 path and derives the chain of keychains accordingly.
    /// Path syntax: (m?/)?([0-9]+'?(/[0-9]+'?)*)?
    /// The following paths are valid:
    ///
    /// "" (root key)
    /// "m" (root key)
    /// "/" (root key)
    /// "m/0'" (hardened child #0 of the root key)
    /// "/0'" (hardened child #0 of the root key)
    /// "0'" (hardened child #0 of the root key)
    /// "m/44'/1'/2'" (BIP44 testnet account #2)
    /// "/44'/1'/2'" (BIP44 testnet account #2)
    /// "44'/1'/2'" (BIP44 testnet account #2)
    ///
    /// The following paths are invalid:
    ///
    /// "m / 0 / 1" (contains spaces)
    /// "m/b/c" (alphabetical characters instead of numerical indexes)
    /// "m/1.2^3" (contains illegal characters)
    public func derivedKey(path: String) throws -> HDPrivateKey {
        var key = privateKey

        var path = path
        if path == "m" || path == "/" || path == "" {
            return key
        }
        if path.contains("m/") {
            path = String(path.dropFirst(2))
        }
        for chunk in path.split(separator: "/") {
            var hardened = false
            var indexText = chunk
            if chunk.contains("'") {
                hardened = true
                indexText = indexText.dropLast()
            }
            guard let index = UInt32(indexText) else {
                throw DerivationError.invalidPath
            }
            key = try key.derived(at: index, hardened: hardened, curve: curve)
        }
        return key
    }

    func derivedNonHardenedPublicKeys(path: String, indices: Range<UInt32>) throws -> [HDPublicKey] {
        guard !indices.isEmpty else {
            return []
        }

        let key = try derivedKey(path: path)

        return try key.derivedNonHardenedPublicKeys(at: indices)
    }
}
