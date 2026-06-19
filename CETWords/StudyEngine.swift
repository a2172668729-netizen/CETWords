import Foundation

@MainActor
final class StudyEngine: ObservableObject {
    @Published private(set) var currentTask: [WordEntry] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var currentMode: StudySessionMode = .daily
    @Published private(set) var reviewOnly: Bool = false

    let wordBank: [WordEntry]
    let progressStore: ProgressStore
    let settings: AppSettings
    let collections: [VocabularyCollection]
    private let libraryWordsByCollection: [Int: [WordEntry]]

    init(wordBank: [WordEntry] = WordBank.entries, progressStore: ProgressStore, settings: AppSettings) {
        self.wordBank = wordBank
        self.progressStore = progressStore
        self.settings = settings
        let collections = WordBank.buildCollections(from: wordBank)
        self.collections = collections
        self.libraryWordsByCollection = Dictionary(uniqueKeysWithValues: collections.map { collection in
            let sorted = collection.words.sorted {
                $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending
            }
            return (collection.id, sorted)
        })
        rebuildTodayTask()
    }

    var scopedWords: [WordEntry] {
        studyWords(inCollection: settings.selectedCollectionID)
    }

    var currentCollection: VocabularyCollection {
        collections.first { $0.id == settings.selectedCollectionID } ?? collections[0]
    }

    var currentWord: WordEntry? {
        guard currentTask.indices.contains(currentIndex) else { return nil }
        return currentTask[currentIndex]
    }

    var dueReviewWords: [WordEntry] {
        dueWords(in: activeWords)
    }

    var weakReviewWords: [WordEntry] {
        weakWords(in: activeWords)
    }

    var nextDueDate: Date? {
        activeWords
            .compactMap { progressStore.progress(for: $0).nextReviewAt }
            .filter { $0 > .now }
            .min()
    }

    var todayCompletedCount: Int {
        progressStore.todayCompletedCount
    }

    func words(inCollection collectionID: Int) -> [WordEntry] {
        (libraryWordsByCollection[collectionID] ?? []).filter { !progressStore.progress(for: $0).isIgnored }
    }

    func collectionStats(for collectionID: Int) -> VocabularyCollectionStats {
        let statuses = words(inCollection: collectionID).map(displayStatus(for:))
        return VocabularyCollectionStats(
            totalWords: statuses.count,
            unmasteredWords: statuses.filter { $0 == .unmastered }.count,
            reinforceWords: statuses.filter { $0 == .reinforce }.count,
            masteredWords: statuses.filter { $0 == .mastered }.count
        )
    }

    func rebuildTodayTask(reviewOnly: Bool = false, weakOnly: Bool = false) {
        if reviewOnly {
            rebuildTask(mode: .review)
        } else if weakOnly {
            rebuildTask(mode: .weak)
        } else {
            rebuildTask(mode: .daily)
        }
    }

    func rebuildQuizTask() {
        rebuildTask(mode: .quiz)
    }

    func rebuildFreeStudyTask() {
        rebuildTask(mode: .free)
    }

    func rebuildCollectionStudyTask(collectionID: Int) {
        settings.selectedCollectionID = collectionID
        rebuildTask(mode: .free)
    }

