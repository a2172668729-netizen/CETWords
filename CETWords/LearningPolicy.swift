import Foundation

enum LearningPolicy {
    static func nextReviewDate(for rating: ReviewRating, currentProgress: WordProgress, now: Date = .now) -> Date {
        switch rating {
        case .forgot:
            return Calendar.current.date(byAdding: .minute, value: 10, to: now) ?? now
        case .vague:
            return Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        case .known, .mastered:
            let nextFamiliarity = min(currentProgress.familiarity + 1, 7)
            return Calendar.current.date(byAdding: .day, value: knownIntervalDays(for: nextFamiliarity), to: now) ?? now
        }
    }

    static func updatedProgress(_ progress: WordProgress, rating: ReviewRating, now: Date = .now) -> WordProgress {
        var updated = progress
        updated.seenCount += 1
        updated.lastReviewedAt = now

        switch rating {
        case .forgot:
            updated.wrongCount += 1
            updated.familiarity = max(0, updated.familiarity - 2)
        case .vague:
            updated.familiarity = min(max(updated.familiarity, 1) + 1, 3)
        case .known, .mastered:
            updated.correctCount += 1
            updated.familiarity = min(updated.familiarity + 1, 7)
        }

        updated.nextReviewAt = nextReviewDate(for: rating, currentProgress: progress, now: now)
        return updated
    }

    static func stage(for progress: WordProgress) -> WordLearningStage {
        if progress.seenCount == 0 {
            return .new
        }
        if progress.familiarity >= 6 {
            return .mastered
        }
        if isWeak(progress) {
            return .weak
        }
        return .learning
    }

    static func displayStatus(for progress: WordProgress) -> WordDisplayStatus {
        if progress.seenCount == 0 {
            return .unmastered
        }
        if progress.familiarity >= 6 {
            return .mastered
        }
        return .reinforce
    }

    static func isWeak(_ progress: WordProgress) -> Bool {
        progress.wrongCount > 0 ||
        progress.familiarity <= 1 && progress.seenCount > 0 ||
        progress.seenCount >= 2 && progress.correctCount * 2 < progress.seenCount
    }

    static func buildDailyTask(
        dueReviewWords: [WordEntry],
        weakWords: [WordEntry],
        newWords: [WordEntry],
        dailyTarget: Int,
        prioritizeReview: Bool
    ) -> [WordEntry] {
        let target = max(dailyTarget, 5)
        var result: [WordEntry] = []
        var seen = Set<String>()

        let dueLimit = prioritizeReview ? target : max(1, target / 3)
        appendUnique(dueReviewWords.prefix(dueLimit), to: &result, seen: &seen, limit: target)

        let weakLimit = max(2, target / 3)
        appendUnique(weakWords.prefix(weakLimit), to: &result, seen: &seen, limit: target)

        appendUnique(newWords, to: &result, seen: &seen, limit: target)

        if result.count < target {
            appendUnique(dueReviewWords.dropFirst(dueLimit), to: &result, seen: &seen, limit: target)
            appendUnique(weakWords.dropFirst(weakLimit), to: &result, seen: &seen, limit: target)
        }

        return result
    }

    static func buildReviewTask(dueReviewWords: [WordEntry], dailyTarget: Int) -> [WordEntry] {
        stableUnique(Array(dueReviewWords.prefix(max(dailyTarget, 20))))
    }

    static func buildWeakTask(weakWords: [WordEntry], dailyTarget: Int) -> [WordEntry] {
        stableUnique(Array(weakWords.prefix(max(dailyTarget, 20))))
    }

    static func buildQuizTask(
        dueReviewWords: [WordEntry],
        weakWords: [WordEntry],
        learnedWords: [WordEntry],
        dailyTarget: Int
    ) -> [WordEntry] {
        let limit = min(max(dailyTarget, 10), 30)
        return stableUnique(Array((dueReviewWords + weakWords + learnedWords).prefix(limit)))
    }

    static func buildFreeStudyTask(
        dueReviewWords: [WordEntry],
        weakWords: [WordEntry],
        newWords: [WordEntry],
        learnedWords: [WordEntry],
        limit: Int
    ) -> [WordEntry] {
        let target = min(max(limit, 1), 100)
        var result: [WordEntry] = []
        var seen = Set<String>()

        appendUnique(newWords, to: &result, seen: &seen, limit: target)
        appendUnique(dueReviewWords, to: &result, seen: &seen, limit: target)
        appendUnique(weakWords, to: &result, seen: &seen, limit: target)
        appendUnique(learnedWords, to: &result, seen: &seen, limit: target)

        return result
    }

    static func nextReviewDescription(for rating: ReviewRating) -> String {
        switch rating {
        case .forgot:
            return "10 分钟后再出现"
        case .vague:
            return "明天复习"
        case .known, .mastered:
            return "按熟悉度延后复习"
        }
    }

    private static func appendUnique<S: Sequence>(
        _ words: S,
        to result: inout [WordEntry],
        seen: inout Set<String>,
        limit: Int
    ) where S.Element == WordEntry {
        for word in words {
            guard result.count < limit else { return }
            if seen.insert(word.progressID).inserted {
                result.append(word)
            }
        }
    }

    private static func stableUnique(_ words: [WordEntry]) -> [WordEntry] {
        var result: [WordEntry] = []
        var seen = Set<String>()
        appendUnique(words, to: &result, seen: &seen, limit: words.count)
        return result
    }

    private static func knownIntervalDays(for familiarity: Int) -> Int {
        switch familiarity {
        case ..<3:
            return 3
        case 3:
            return 7
        case 4...5:
            return 15
        default:
            return 30
        }
    }
}
