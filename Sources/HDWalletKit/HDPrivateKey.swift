//
//  HDPrivateKey.swift
//  HDWalletKit
//
//  Created by Sun on 2022/1/19.
//

import Foundation

import Crypto
import secp256k1
import SWCryptoKit
import SWExtensions

// MARK: - HDPrivateKey

public class HDPrivateKey: HDKey {
    // MARK: Overridden Properties

    override public var raw: Data {
        _raw.suffix(32) // first byte is 0x00
    }

    // MARK: Computed Properties

    var extendedVersion: HDExtendedKeyVersion {
        HDExtendedKeyVersion(rawValue: version) ??
            .xprv // created key successfully validated before creation, so fallback not using
    }

    // MARK: Lifecycle

    override public init(
        raw: Data,
        chainCode: Data,
        version: UInt32,
        depth: UInt8,
        fingerprint: UInt32,
        childIndex: UInt32
    ) {
        super.init(
            raw: raw,
            chainCode: chainCode,
            version: version,
            depth: depth,
            fingerprint: fingerprint,
            childIndex: childIndex
        )
    }

    public init(
        privateKey: Data,
        chainCode: Data,
        version: UInt32,
        depth: UInt8 = 0,
        fingerprint: UInt32 = 0,
        childIndex: UInt32 = 0
    ) {
        let zeros = privateKey.count < 33 ? [UInt8](repeating: 0, count: 33 - privateKey.count) : []

        super.init(
            raw: Data(zeros) + privateKey,
            chainCode: chainCode,
            version: version,
            depth: depth,
            fingerprint: fingerprint,
            childIndex: childIndex
        )
    }

    public convenience init(seed: Data, xPrivKey: UInt32, salt: Data = DerivationCurve.secp256k1.bip32SeedSalt) {
        let hmac = Crypto.hmacSha512(seed, key: salt)
        let privateKey = hmac[0 ..< 32]
        let chainCode = hmac[32 ..< 64]
        self.init(privateKey: privateKey, chainCode: chainCode, version: xPrivKey)
    }

    override init(extendedKey: Data) throws {
        try super.init(extendedKey: extendedKey)
    }
}

extension HDPrivateKey {
    public func derived(at index: UInt32, hardened: Bool, curve: DerivationCurve = .secp256k1) throws -> HDPrivateKey {
        let edge: UInt32 = 0x80000000
        guard (edge & index) == 0 else {
            throw DerivationError.invalidChildIndex
        }

        if !(curve.supportNonHardened || hardened) {
            throw DerivationError.cantDeriveNonHardened
        }

        var data = Data()
        let publicKey = curve.publicKey(privateKey: raw, compressed: true)
        if hardened {
            data += Data([0])
            data += raw
        } else {
            data += publicKey
        }

        let derivingIndex = CFSwapInt32BigToHost(hardened ? (edge | index) : index)
        data += derivingIndex.data

        let digest = Crypto.hmacSha512(data, key: chainCode)

        let derivedPrivateKey = try curve.applyParameters(parentPrivateKey: raw, childKey: digest[0 ..< 32])
        let derivedChainCode = digest[32 ..< 64]

        let hash = Crypto.ripeMd160Sha256(publicKey)
        let fingerprint: UInt32 = hash[0 ..< 4].sw.to(type: UInt32.self)

        return HDPrivateKey(
            privateKey: derivedPrivateKey,
            chainCode: derivedChainCode,
            version: version,
            depth: depth + 1,
            fingerprint: fingerprint.bigEndian,
            childIndex: derivingIndex.bigEndian
        )
    }

    public func publicKey(compressed: Bool = true, curve: DerivationCurve = .secp256k1) -> HDPublicKey {
        HDPublicKey(
            raw: Crypto.publicKey(privateKey: raw, curve: curve, compressed: compressed),
            chainCode: chainCode,
            version: extendedVersion.pubKey.rawValue,
            depth: depth,
            fingerprint: fingerprint,
            childIndex: childIndex
        )
    }

    public func derivedNonHardenedPublicKeys(at indices: Range<UInt32>) throws -> [HDPublicKey] {
        guard let firstIndex = indices.first, let lastIndex = indices.last else {
            return []
        }

        if (0x80000000 & firstIndex) != 0, (0x80000000 & lastIndex) != 0 {
            throw DerivationError.invalidChildIndex
        }

        let hdPubKey = publicKey(curve: .secp256k1)
        var keys = [HDPublicKey]()

        try indices.forEach { int32 in
            try keys.append(hdPubKey.derived(at: int32))
        }

        return keys
    }
}

// MARK: - DerivationError

public enum DerivationError: Error {
    case derivationFailed
    case cantDeriveNonHardened
    case invalidChildIndex
    case invalidPath
    case invalidHmacToPoint
    case invalidRawToPoint
    case invalidCombinePoints
}
