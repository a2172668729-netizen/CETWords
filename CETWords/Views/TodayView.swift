import SwiftUI

struct TodayView: View {
    @ObservedObject var engine: StudyEngine
    @ObservedObject var settings: AppSettings
    @State private var showingStudy = false
    @State private var showingQuiz = false

    var body: some View {
        NavigationStack {
            let stats = engine.stats()
            let collectionStats = engine.collectionStats(for: settings.selectedCollectionID)
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("词库 \(settings.selectedCollectionID)")
                                    .font(.title2.weight(.bold))
                                Text("今日目标 \(settings.dailyNewWordTarget)")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(stats.todayCompleted)/\(max(stats.todayTarget, 1))")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.indigo)
                        }

                        ProgressView(value: stats.todayCompletionRate)
                            .tint(.indigo)

                        HStack(spacing: 10) {
                            StatPill(title: "待复习", value: "\(stats.dueWords)", tint: .red)
                            StatPill(title: "错题", value: "\(stats.weakWords)", tint: .orange)
                            StatPill(title: "已完成", value: "\(stats.todayCompleted)", tint: .green)
                        }
                        Text("今日任务会先安排到期复习，再穿插错题，最后补新词。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .panelStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("当前小词库进度", systemImage: "books.vertical")
                                .font(.headline)
                            Spacer()
                            Text("\(collectionStats.masteredWords)/\(collectionStats.totalWords)")
                                .font(.headline)
                                .foregroundStyle(.indigo)
                        }

                        ProgressView(value: collectionStats.completionRate)
                            .tint(.green)

                        HStack(spacing: 10) {
                            StatPill(title: "未掌握", value: "\(collectionStats.unmasteredWords)", tint: .red)
                            StatPill(title: "待强化", value: "\(collectionStats.reinforceWords)", tint: .yellow)
                            StatPill(title: "已掌握", value: "\(collectionStats.masteredWords)", tint: .green)
                        }

                        HStack(spacing: 10) {
                            StatPill(title: "全部已学", value: "\(stats.studiedWords)", tint: .blue)
                            StatPill(title: "连续", value: "\(stats.studyStreak) 天", tint: .green)
                        }
                    }
                    .panelStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        NavigationLink {
                            CollectionDetailView(
                                collectionID: settings.selectedCollectionID,
                                engine: engine,
                                settings: settings
                            )
                        } label: {
                            Label("查看词库 \(settings.selectedCollectionID) 的全部单词", systemImage: "list.bullet")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .panelStyle()

                    Button {
                        engine.rebuildTodayTask()
                        showingStudy = true
                    } label: {
                        Label("开始今日学习", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    Button {
                        engine.rebuildFreeStudyTask()
                        showingStudy = true
                    } label: {
                        Label(stats.todayCompleted >= stats.todayTarget ? "继续自由学习" : "自由学习", systemImage: "infinity")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        engine.rebuildTodayTask(reviewOnly: true)
                        showingStudy = true
                    } label: {
                        Label("复习到期词", systemImage: "clock")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        engine.rebuildTodayTask(weakOnly: true)
                        showingStudy = true
                    } label: {
                        Label("错题强化", systemImage: "exclamationmark.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(stats.weakWords == 0)

                    Button {
                        engine.rebuildQuizTask()
                        showingQuiz = true
                    } label: {
                        Label("测验模式", systemImage: "checklist")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今日")
            .sheet(isPresented: $showingStudy) {
                NavigationStack {
                    WordCardView(engine: engine)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("完成") { showingStudy = false }
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
}

struct StatPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.headline)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension View {
    func panelStyle() -> some View {
        padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
