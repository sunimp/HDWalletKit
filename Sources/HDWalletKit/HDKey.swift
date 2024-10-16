//
//  HDKey.swift
//  HDWalletKit
//
//  Created by Sun on 2022/10/20.
//

import Foundation

import SWCryptoKit

// MARK: - HDKey

public class HDKey {
    // MARK: Properties

    public let version: UInt32
    public let depth: UInt8
    public let fingerprint: UInt32
    public let childIndex: UInt32

    public let chainCode: Data

    let _raw: Data

    // MARK: Computed Properties

    open var raw: Data { _raw }

    // MARK: Lifecycle

    public init(raw: Data, chainCode: Data, version: UInt32, depth: UInt8, fingerprint: UInt32, childIndex: UInt32) {
        self.version = version
        _raw = raw
        self.chainCode = chainCode
        self.depth = depth
        self.fingerprint = fingerprint
        self.childIndex = childIndex
    }

    public init(extendedKey: Data) throws {
        try HDExtendedKey.isValid(extendedKey)
        version = extendedKey.prefix(4).sw.to(type: UInt32.self).bigEndian

        depth = extendedKey[4]
        fingerprint = extendedKey[5 ..< 9].sw.to(type: UInt32.self).bigEndian
        childIndex = extendedKey[9 ..< 12].sw.to(type: UInt32.self).bigEndian
        chainCode = extendedKey[13 ..< 45]
        _raw = extendedKey[45 ..< 78]
    }
}

extension HDKey {
    func data(version: UInt32? = nil) -> Data {
        var data = Data()
        data += (version ?? self.version).bigEndian.data
        data += Data([depth])
        data += fingerprint.bigEndian.data
        data += childIndex.bigEndian.data
        data += chainCode
        data += _raw
        let checksum = Crypto.doubleSha256(data).prefix(4)
        return data + checksum
    }
}

extension HDKey {
    public func extended(customVersion: HDExtendedKeyVersion? = nil) -> String {
        let version = customVersion?.rawValue ?? version
        return Base58.encode(data(version: version))
    }

    public var description: String {
        "\(raw.sw.hex) ::: \(chainCode.sw.hex) ::: depth: \(depth) - fingerprint: \(fingerprint) - childIndex: \(childIndex)"
    }
}
