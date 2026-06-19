import SwiftUI

struct StatsView: View {
    @ObservedObject var engine: StudyEngine

    var body: some View {
        NavigationStack {
            let stats = engine.stats()
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("掌握率")
                            Spacer()
                            Text("\(Int(stats.masteryRate * 100))%")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.indigo)
                        }
                        ProgressView(value: stats.masteryRate)
                            .tint(.indigo)
                    }
                    .panelStyle()

                    statRow("总词数", "\(stats.totalWords)", icon: "books.vertical")
                    statRow("未学单词", "\(stats.unlearnedWords)", icon: "circle")
                    statRow("已学单词", "\(stats.studiedWords)", icon: "checkmark.circle")
                    statRow("学习中", "\(stats.learningWords)", icon: "book.pages")
                    statRow("已掌握", "\(stats.masteredWords)", icon: "star.circle")
                    statRow("待复习", "\(stats.dueWords)", icon: "clock")
                    statRow("错题单词", "\(stats.weakWords)", icon: "exclamationmark.circle")
                    statRow("收藏数", "\(stats.favoriteWords)", icon: "star")
                    statRow("今日已复习", "\(stats.reviewedToday)", icon: "calendar")
                    statRow("连续学习", "\(stats.studyStreak) 天", icon: "flame")

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("今日完成率")
                            Spacer()
                            Text("\(Int(stats.todayCompletionRate * 100))%")
                                .fontWeight(.bold)
                        }
                        ProgressView(value: stats.todayCompletionRate)
                            .tint(.indigo)
                    }
                    .panelStyle()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("统计")
        }
    }

    private func statRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.indigo)
        }
        .panelStyle()
    }
}
