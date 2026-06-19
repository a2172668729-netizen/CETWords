import SwiftUI

struct WordDetailView: View {
    let entry: WordEntry
    @ObservedObject var engine: StudyEngine

    var body: some View {
        let progress = engine.progressStore.progress(for: entry)
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(entry.word)
                            .font(.largeTitle.weight(.bold))
                        Spacer()
                        Button {
                            engine.toggleFavorite(entry)
                        } label: {
                            Image(systemName: progress.isFavorite ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(progress.isFavorite ? .yellow : .secondary)
                        }
                    }
                    Text("来源：\(entry.sourceDisplayName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
            }

            Section("释义") {
                ForEach(Array(entry.meanings.enumerated()), id: \.offset) { _, meaning in
                    Text(meaning)
                }
            }

            Section("短语") {
                if entry.phrases.isEmpty {
                    Text("当前词库暂无短语数据")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.phrases, id: \.self) { phrase in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phrase.phrase)
                                .font(.headline)
                            Text(phrase.translation)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("例句") {
                if entry.examples.isEmpty {
                    Text("当前词库暂无例句数据")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.examples, id: \.self) { example in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(example.sentence)
                                .font(.headline)
                            Text(example.translation)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("学习记录") {
                LabeledContent("单词状态", value: engine.displayStatus(for: entry).displayName)
                LabeledContent("学习阶段", value: engine.learningStage(for: entry).displayName)
                LabeledContent("学习次数", value: "\(progress.seenCount)")
                LabeledContent("正确次数", value: "\(progress.correctCount)")
                LabeledContent("错误次数", value: "\(progress.wrongCount)")
                LabeledContent("正确率", value: accuracyText(progress))
                LabeledContent("熟悉度", value: "\(progress.familiarity)")
                LabeledContent("下次复习", value: format(progress.nextReviewAt))
            }
        }
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "未安排" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func accuracyText(_ progress: WordProgress) -> String {
        guard progress.seenCount > 0 else { return "暂无" }
        return "\(Int(Double(progress.correctCount) / Double(progress.seenCount) * 100))%"
    }
}
