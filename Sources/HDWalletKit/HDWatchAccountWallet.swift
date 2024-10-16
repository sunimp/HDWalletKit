//
//  HDWatchAccountWallet.swift
//  HDWalletKit
//
//  Created by Sun on 2022/10/18.
//

import Foundation

public class HDWatchAccountWallet {
    // MARK: Nested Types

    public enum Chain: Int {
        case external
        case `internal`
    }

    // MARK: Properties

    private let publicKey: HDPublicKey

    // MARK: Lifecycle

    public init(publicKey: HDPublicKey) {
        self.publicKey = publicKey
    }

    // MARK: Functions

    public func publicKey(index: Int, chain: Chain) throws -> HDPublicKey {
        try publicKey.derived(at: UInt32(chain.rawValue)).derived(at: UInt32(index))
    }

    public func publicKeys(indices: Range<UInt32>, chain: Chain) throws -> [HDPublicKey] {
        guard let firstIndex = indices.first, let lastIndex = indices.last else {
            return []
        }

        if (0x80000000 & firstIndex) != 0, (0x80000000 & lastIndex) != 0 {
            throw DerivationError.invalidChildIndex
        }

        let derivedHDKey = try publicKey.derived(at: UInt32(chain.rawValue))

        var keys = [HDPublicKey]()
        for i in indices {
            try keys.append(derivedHDKey.derived(at: i))
        }

        return keys
    }
}
