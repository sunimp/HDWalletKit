//
//  HDExtendedKey.swift
//
//  Created by Sun on 2022/10/17.
//

import Foundation

import WWCryptoKit
import WWExtensions

// MARK: - HDExtendedKey

public enum HDExtendedKey {
    case `private`(key: HDPrivateKey)
    case `public`(key: HDPublicKey)

    // MARK: Static Properties

    static let length = 82

    // MARK: Computed Properties

    var hdKey: HDKey {
        switch self {
        case let .private(key): key
        case let .public(key): key
        }
    }

    // MARK: Lifecycle

    public init(extendedKey: String) throws {
        let data = Base58.decode(extendedKey)
        try self.init(data: data)
    }

    public init(data: Data, curve _: DerivationCurve = .secp256k1) throws {
        guard data.count == HDExtendedKey.length else {
            throw ParsingError.wrongKeyLength
        }

        let version = try HDExtendedKey.version(extendedKey: data)

        let derivedType = DerivedType(depth: data[4])
        guard derivedType != .bip32 else {
            throw ParsingError.wrongDerivedType
        }

        if version.isPublic {
            self = try .public(key: HDPublicKey(extendedKey: data))
        } else {
            self = try .private(key: HDPrivateKey(extendedKey: data))
        }
    }
}

extension HDExtendedKey {
    public var derivedType: DerivedType {
        DerivedType(depth: hdKey.depth)
    }

    public var purposes: [Purpose] {
        let version = HDExtendedKeyVersion(rawValue: hdKey.version) ?? .xprv
        return version.purposes
    }

    public var coinTypes: [HDExtendedKeyVersion.ExtendedKeyCoinType] {
        let version = HDExtendedKeyVersion(rawValue: hdKey.version) ?? .xprv
        return version.coinTypes
    }

    public var serialized: Data {
        hdKey.data()
    }

    public static func deserialize(data: Data) throws -> HDExtendedKey {
        try HDExtendedKey(data: data)
    }
}

extension HDExtendedKey {
    public static func version(extendedKey: Data) throws -> HDExtendedKeyVersion {
        let version = extendedKey.prefix(4).ww.to(type: UInt32.self).bigEndian
        guard let keyType = HDExtendedKeyVersion(rawValue: version) else {
            throw ParsingError.wrongVersion
        }

        return keyType
    }

    public static func isValid(_ extendedKey: Data, isPublic: Bool? = nil) throws {
        guard extendedKey.count == HDExtendedKey.length else {
            throw ParsingError.wrongKeyLength
        }

        let version = try version(extendedKey: extendedKey)
        if let isPublic, version.isPublic != isPublic {
            throw ParsingError.wrongVersion
        }

        let checksum: Data = extendedKey[78 ..< 82]
        guard Data(Crypto.doubleSha256(extendedKey.prefix(78)).prefix(4)) == checksum else {
            throw ParsingError.invalidChecksum
        }
    }
}

// MARK: Equatable, Hashable

extension HDExtendedKey: Equatable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(serialized)
    }

    public static func == (lhs: HDExtendedKey, rhs: HDExtendedKey) -> Bool {
        lhs.serialized == rhs.serialized
    }
}

extension HDExtendedKey {
    /// master key depth == 0, account depth = "m/purpose'/coin_type'/account'" = 3, all others is custom
    public enum DerivedType {
        case bip32
        case master
        case account

        // MARK: Lifecycle

        init(depth: UInt8) {
            switch depth {
            case 0: self = .master
            case 3: self = .account
            default: self = .bip32
            }
        }
    }

    public enum ParsingError: Error {
        case wrongVersion
        case wrongType
        case wrongKeyLength
        case wrongDerivedType
        case invalidChecksum
    }
}
