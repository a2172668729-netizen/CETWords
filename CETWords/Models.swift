import Foundation

enum WordLevel: String, Codable, Hashable, CaseIterable {
    case cet4
    case cet6

    var displayName: String {
        switch self {
        case .cet4:
            return "四级"
        case .cet6:
            return "六级"
        }
    }

    var resourceName: String {
        switch self {
        case .cet4:
            return "cet4"
        case .cet6:
            return "cet6"
        }
    }
}

struct Phrase: Codable, Hashable {
    let phrase: String
    let translation: String
}

struct ExampleSentence: Codable, Hashable {
    let sentence: String
    let translation: String
}

struct WordEntry: Identifiable, Codable, Hashable {
    let id: String
    let word: String
    let sources: Set<WordLevel>
    let meanings: [String]
    let phoneticUS: String?
    let phoneticUK: String?
    let phrases: [Phrase]
    let examples: [ExampleSentence]

    var primaryMeaning: String {
        meanings.joined(separator: "；")
    }

    var progressID: String {
        "word::\(normalizedWord)"
    }

    var sourceDisplayName: String {
        WordLevel.allCases
            .filter { sources.contains($0) }
            .map(\.displayName)
            .joined(separator: "、")
    }

    private var normalizedWord: String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    init(
        id: String,
        word: String,
        sources: Set<WordLevel>,
        meanings: [String],
        phoneticUS: String?,
        phoneticUK: String?,
        phrases: [Phrase],
        examples: [ExampleSentence]
    ) {
        self.id = id
        self.word = word
        self.sources = sources
        self.meanings = meanings
        self.phoneticUS = phoneticUS
        self.phoneticUK = phoneticUK
        self.phrases = phrases
        self.examples = examples
    }

    init(
        id: String,
        word: String,
        level: WordLevel,
        meanings: [String],
        phoneticUS: String?,
        phoneticUK: String?,
        phrases: [Phrase],
        examples: [ExampleSentence]
    ) {
        self.init(
            id: id,
            word: word,
            sources: [level],
            meanings: meanings,
            phoneticUS: phoneticUS,
            phoneticUK: phoneticUK,
            phrases: phrases,
            examples: examples
        )
    }
}

struct WordItem: Identifiable, Codable, Equatable {
    let id: String
    let word: String
    let meaning: String
    let sources: String
}

struct VocabularyCollection: Identifiable, Hashable {
    let id: Int
    let words: [WordEntry]

    var displayName: String {
        "词库 \(id)"
    }
}

struct VocabularyCollectionStats {
    let totalWords: Int
    let unmasteredWords: Int
    let reinforceWords: Int
    let masteredWords: Int

    var completionRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords)
    }
}

enum WordDisplayStatus: String, CaseIterable, Identifiable {
    case unmastered
    case reinforce
    case mastered

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unmastered:
            return "未掌握"
        case .reinforce:
            return "待强化"
        case .mastered:
            return "已掌握"
        }
    }
}

struct WordProgress: Codable, Hashable {
    var wordID: String
    var seenCount: Int
    var correctCount: Int
    var wrongCount: Int
    var familiarity: Int
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var isFavorite: Bool
    var isIgnored: Bool

    init(
        wordID: String,
        seenCount: Int = 0,
        correctCount: Int = 0,
        wrongCount: Int = 0,
        familiarity: Int = 0,
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        isFavorite: Bool = false,
        isIgnored: Bool = false
    ) {
        self.wordID = wordID
        self.seenCount = seenCount
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.familiarity = familiarity
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.isFavorite = isFavorite
        self.isIgnored = isIgnored
    }
}

enum ReviewRating: String, Codable, CaseIterable, Identifiable {
    case forgot
    case vague
    case known
    case mastered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forgot:
            return "不认识"
        case .vague:
            return "模糊"
        case .known:
            return "认识"
        case .mastered:
            return "熟练"
        }
    }

    static var visibleRatings: [ReviewRating] {
        [.forgot, .vague, .known]
    }
}

struct StudyStats {
    let totalWords: Int
    let studiedWords: Int
    let unlearnedWords: Int
    let learningWords: Int
    let masteredWords: Int
    let dueWords: Int
    let weakWords: Int
    let favoriteWords: Int
    let reviewedToday: Int
    let todayCompleted: Int
    let todayTarget: Int
    let studyStreak: Int

    var todayCompletionRate: Double {
        guard todayTarget > 0 else { return 0 }
        return min(1, Double(todayCompleted) / Double(todayTarget))
    }

    var masteryRate: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords)
    }
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
    case unmastered
    case reinforce
    case mastered
    case favorite
    case due

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "全部"
        case .unmastered:
            return "未掌握"
        case .reinforce:
            return "待强化"
        case .mastered:
            return "已掌握"
        case .favorite:
            return "收藏"
        case .due:
            return "待复习"
        }
    }
}

enum WordLearningStage: String, CaseIterable, Identifiable {
    case new
    case learning
    case weak
    case mastered

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new:
            return "未学"
        case .learning:
            return "学习中"
        case .weak:
            return "错题/不熟"
        case .mastered:
            return "已掌握"
        }
    }
}

enum StudySessionMode: String, CaseIterable, Identifiable {
    case daily
    case review
    case weak
    case quiz
    case free

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "今日学习"
        case .review:
            return "到期复习"
        case .weak:
            return "错题强化"
        case .quiz:
            return "测验"
        case .free:
            return "自由学习"
        }
    }
}

enum QuizQuestionKind: String, CaseIterable {
    case chooseMeaning
    case spellWord

    var title: String {
        switch self {
        case .chooseMeaning:
            return "选择释义"
        case .spellWord:
            return "拼写回忆"
        }
    }
}
