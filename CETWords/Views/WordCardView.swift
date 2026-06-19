import SwiftUI

struct WordCardView: View {
    @ObservedObject var engine: StudyEngine
    @State private var showingMeaning = false

    var body: some View {
        VStack(spacing: 16) {
            if let word = engine.currentWord {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        StatusBadge(status: engine.displayStatus(for: word))
                        Spacer()
                        Text(progressText(for: word))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(word.word)
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)

                    Divider()

                    if showingMeaning {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(word.meanings.enumerated()), id: \.offset) { _, meaning in
                                Text(meaning)
                                    .font(.title3.weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } else {
                        Button {
                            withAnimation { showingMeaning = true }
                        } label: {
                            Label("翻卡看释义", systemImage: "hand.tap")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .panelStyle()

                HStack(spacing: 10) {
                    ForEach(ReviewRating.visibleRatings) { rating in
                        ratingButton(rating, tint: tint(for: rating))
                    }
                }
            } else {
                ContentUnavailableView(emptyTitle, systemImage: "checkmark.circle", description: Text(emptyDescription))
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationTitle(engine.currentMode.title)
        .onChange(of: engine.currentIndex) {
            showingMeaning = false
        }
    }

    private func ratingButton(_ rating: ReviewRating, tint: Color) -> some View {
        Button {
            engine.rateCurrent(rating)
            showingMeaning = false
        } label: {
            VStack(spacing: 4) {
                Text(rating.title)
                    .font(.headline.weight(.bold))
                Text(LearningPolicy.nextReviewDescription(for: rating))
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .disabled(engine.currentWord == nil)
    }

    private func progressText(for word: WordEntry) -> String {
        let progress = engine.progressStore.progress(for: word)
        if progress.seenCount == 0 { return "未学" }
        return "已学 \(progress.seenCount) 次"
    }

    private var emptyTitle: String {
        switch engine.currentMode {
        case .daily:
            return "今日任务已完成"
        case .free:
            return "本次自由学习已完成"
        default:
            return "\(engine.currentMode.title)已完成"
        }
    }

    private var emptyDescription: String {
        switch engine.currentMode {
        case .daily:
            return "可以继续自由学习，或去词库查看已学和收藏单词。"
        case .free:
            return "可以返回今日页，再次点自由学习继续。"
        default:
            return "可以返回上一页选择其他学习模式。"
        }
    }

    private func tint(for rating: ReviewRating) -> Color {
        switch rating {
        case .forgot:
            return .red
        case .vague:
            return .orange
        case .known, .mastered:
            return .green
        }
    }
}
