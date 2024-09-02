//
//  Mnemonic.swift
//
//  Created by Sun on 2022/1/19.
//

import Foundation

import WWCryptoKit

public enum Mnemonic {
    // MARK: Nested Types

    public enum WordCount: Int, CaseIterable {
        case twelve = 12
        case fifteen = 15
        case eighteen = 18
        case twentyOne = 21
        case twentyFour = 24

        // MARK: Computed Properties

        var bitLength: Int {
            rawValue / 3 * 32
        }

        var checksumLength: Int {
            rawValue / 3
        }
    }

    public enum Language: CaseIterable {
        case english
        case japanese
        case korean
        case spanish
        case simplifiedChinese
        case traditionalChinese
        case french
        case italian
        case czech
        case portuguese
    }

    public enum ValidationError: Error {
        case invalidWords(count: Int)
        case invalidWord(index: Int)
        case invalidChecksum
    }

    enum MnemonicError: Error {
        case randomBytesError
    }

    // MARK: Static Functions

    public static func generate(wordCount: WordCount = .twelve, language: Language = .english) throws -> [String] {
        let byteCount = wordCount.bitLength / 8
        var bytes = Data(count: byteCount)

        let status = bytes.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!.assumingMemoryBound(to: UInt8.self))
        }

        guard status == errSecSuccess else {
            throw MnemonicError.randomBytesError
        }
        return generate(entropy: bytes, language: language)
    }

    public static func seed(
        mnemonic m: [String],
        prefix: String = "mnemonic",
        passphrase: String = "",
        iterations: Int = 2048
    )
        -> Data? {
        let mnemonic = m.joined(separator: " ").decomposedStringWithCompatibilityMapping
        let salt = (prefix + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8)!
        return Crypto.deriveKey(password: mnemonic, salt: salt, iterations: iterations, keyLength: 64)
    }

    public static func seedNonStandard(mnemonic m: [String], passphrase: String = "") -> Data? {
        let mnemonic = m.joined(separator: " ")
        let salt = ("mnemonic" + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8)!
        return Crypto.deriveKeyNonStandard(password: mnemonic, salt: salt, iterations: 2048, keyLength: 64)
    }

    public static func validate(words: [String]) throws {
        guard let wordCount = WordCount(rawValue: words.count) else {
            throw ValidationError.invalidWords(count: words.count)
        }

        let seedBits = try seedBitsForLanguage(words: words)
        let checksumLength = wordCount.checksumLength
        let dataBitsLength = seedBits.count - checksumLength

        let dataBits = String(seedBits.prefix(dataBitsLength))
        let checksumBits = String(seedBits.suffix(checksumLength))

        guard let dataBytes = dataBits.bitStringToBytes() else {
            throw ValidationError.invalidChecksum
        }

        let hash = Crypto.sha256(dataBytes)
        let hashBits = hash.toBitArray().joined(separator: "").prefix(checksumLength)

        guard hashBits == checksumBits else {
            throw ValidationError.invalidChecksum
        }
    }

    public static func isValid(words: [String]) -> Bool {
        do {
            try validate(words: words)
            return true
        } catch {
            return false
        }
    }

    public static func wordList(for language: Language) -> [String.SubSequence] {
        switch language {
        case .english:
            WordList.english
        case .japanese:
            WordList.japanese
        case .korean:
            WordList.korean
        case .spanish:
            WordList.spanish
        case .simplifiedChinese:
            WordList.simplifiedChinese
        case .traditionalChinese:
            WordList.traditionalChinese
        case .french:
            WordList.french
        case .italian:
            WordList.italian
        case .czech:
            WordList.czech
        case .portuguese:
            WordList.portuguese
        }
    }

    public static func language(words: [String]) -> Mnemonic.Language? {
        for language in Language.allCases {
            do {
                _ = try seedBits(words: words, list: wordList(for: language).map(String.init))
                return language
            } catch { }
        }

        return nil
    }

    private static func generate(entropy: Data, language: Language = .english) -> [String] {
        let list = wordList(for: language)
        var bin = String(entropy.flatMap { ("00000000" + String($0, radix: 2)).suffix(8) })

        let hash = Crypto.sha256(entropy)
        let bits = entropy.count * 8
        let cs = bits / 32

        let hashbits = String(hash.flatMap { ("00000000" + String($0, radix: 2)).suffix(8) })
        let checksum = String(hashbits.prefix(cs))
        bin += checksum

        var mnemonic = [String]()
        for i in 0 ..< (bin.count / 11) {
            let wi = Int(
                bin[bin.index(bin.startIndex, offsetBy: i * 11) ..< bin.index(bin.startIndex, offsetBy: (i + 1) * 11)],
                radix: 2
            )!
            mnemonic.append(String(list[wi]))
        }
        return mnemonic
    }

    private static func seedBits(words: [String], list: [String]) throws -> String {
        var seedBits = ""
        // swiftformat:disable unusedArguments
        try words.enumerated().forEach { index, word in
            guard let index = list.firstIndex(of: word) else {
                throw ValidationError.invalidWord(index: index)
            }

            let binaryString = String(index, radix: 2).pad(toSize: 11)

            seedBits.append(contentsOf: binaryString)
        }
        // swiftformat:enable unusedArguments
        return seedBits
    }

    private static func seedBitsForLanguage(words: [String]) throws -> String {
        var wrongWordIndex = 0

        for language in (Language.allCases.map { wordList(for: $0).map(String.init) }) {
            do {
                return try seedBits(words: words, list: language)
            } catch {
                if case let ValidationError.invalidWord(index) = error {
                    wrongWordIndex = wrongWordIndex < index ? index : wrongWordIndex
                }
            }
        }

        throw ValidationError.invalidWord(index: wrongWordIndex)
    }
}
