//
//  HDExtendedKeyVersion.swift
//  HDWalletKit
//
//  Created by Sun on 2022/10/17.
//

import Foundation

import SWExtensions

// MARK: - HDExtendedKeyVersion

/// https://github.com/satoshilabs/slips/blob/master/slip-0132.md
public enum HDExtendedKeyVersion: UInt32, CaseIterable {
    case xprv = 0x0488ADE4
    case xpub = 0x0488B21E
    case yprv = 0x049D7878
    case ypub = 0x049D7CB2
    case zprv = 0x04B2430C
    case zpub = 0x04B24746
    case Ltpv = 0x019D9CFE
    case Ltub = 0x019DA462
    case Mtpv = 0x01B26792
    case Mtub = 0x01B26EF6

    // MARK: Computed Properties

    public var string: String {
        switch self {
        case .xprv: "xprv"
        case .xpub: "xpub"
        case .yprv: "yprv"
        case .ypub: "ypub"
        case .zprv: "zprv"
        case .zpub: "zpub"
        case .Ltpv: "Ltpv"
        case .Ltub: "Ltub"
        case .Mtpv: "Mtpv"
        case .Mtub: "Mtub"
        }
    }

    public var purposes: [Purpose] {
        switch self {
        case .xprv,
             .xpub: [.bip44, .bip86]
        case .Ltpv,
             .Ltub: [.bip44]
        case .yprv,
             .ypub,
             .Mtpv,
             .Mtub: [.bip49]
        case .zprv,
             .zpub: [.bip84]
        }
    }

    public var coinTypes: [ExtendedKeyCoinType] {
        switch self {
        case .xprv,
             .xpub,
             .zprv,
             .zpub: [.bitcoin, .litecoin]
        case .yprv,
             .ypub: [.bitcoin]
        case .Ltpv,
             .Ltub,
             .Mtpv,
             .Mtub: [.litecoin]
        }
    }

    public var pubKey: Self {
        switch self {
        case .xprv: .xpub
        case .yprv: .ypub
        case .zprv: .zpub
        case .Ltpv: .Ltub
        case .Mtpv: .Mtub
        default: self
        }
    }

    public var isPublic: Bool {
        switch self {
        case .xpub,
             .ypub,
             .zpub,
             .Ltub,
             .Mtub: true
        default: false
        }
    }

    // MARK: Lifecycle

    public init(purpose: Purpose, coinType: ExtendedKeyCoinType, isPrivate: Bool = true) throws {
        switch purpose {
        case .bip44:
            switch coinType {
            case .bitcoin: self = isPrivate ? .xprv : .xpub
            case .litecoin: self = isPrivate ? .Ltpv : .Ltub
            }

        case .bip49:
            switch coinType {
            case .bitcoin: self = isPrivate ? .yprv : .ypub
            case .litecoin: self = isPrivate ? .Mtpv : .Mtub
            }

        case .bip84:
            self = isPrivate ? .zprv : .zpub

        case .bip86:
            self = isPrivate ? .xprv : .xpub
        }
    }

    public init?(string: String) {
        guard let result = Self.allCases.first(where: { $0.string == string }) else {
            return nil
        }

        self = result
    }
}

// MARK: HDExtendedKeyVersion.ExtendedKeyCoinType

extension HDExtendedKeyVersion {
    public enum ExtendedKeyCoinType {
        case bitcoin
        case litecoin
    }
}
