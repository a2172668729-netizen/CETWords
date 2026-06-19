import Foundation

struct StudyProgressFile: Codable {
    var version: Int
    var wordProgress: [String: WordProgress]
    var todayCompletedIDs: [String]
    var todayDateKey: String
    var activeDays: [String]

    init(
        version: Int = 3,
        wordProgress: [String: WordProgress] = [:],
        todayCompletedIDs: [String] = [],
        todayDateKey: String = Date.dayKey(),
        activeDays: [String] = []
    ) {
        self.version = version
        self.wordProgress = wordProgress
        self.todayCompletedIDs = todayCompletedIDs
        self.todayDateKey = todayDateKey
        self.activeDays = activeDays
    }

    enum CodingKeys: String, CodingKey {
        case version
        case wordProgress
        case todayCompletedIDs
        case todayDateKey
        case activeDays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        wordProgress = try container.decodeIfPresent([String: WordProgress].self, forKey: .wordProgress) ?? [:]
        todayCompletedIDs = try container.decodeIfPresent([String].self, forKey: .todayCompletedIDs) ?? []
        todayDateKey = try container.decodeIfPresent(String.self, forKey: .todayDateKey) ?? Date.dayKey()
        activeDays = try container.decodeIfPresent([String].self, forKey: .activeDays) ?? []
    }
}

@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var progressFile: StudyProgressFile
    @Published private(set) var lastErrorMessage: String?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        self.progressFile = StudyProgressFile()
        load()
        rollTodayIfNeeded()
    }

    var allProgress: [String: WordProgress] {
        progressFile.wordProgress
    }

    var todayCompletedCount: Int {
        progressFile.todayCompletedIDs.count
    }

    var studyStreak: Int {
        currentStudyStreak()
    }

    func progress(for entry: WordEntry) -> WordProgress {
        progressFile.wordProgress[entry.progressID] ?? WordProgress(wordID: entry.progressID)
    }

    func upsert(_ progress: WordProgress) {
        progressFile.wordProgress[progress.wordID] = progress
        save()
    }

    func markCompletedToday(wordID: String) {
        rollTodayIfNeeded()
        if !progressFile.todayCompletedIDs.contains(wordID) {
            progressFile.todayCompletedIDs.append(wordID)
        }
        if !progressFile.activeDays.contains(progressFile.todayDateKey) {
            progressFile.activeDays.append(progressFile.todayDateKey)
        }
    }

    func toggleFavorite(for entry: WordEntry) {
        var item = progress(for: entry)
        item.isFavorite.toggle()
        upsert(item)
    }

    func resetAllProgress() {
        progressFile = StudyProgressFile()
        save()
    }

    @discardableResult
    func exportBackup() -> URL? {
        do {
            try ensureDirectory()
            let data = try encoder.encode(progressFile)
            let url = supportDirectory.appendingPathComponent("progress-backup.json")
            try data.write(to: url, options: [.atomic])
            lastErrorMessage = nil
            return url
        } catch {
            lastErrorMessage = error.localizedDescription
            return nil
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: progressURL.path) else {
            migrateLegacyProgressIfPossible()
            return
        }

        do {
            let data = try Data(contentsOf: progressURL)
            progressFile = try decoder.decode(StudyProgressFile.self, from: data)
            if progressFile.version < 3 {
                progressFile = ProgressMigration.migrate(progressFile)
                save()
            }
            lastErrorMessage = nil
        } catch {
            preserveCorruptFile()
            progressFile = StudyProgressFile()
            lastErrorMessage = "进度文件读取失败，已保留损坏副本。"
        }
    }

    private func save() {
        do {
            try ensureDirectory()
            let data = try encoder.encode(progressFile)
            let tmpURL = supportDirectory.appendingPathComponent("study-progress.tmp")
            try data.write(to: tmpURL, options: [.atomic])
            if FileManager.default.fileExists(atPath: progressURL.path) {
                _ = try FileManager.default.replaceItemAt(progressURL, withItemAt: tmpURL)
            } else {
                try FileManager.default.moveItem(at: tmpURL, to: progressURL)
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func preserveCorruptFile() {
        guard FileManager.default.fileExists(atPath: progressURL.path) else { return }
        let corruptURL = supportDirectory.appendingPathComponent("study-progress-corrupt.json")
        try? FileManager.default.removeItem(at: corruptURL)
        try? FileManager.default.copyItem(at: progressURL, to: corruptURL)
    }

    private func migrateLegacyProgressIfPossible() {
        let legacyProgress = loadLegacyStudyProgress()
        let knownIDs = legacyProgress?.knownIDs ?? legacyStringSet(forKey: "knownIDs")
        let reviewIDs = legacyProgress?.reviewIDs ?? legacyStringSet(forKey: "reviewIDs")
        let memories = legacyProgress?.memories ?? [:]
        guard !knownIDs.isEmpty || !reviewIDs.isEmpty || !memories.isEmpty else { return }

        for id in knownIDs {
            let wordID = stableProgressID(fromLegacyID: id)
            mergeLegacyProgress(WordProgress(
                wordID: wordID,
                seenCount: 1,
                correctCount: 1,
                familiarity: 3,
                lastReviewedAt: .now,
                nextReviewAt: Calendar.current.date(byAdding: .day, value: 7, to: .now)
            ))
        }
        for id in reviewIDs {
            let wordID = stableProgressID(fromLegacyID: id)
            mergeLegacyProgress(WordProgress(
                wordID: wordID,
                seenCount: 1,
                wrongCount: 1,
                familiarity: 1,
                lastReviewedAt: .now,
                nextReviewAt: .now
            ))
        }
        for (legacyID, memory) in memories {
            let wordID = stableProgressID(fromLegacyID: legacyID)
            mergeLegacyProgress(WordProgress(
                wordID: wordID,
                seenCount: max(memory.reviews, 1),
                correctCount: memory.familiarity >= 3 ? max(memory.reviews - memory.lapses, 0) : 0,
                wrongCount: memory.lapses,
                familiarity: memory.familiarity,
                lastReviewedAt: memory.lastReviewedAt,
                nextReviewAt: memory.dueAt,
                isFavorite: false,
                isIgnored: false
            ))
        }
        save()
    }

    private func mergeLegacyProgress(_ item: WordProgress) {
        if let existing = progressFile.wordProgress[item.wordID] {
            progressFile.wordProgress[item.wordID] = ProgressMigration.merge(
                existing,
                item,
                unifiedWordID: item.wordID
            )
        } else {
            progressFile.wordProgress[item.wordID] = item
        }
    }

    private func loadLegacyStudyProgress() -> LegacyStudyProgress? {
        let decoder = JSONDecoder()
        for key in ["cet_words_progress_v2", "cet_words_progress_v1"] {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let progress = try? decoder.decode(LegacyStudyProgress.self, from: data) else {
                continue
            }
            return progress
        }
        return nil
    }

    private func stableProgressID(fromLegacyID legacyID: String) -> String {
        ProgressMigration.unifiedWordID(from: legacyID)
    }

    private func legacyStringSet(forKey key: String) -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: key) as? [String] else { return [] }
        return Set(array)
    }

    private func rollTodayIfNeeded() {
        let key = Date.dayKey()
        if progressFile.todayDateKey != key {
            progressFile.todayDateKey = key
            progressFile.todayCompletedIDs = []
            save()
        }
    }

    private func currentStudyStreak() -> Int {
        let active = Set(progressFile.activeDays)
        guard !active.isEmpty else { return 0 }

        let calendar = Calendar.current
        var cursor = Date()
        if !active.contains(Date.dayKey(cursor)),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }

        var count = 0
        while active.contains(Date.dayKey(cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
    }

    private var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("CETWords", isDirectory: true)
    }

    private var progressURL: URL {
        supportDirectory.appendingPathComponent("study-progress.json")
    }
}