    func rebuildTask(mode: StudySessionMode) {
        currentMode = mode
        reviewOnly = mode == .review || mode == .weak

        let currentCollectionWords = studyWords(inCollection: settings.selectedCollectionID)
        let allDue = dueWords(in: activeWords)
        let allWeak = weakWords(in: activeWords)
        let allWeakNotDue = allWeak.filter { word in !allDue.contains { $0.progressID == word.progressID } }
        let currentDue = dueWords(in: currentCollectionWords)
        let currentWeak = weakWords(in: currentCollectionWords)
        let currentWeakNotDue = currentWeak.filter { word in !currentDue.contains { $0.progressID == word.progressID } }
        let new = newWords(in: currentCollectionWords)
        let target = settings.dailyNewWordTarget

        switch mode {
        case .daily:
            let remaining = max(target - progressStore.todayCompletedCount, 0)
            let effectiveTarget = max(remaining, min(5, target))
            currentTask = LearningPolicy.buildDailyTask(
                dueReviewWords: allDue,
                weakWords: allWeakNotDue,
                newWords: new,
                dailyTarget: effectiveTarget,
                prioritizeReview: settings.prioritizeReview
            )
        case .review:
            currentTask = LearningPolicy.buildReviewTask(dueReviewWords: allDue, dailyTarget: target)
        case .weak:
            currentTask = LearningPolicy.buildWeakTask(weakWords: allWeak, dailyTarget: target)
        case .quiz:
            let learned = currentCollectionWords.filter { progressStore.progress(for: $0).seenCount > 0 }
            let quizTask = LearningPolicy.buildQuizTask(
                dueReviewWords: currentDue,
                weakWords: currentWeak,
                learnedWords: learned,
                dailyTarget: target
            )
            currentTask = quizTask.isEmpty ? Array(new.prefix(min(max(target, 10), 30))) : quizTask
        case .free:
            let learned = currentCollectionWords.filter { progressStore.progress(for: $0).seenCount > 0 }
            currentTask = LearningPolicy.buildFreeStudyTask(
                dueReviewWords: currentDue,
                weakWords: currentWeakNotDue,
                newWords: new,
                learnedWords: learned,
                limit: max(target, 50)
            )
        }
        currentIndex = 0
    }

    func rateCurrent(_ rating: ReviewRating) {
        guard let entry = currentWord else { return }
        apply(rating, to: entry)
        currentIndex += 1
        if currentIndex >= currentTask.count {
            currentTask = []
            currentIndex = 0
        }
    }

    func apply(_ rating: ReviewRating, to entry: WordEntry) {
        var progress = progressStore.progress(for: entry)
        progress.wordID = entry.progressID
        progress = LearningPolicy.updatedProgress(progress, rating: rating)
        progress.wordID = entry.progressID

        progressStore.markCompletedToday(wordID: entry.progressID)
        progressStore.upsert(progress)
    }

    func toggleFavorite(_ entry: WordEntry) {
        progressStore.toggleFavorite(for: entry)
    }

    func stats() -> StudyStats {
        let words = activeWords
        let now = Date()
        let progresses = words.map { progressStore.progress(for: $0) }
        let studied = progresses.filter { $0.seenCount > 0 }.count
        let unlearned = progresses.filter { $0.seenCount == 0 }.count
        let mastered = progresses.filter { $0.familiarity >= 6 }.count
        let weak = progresses.filter { isWeak($0) && !$0.isIgnored }.count
        let learning = progresses.filter { progress in
            progress.seenCount > 0 && progress.familiarity < 6 && !isWeak(progress)
        }.count
        let due = progresses.filter { item in
            guard let next = item.nextReviewAt else { return false }
            return next <= now && !item.isIgnored
        }.count
        let favorites = progresses.filter(\.isFavorite).count
        let reviewedToday = progresses.filter { item in
            guard let reviewedAt = item.lastReviewedAt else { return false }
            return Date.dayKey(reviewedAt) == Date.dayKey()
        }.count

        return StudyStats(
            totalWords: words.count,
            studiedWords: studied,
            unlearnedWords: unlearned,
            learningWords: learning,
            masteredWords: mastered,
            dueWords: due,
            weakWords: weak,
            favoriteWords: favorites,
            reviewedToday: reviewedToday,
            todayCompleted: progressStore.todayCompletedCount,
            todayTarget: settings.dailyNewWordTarget,
            studyStreak: progressStore.studyStreak
        )
    }

