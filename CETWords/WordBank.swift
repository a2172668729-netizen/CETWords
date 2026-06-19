import Foundation

enum WordBank {
    static let collectionLayoutVersion = 1

    private static let sourceEntries: [WordEntry] = {
        let cet4 = loadBundledEntries(level: .cet4)
        let cet6 = loadBundledEntries(level: .cet6)
        let bundled = cet4 + cet6
        return bundled.isEmpty ? fallbackEntries : bundled
    }()

    static let entries = mergeEntries(sourceEntries)
    static let collections = buildCollections(from: entries)

    static let items: [WordItem] = entries.map { entry in
        WordItem(
            id: entry.id,
            word: entry.word,
            meaning: entry.primaryMeaning,
            sources: entry.sourceDisplayName
        )
    }

    static func collection(id: Int) -> VocabularyCollection {
        collections.first { $0.id == id } ?? collections[0]
    }

    static func unifiedProgressID(forLegacyEntryID entryID: String) -> String? {
        sourceEntries.first { $0.id == entryID }?.progressID
    }

    private static func loadBundledEntries(level: WordLevel) -> [WordEntry] {
        guard let url = Bundle.main.url(forResource: level.resourceName, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parseEntries(text: text, source: level)
    }

    static func parseEntries(text: String, source: WordLevel) -> [WordEntry] {
        var drafts: [String: (firstIndex: Int, word: String, meanings: [String])] = [:]

        for (index, line) in text.split(whereSeparator: \.isNewline).enumerated() {
            let parts = line.split(separator: "\t", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            let word = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let meaning = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !word.isEmpty, !meaning.isEmpty else { continue }

            let normalizedWord = normalizeWord(word)
            if var draft = drafts[normalizedWord] {
                if !draft.meanings.contains(meaning) {
                    draft.meanings.append(meaning)
                }
                drafts[normalizedWord] = draft
            } else {
                drafts[normalizedWord] = (firstIndex: index + 1, word: word, meanings: [meaning])
            }
        }

        return drafts.values
            .sorted { $0.firstIndex < $1.firstIndex }
            .map { draft in
                WordEntry(
                    id: "\(source.resourceName)-\(String(format: "%05d", draft.firstIndex))",
                    word: draft.word,
                    sources: [source],
                    meanings: draft.meanings,
                    phoneticUS: nil,
                    phoneticUK: nil,
                    phrases: [],
                    examples: []
                )
            }
    }

    static func mergeEntries(_ entries: [WordEntry]) -> [WordEntry] {
        var order: [String] = []
        var merged: [String: WordEntry] = [:]

        for entry in entries {
            let normalized = normalizeWord(entry.word)
            guard !normalized.isEmpty else { continue }

            if let existing = merged[normalized] {
                merged[normalized] = WordEntry(
                    id: "word::\(normalized)",
                    word: existing.word,
                    sources: existing.sources.union(entry.sources),
                    meanings: appendUnique(entry.meanings, to: existing.meanings),
                    phoneticUS: existing.phoneticUS ?? entry.phoneticUS,
                    phoneticUK: existing.phoneticUK ?? entry.phoneticUK,
                    phrases: appendUnique(entry.phrases, to: existing.phrases),
                    examples: appendUnique(entry.examples, to: existing.examples)
                )
            } else {
                order.append(normalized)
                merged[normalized] = WordEntry(
                    id: "word::\(normalized)",
                    word: entry.word,
                    sources: entry.sources,
                    meanings: appendUnique(entry.meanings, to: []),
                    phoneticUS: entry.phoneticUS,
                    phoneticUK: entry.phoneticUK,
                    phrases: appendUnique(entry.phrases, to: []),
                    examples: appendUnique(entry.examples, to: [])
                )
            }
        }

        return order.compactMap { merged[$0] }
    }

    static func buildCollections(from entries: [WordEntry], count: Int = 20) -> [VocabularyCollection] {
        guard count > 0 else { return [] }

        let shuffled = entries.sorted { left, right in
            let leftWord = normalizeWord(left.word)
            let rightWord = normalizeWord(right.word)
            let leftHash = fixedHash(leftWord)
            let rightHash = fixedHash(rightWord)
            if leftHash == rightHash {
                return leftWord < rightWord
            }
            return leftHash < rightHash
        }

        var groups = Array(repeating: [WordEntry](), count: count)
        for (index, entry) in shuffled.enumerated() {
            groups[index % count].append(entry)
        }

        return groups.enumerated().map { index, words in
            VocabularyCollection(id: index + 1, words: words)
        }
    }

    private static func normalizeWord(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func fixedHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }

    private static func appendUnique<T: Hashable>(_ newItems: [T], to existingItems: [T]) -> [T] {
        var result = existingItems
        var seen = Set(existingItems)
        for item in newItems where seen.insert(item).inserted {
            result.append(item)
        }
        return result
    }

    private static let fallbackEntries: [WordEntry] = [
        WordEntry(id: "cet4-fallback-001", word: "access", level: .cet4, meanings: ["v. 获取 n. 接近，入口"], phoneticUS: nil, phoneticUK: nil, phrases: [], examples: []),
        WordEntry(id: "cet4-fallback-002", word: "project", level: .cet4, meanings: ["n. 工程；课题、作业"], phoneticUS: nil, phoneticUK: nil, phrases: [], examples: []),
        WordEntry(id: "cet4-fallback-003", word: "intention", level: .cet4, meanings: ["n. 打算，意图"], phoneticUS: nil, phoneticUK: nil, phrases: [], examples: []),
        WordEntry(id: "cet6-fallback-001", word: "consistent", level: .cet6, meanings: ["adj. 一致的"], phoneticUS: nil, phoneticUK: nil, phrases: [], examples: []),
        WordEntry(id: "cet6-fallback-002", word: "battery", level: .cet6, meanings: ["n. 电池"], phoneticUS: nil, phoneticUK: nil, phrases: [], examples: []),
        WordEntry(id: "cet6-fallback-003", word: "competent", level: .cet6, meanings: ["adj. 能胜任的，有能力的"], phoneticUS: nil, phoneticUK: nil, phrases: [], examples: [])
    ]
}
