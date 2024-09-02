//
//  HDWallet.swift
//
//  Created by Sun on 2022/1/19.
//

import Foundation

import WWCryptoKit

public class HDWallet {
    // MARK: Nested Types

    public enum Chain: Int {
        case external
        case `internal`
    }

    // MARK: Properties

    private let keychain: HDKeychain

    private let purpose: UInt32
    private let coinType: UInt32

    // MARK: Computed Properties

    public var masterKey: HDPrivateKey {
        keychain.privateKey
    }

    // MARK: Lifecycle

    public init(
        seed: Data,
        coinType: UInt32,
        xPrivKey: UInt32,
        purpose: Purpose = .bip44,
        curve: DerivationCurve = .secp256k1
    ) {
        keychain = HDKeychain(seed: seed, xPrivKey: xPrivKey, curve: curve)
        self.purpose = purpose.rawValue
        self.coinType = coinType
    }

    public init(
        masterKey: HDPrivateKey,
        coinType: UInt32,
        purpose: Purpose = .bip44,
        curve: DerivationCurve = .secp256k1
    ) {
        keychain = HDKeychain(privateKey: masterKey, curve: curve)
        self.purpose = purpose.rawValue
        self.coinType = coinType
    }

    // MARK: Functions

    public func privateKey(account: Int, index: Int, chain: Chain) throws -> HDPrivateKey {
        try privateKey(path: "m/\(purpose)'/\(coinType)'/\(account)'/\(chain.rawValue)/\(index)")
    }

    public func privateKey(account: Int) throws -> HDPrivateKey {
        try privateKey(path: "m/\(purpose)'/\(coinType)'/\(account)'")
    }

    public func privateKey(path: String) throws -> HDPrivateKey {
        try keychain.derivedKey(path: path)
    }

    public func publicKey(account: Int, index: Int, chain: Chain) throws -> HDPublicKey {
        try privateKey(account: account, index: index, chain: chain).publicKey(curve: .secp256k1)
    }

    public func publicKeys(account: Int, indices: Range<UInt32>, chain: Chain) throws -> [HDPublicKey] {
        try keychain.derivedNonHardenedPublicKeys(
            path: "m/\(purpose)'/\(coinType)'/\(account)'/\(chain.rawValue)",
            indices: indices
        )
    }
}
