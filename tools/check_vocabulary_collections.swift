import Foundation

func assertVocabularyCondition(_ condition: Bool, _ message: String) {
    if !condition {
        print("FAILED: \(message)")
        exit(1)
    }
}

@main
struct VocabularyCollectionsCheck {
    static func main() throws {
        let cet4Text = try String(contentsOfFile: "CETWords/Resources/VocabSources/cet4.txt", encoding: .utf8)
        let cet6Text = try String(contentsOfFile: "CETWords/Resources/VocabSources/cet6.txt", encoding: .utf8)
        let cet4 = WordBank.parseEntries(text: cet4Text, source: .cet4)
        let cet6 = WordBank.parseEntries(text: cet6Text, source: .cet6)
        let merged = WordBank.mergeEntries(cet4 + cet6)

        assertVocabularyCondition(merged.count == 6_661, "merged vocabulary should contain 6661 unique words")
        assertVocabularyCondition(Set(merged.map(\.progressID)).count == merged.count, "merged progress IDs should be unique")

        let access = merged.first { $0.word.lowercased() == "access" }
        assertVocabularyCondition(access?.sources == Set([.cet4, .cet6]), "cross-level words should retain both sources")
        assertVocabularyCondition(access?.progressID == "word::access", "progress ID should use normalized word")
        assertVocabularyCondition((access?.meanings.count ?? 0) > 1, "cross-level meanings should be merged")

        let firstCollections = WordBank.buildCollections(from: merged)
        let secondCollections = WordBank.buildCollections(from: merged)
        let counts = firstCollections.map { $0.words.count }
        let allCollectionIDs = firstCollections.flatMap { $0.words.map(\.progressID) }

        assertVocabularyCondition(firstCollections.count == 20, "there should be 20 collections")
        assertVocabularyCondition(WordBank.collectionLayoutVersion == 1, "collection layout changes should require a version bump")
        assertVocabularyCondition(counts.max()! - counts.min()! <= 1, "collection sizes should differ by at most one")
        assertVocabularyCondition(Set(allCollectionIDs).count == merged.count, "each word should belong to exactly one collection")
        assertVocabularyCondition(
            firstCollections.map { $0.words.map(\.progressID) } == secondCollections.map { $0.words.map(\.progressID) },
            "fixed shuffle should be deterministic"
        )

        assertVocabularyCondition(
            LearningPolicy.displayStatus(for: WordProgress(wordID: "word::new")) == .unmastered,
            "unseen words should be red/unmastered"
        )
        assertVocabularyCondition(
            LearningPolicy.displayStatus(for: WordProgress(wordID: "word::learning", seenCount: 1, familiarity: 3)) == .reinforce,
            "studied but not mastered words should be yellow/reinforce"
        )
        assertVocabularyCondition(
            LearningPolicy.displayStatus(for: WordProgress(wordID: "word::mastered", seenCount: 3, familiarity: 6)) == .mastered,
            "familiarity 6 words should be green/mastered"
        )

        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_700_100_000)
        let mergedProgress = ProgressMigration.merge(
            WordProgress(
                wordID: "cet4::access",
                seenCount: 2,
                correctCount: 1,
                wrongCount: 1,
                familiarity: 2,
                lastReviewedAt: earlier,
                nextReviewAt: later,
                isFavorite: false
            ),
            WordProgress(
                wordID: "cet6::access",
                seenCount: 3,
                correctCount: 2,
                wrongCount: 1,
                familiarity: 5,
                lastReviewedAt: later,
                nextReviewAt: earlier,
                isFavorite: true
            ),
            unifiedWordID: "word::access"
        )

        assertVocabularyCondition(mergedProgress.wordID == "word::access", "migrated progress should use unified ID")
        assertVocabularyCondition(mergedProgress.seenCount == 5, "migrated seen counts should be added")
        assertVocabularyCondition(mergedProgress.correctCount == 3, "migrated correct counts should be added")
        assertVocabularyCondition(mergedProgress.wrongCount == 2, "migrated wrong counts should be added")
        assertVocabularyCondition(mergedProgress.familiarity == 5, "migrated familiarity should keep the highest value")
        assertVocabularyCondition(mergedProgress.lastReviewedAt == later, "migrated last review should keep the latest date")
        assertVocabularyCondition(mergedProgress.nextReviewAt == earlier, "migrated next review should keep the earliest date")
        assertVocabularyCondition(mergedProgress.isFavorite, "migrated favorites should be preserved")

        let migratedFile = ProgressMigration.migrate(
            StudyProgressFile(
                version: 2,
                wordProgress: [
                    "cet4::access": WordProgress(wordID: "cet4::access", seenCount: 1, familiarity: 2),
                    "cet6::access": WordProgress(wordID: "cet6::access", seenCount: 2, familiarity: 4)
                ],
                todayCompletedIDs: ["cet4::access", "cet6::access"],
                todayDateKey: "2026-06-13",
                activeDays: ["2026-06-13"]
            )
        )
        assertVocabularyCondition(migratedFile.version == 3, "migrated progress file should use version 3")
        assertVocabularyCondition(migratedFile.wordProgress.count == 1, "duplicate old progress keys should become one unified key")
        assertVocabularyCondition(migratedFile.wordProgress["word::access"]?.seenCount == 3, "file migration should merge progress values")
        assertVocabularyCondition(migratedFile.todayCompletedIDs == ["word::access"], "today completion IDs should migrate and deduplicate")

        print("Vocabulary collection checks passed")
    }
}