    private func dueWords(in words: [WordEntry]) -> [WordEntry] {
        let now = Date()
        return words
            .filter { entry in
                let progress = progressStore.progress(for: entry)
                guard !progress.isIgnored, let next = progress.nextReviewAt else { return false }
                return next <= now
            }
            .sorted { lhs, rhs in
                let left = progressStore.progress(for: lhs)
                let right = progressStore.progress(for: rhs)
                return (left.nextReviewAt ?? .distantFuture) < (right.nextReviewAt ?? .distantFuture)
            }
    }

    private func newWords(in words: [WordEntry]) -> [WordEntry] {
        words.filter { progressStore.progress(for: $0).seenCount == 0 }
    }

    private func weakWords(in words: [WordEntry]) -> [WordEntry] {
        words
            .filter { entry in
                let progress = progressStore.progress(for: entry)
                return isWeak(progress) && !progress.isIgnored
            }
            .sorted { lhs, rhs in
                progressStore.progress(for: lhs).familiarity < progressStore.progress(for: rhs).familiarity
            }
    }

    func filteredWords(collectionID: Int, filter: LibraryFilter, query: String) -> [WordEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = words(inCollection: collectionID)
        let filteredByState = source.filter { entry in
            let progress = progressStore.progress(for: entry)
            switch filter {
            case .all:
                return true
            case .unmastered:
                return LearningPolicy.displayStatus(for: progress) == .unmastered
            case .reinforce:
                return LearningPolicy.displayStatus(for: progress) == .reinforce
            case .mastered:
                return LearningPolicy.displayStatus(for: progress) == .mastered
            case .favorite:
                return progress.isFavorite
            case .due:
                guard let next = progress.nextReviewAt else { return false }
                return next <= .now
            }
        }
        guard !trimmed.isEmpty else { return filteredByState }
        return filteredByState.filter {
            $0.word.localizedCaseInsensitiveContains(trimmed) ||
            $0.primaryMeaning.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func isWeak(_ progress: WordProgress) -> Bool {
        LearningPolicy.isWeak(progress)
    }

    func learningStage(for entry: WordEntry) -> WordLearningStage {
        LearningPolicy.stage(for: progressStore.progress(for: entry))
    }

    func displayStatus(for entry: WordEntry) -> WordDisplayStatus {
        LearningPolicy.displayStatus(for: progressStore.progress(for: entry))
    }

    func quizKindForCurrentWord() -> QuizQuestionKind {
        currentIndex.isMultiple(of: 2) ? .chooseMeaning : .spellWord
    }

    func quizOptions(for entry: WordEntry) -> [String] {
        let source = words(inCollection: settings.selectedCollectionID)
        var options = [entry.primaryMeaning]

        guard let index = source.firstIndex(where: { $0.progressID == entry.progressID }) else {
            return options
        }

        for step in 1...source.count {
            guard options.count < 4 else { break }
            let candidate = source[(index + step * 7) % source.count]
            guard candidate.progressID != entry.progressID,
                  !options.contains(candidate.primaryMeaning) else {
                continue
            }
            options.append(candidate.primaryMeaning)
        }

        return shuffled(options, seedText: entry.word)
    }

    func isCorrectMeaning(_ selectedMeaning: String, for entry: WordEntry) -> Bool {
        selectedMeaning == entry.primaryMeaning
    }

    func isCorrectSpelling(_ input: String, for entry: WordEntry) -> Bool {
        normalizeAnswer(input) == normalizeAnswer(entry.word)
    }

    private var activeWords: [WordEntry] {
        wordBank.filter { !progressStore.progress(for: $0).isIgnored }
    }

    private func studyWords(inCollection collectionID: Int) -> [WordEntry] {
        let collection = collections.first { $0.id == collectionID } ?? collections[0]
        return collection.words.filter { !progressStore.progress(for: $0).isIgnored }
    }

    private func shuffled(_ items: [String], seedText: String) -> [String] {
        guard items.count > 1 else { return items }
        var result = items
        let seed = seedText.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let swapIndex = abs(seed + index * 31) % (index + 1)
            result.swapAt(index, swapIndex)
        }
        return result
    }

    private func normalizeAnswer(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