enum ProgressMigration {
    static func migrate(_ file: StudyProgressFile) -> StudyProgressFile {
        var migrated = StudyProgressFile(
            version: 3,
            todayCompletedIDs: stableUnique(file.todayCompletedIDs.map(unifiedWordID(from:))),
            todayDateKey: file.todayDateKey,
            activeDays: file.activeDays
        )

        for (oldID, progress) in file.wordProgress {
            let unifiedID = unifiedWordID(from: oldID)
            var item = progress
            item.wordID = unifiedID
            if let existing = migrated.wordProgress[unifiedID] {
                migrated.wordProgress[unifiedID] = merge(existing, item, unifiedWordID: unifiedID)
            } else {
                migrated.wordProgress[unifiedID] = item
            }
        }
        return migrated
    }

    static func merge(_ first: WordProgress, _ second: WordProgress, unifiedWordID: String) -> WordProgress {
        WordProgress(
            wordID: unifiedWordID,
            seenCount: first.seenCount + second.seenCount,
            correctCount: first.correctCount + second.correctCount,
            wrongCount: first.wrongCount + second.wrongCount,
            familiarity: max(first.familiarity, second.familiarity),
            lastReviewedAt: latest(first.lastReviewedAt, second.lastReviewedAt),
            nextReviewAt: earliest(first.nextReviewAt, second.nextReviewAt),
            isFavorite: first.isFavorite || second.isFavorite,
            isIgnored: first.isIgnored || second.isIgnored
        )
    }

    static func unifiedWordID(from oldID: String) -> String {
        if oldID.hasPrefix("word::") {
            return "word::\(normalize(String(oldID.dropFirst("word::".count))))"
        }
        if let separator = oldID.range(of: "::") {
            return "word::\(normalize(String(oldID[separator.upperBound...])))"
        }
        return WordBank.unifiedProgressID(forLegacyEntryID: oldID) ?? oldID
    }

    private static func normalize(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func latest(_ first: Date?, _ second: Date?) -> Date? {
        [first, second].compactMap { $0 }.max()
    }

    private static func earliest(_ first: Date?, _ second: Date?) -> Date? {
        [first, second].compactMap { $0 }.min()
    }

    private static func stableUnique(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }
}

private struct LegacyWordMemory: Codable {
    var familiarity: Int
    var intervalDays: Int
    var reviews: Int
    var lapses: Int
    var lastReviewedAt: Date?
    var dueAt: Date
}

private struct LegacyStudyProgress: Codable {
    var knownIDs: Set<String>?
    var reviewIDs: Set<String>?
    var currentIndexByLevel: [String: Int]?
    var memories: [String: LegacyWordMemory]?
    var lastBackupAt: Date?
}

extension Date {
    static func dayKey(_ date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
