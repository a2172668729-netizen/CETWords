import SwiftUI

struct QuizView: View {
    @ObservedObject var engine: StudyEngine
    @State private var selectedMeaning: String?
    @State private var spellingText = ""
    @State private var resultText: String?
    @State private var resultIsCorrect = false
    @State private var pendingRating: ReviewRating?

    var body: some View {
        VStack(spacing: 16) {
            if engine.currentMode != .quiz || engine.currentWord == nil {
                emptyOrStartView
            } else if let word = engine.currentWord {
                quizContent(for: word)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("测验")
        .onChange(of: engine.currentIndex) {
            resetAnswer()
        }
    }

    private var emptyOrStartView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "暂无测验题",
                systemImage: "checklist",
                description: Text("测验会优先抽到期词和错题。如果还没有学习记录，也会先抽一些新词。")
            )

            Button {
                engine.rebuildQuizTask()
                resetAnswer()
            } label: {
                Label("开始测验", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
    }

    private func quizContent(for word: WordEntry) -> some View {
        let kind = engine.quizKindForCurrentWord()

        return VStack(spacing: 16) {
            HStack {
                Label(kind.title, systemImage: kind == .chooseMeaning ? "list.bullet.rectangle" : "keyboard")
                    .font(.headline)
                Spacer()
                Text("\(engine.currentIndex + 1)/\(engine.currentTask.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .panelStyle()

            if kind == .chooseMeaning {
                chooseMeaningView(for: word)
            } else {
                spellWordView(for: word)
            }

            if let resultText {
                Text(resultText)
                    .font(.headline)
                    .foregroundStyle(resultIsCorrect ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .panelStyle()
            }

            Button {
                if let pendingRating {
                    engine.rateCurrent(pendingRating)
                    resetAnswer()
                } else {
                    submitAnswer(for: word, kind: kind)
                }
            } label: {
                Label(pendingRating == nil ? "提交" : "下一题", systemImage: pendingRating == nil ? "checkmark.circle" : "arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(pendingRating == nil ? .indigo : .green)
            .disabled(!canSubmit(kind: kind))
        }
    }

    private func chooseMeaningView(for word: WordEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(word.word)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            ForEach(engine.quizOptions(for: word), id: \.self) { option in
                Button {
                    selectedMeaning = option
                } label: {
                    HStack {
                        Text(option)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if selectedMeaning == option {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .disabled(pendingRating != nil)
            }
        }
        .panelStyle()
    }

    private func spellWordView(for word: WordEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(word.primaryMeaning)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("输入英文单词", text: $spellingText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .disabled(pendingRating != nil)

            if pendingRating != nil {
                Text("正确答案：\(word.word)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .panelStyle()
    }

    private func submitAnswer(for word: WordEntry, kind: QuizQuestionKind) {
        let isCorrect: Bool
        switch kind {
        case .chooseMeaning:
            isCorrect = selectedMeaning.map { engine.isCorrectMeaning($0, for: word) } ?? false
        case .spellWord:
            isCorrect = engine.isCorrectSpelling(spellingText, for: word)
        }

        resultIsCorrect = isCorrect
        resultText = isCorrect ? "答对了" : "答错了，会进入短间隔复习"
        pendingRating = isCorrect ? .known : .forgot
    }

    private func canSubmit(kind: QuizQuestionKind) -> Bool {
        if pendingRating != nil { return true }
        switch kind {
        case .chooseMeaning:
            return selectedMeaning != nil
        case .spellWord:
            return !spellingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func resetAnswer() {
        selectedMeaning = nil
        spellingText = ""
        resultText = nil
        resultIsCorrect = false
        pendingRating = nil
    }
}
