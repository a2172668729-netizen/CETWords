import Foundation

func assertCondition(_ condition: Bool, _ message: String) {
    if !condition {
        print("FAILED: \(message)")
        exit(1)
    }
}

@main
struct LearningPolicyCheck {
    static func main() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        var newProgress = WordProgress(wordID: "cet4::sample")

        let forgotDate = LearningPolicy.nextReviewDate(for: .forgot, currentProgress: newProgress, now: baseDate)
        let vagueDate = LearningPolicy.nextReviewDate(for: .vague, currentProgress: newProgress, now: baseDate)
        let knownDate = LearningPolicy.nextReviewDate(for: .known, currentProgress: newProgress, now: baseDate)

        assertCondition(forgotDate.timeIntervalSince(baseDate) == 10 * 60, "forgot words should return after 10 minutes")
        assertCondition(vagueDate.timeIntervalSince(baseDate) == 24 * 60 * 60, "vague words should return tomorrow")
        assertCondition(knownDate.timeIntervalSince(baseDate) == 3 * 24 * 60 * 60, "new known words should return in 3 days")

        newProgress.familiarity = 4
        let strongerKnownDate = LearningPolicy.nextReviewDate(for: .known, currentProgress: newProgress, now: baseDate)
        assertCondition(strongerKnownDate.timeIntervalSince(baseDate) == 15 * 24 * 60 * 60, "familiar known words should use longer intervals")

        let due = sampleWords(prefix: "due", count: 4)
        let weak = sampleWords(prefix: "weak", count: 4)
        let fresh = sampleWords(prefix: "new", count: 8)
        let task = LearningPolicy.buildDailyTask(
            dueReviewWords: due,
            weakWords: weak,
            newWords: fresh,
            dailyTarget: 10,
            prioritizeReview: true
        )

        assertCondition(task.count == 10, "daily task should match target when enough words exist")
        assertCondition(task.prefix(4).map(\.word) == due.map(\.word), "due review words should be first")
        assertCondition(task.contains(where: { $0.word == "weak-1" }), "weak words should be included")
        assertCondition(task.contains(where: { $0.word == "new-1" }), "new words should fill remaining slots")

        let freeTask = LearningPolicy.buildFreeStudyTask(
            dueReviewWords: due,
            weakWords: weak,
            newWords: fresh,
            learnedWords: sampleWords(prefix: "learned", count: 6),
            limit: 14
        )

        assertCondition(freeTask.count == 14, "free study should fill the requested limit when enough words exist")
        assertCondition(freeTask.prefix(8).map(\.word) == fresh.map(\.word), "free study should prefer unlearned words first")
        assertCondition(freeTask.contains(where: { $0.word == "due-1" }), "free study should include due words after new words")
        assertCondition(freeTask.contains(where: { $0.word == "weak-1" }), "free study should include weak words after new words")

        print("LearningPolicy checks passed")
    }
}

func sampleWords(prefix: String, count: Int) -> [WordEntry] {
    (1...count).map { index in
        WordEntry(
            id: "\(prefix)-\(index)",
            word: "\(prefix)-\(index)",
            level: .cet4,
            meanings: ["释义 \(index)"],
            phoneticUS: nil,
            phoneticUK: nil,
            phrases: [],
            examples: []
        )
    }
}
