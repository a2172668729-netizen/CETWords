import SwiftUI

struct ReviewView: View {
    @ObservedObject var engine: StudyEngine
    @State private var showingReview = false
    @State private var showingQuiz = false

    var body: some View {
        NavigationStack {
            List {
                if engine.dueReviewWords.isEmpty {
                    Section {
                        ContentUnavailableView("暂无到期复习", systemImage: "checkmark.circle", description: Text(emptyDescription))
                    }
                    Section {
                        Button {
                            engine.rebuildTodayTask(weakOnly: true)
                            showingReview = true
                        } label: {
                            Label("错题强化", systemImage: "exclamationmark.circle")
                        }
                        .disabled(engine.weakReviewWords.isEmpty)

                        Button {
                            engine.rebuildFreeStudyTask()
                            showingReview = true
                        } label: {
                            Label("继续自由学习", systemImage: "infinity")
                        }
                    }
                    Section {
                        Button {
                            engine.rebuildQuizTask()
                            showingQuiz = true
                        } label: {
                            Label("测验模式", systemImage: "checklist")
                        }
                    }
                } else {
                    Section {
                        Text("这些词是系统根据你上次选择的不认识/模糊/认识自动安排的复习词。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("到期复习：\(engine.dueReviewWords.count) 个")
                            .font(.headline)
                    }
                    Section {
                        Button {
                            engine.rebuildTodayTask(reviewOnly: true)
                            showingReview = true
                        } label: {
                            Label("开始复习 \(engine.dueReviewWords.count) 个词", systemImage: "play.fill")
                                .font(.headline)
                        }
                    }

                    Section("到期词") {
                        ForEach(engine.dueReviewWords.prefix(100)) { word in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(word.word)
                                    .font(.headline)
                                Text(word.primaryMeaning)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("错题强化") {
                        Button {
                            engine.rebuildTodayTask(weakOnly: true)
                            showingReview = true
                        } label: {
                            Label("强化 \(engine.weakReviewWords.count) 个错题", systemImage: "exclamationmark.circle")
                        }
                        .disabled(engine.weakReviewWords.isEmpty)
                    }

                    Section("测验") {
                        Button {
                            engine.rebuildQuizTask()
                            showingQuiz = true
                        } label: {
                            Label("选择 + 拼写测验", systemImage: "checklist")
                        }
                    }
                }
            }
            .navigationTitle("复习")
            .sheet(isPresented: $showingReview) {
                NavigationStack {
                    WordCardView(engine: engine)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("完成") { showingReview = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingQuiz) {
                NavigationStack {
                    QuizView(engine: engine)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("完成") { showingQuiz = false }
                            }
                        }
                }
            }
        }
    }

    private var emptyDescription: String {
        let base = "复习时间由系统根据你上次选择的不认识/模糊/认识自动安排。"
        guard let next = engine.nextDueDate else { return base }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(base)\n下一批复习预计在：\(formatter.string(from: next))"
    }
}
