import SwiftUI

struct LibraryView: View {
    @ObservedObject var engine: StudyEngine
    @ObservedObject var settings: AppSettings

    var body: some View {
        NavigationStack {
            List(engine.collections) { collection in
                NavigationLink {
                    CollectionDetailView(collectionID: collection.id, engine: engine, settings: settings)
                } label: {
                    CollectionSummaryRow(
                        collection: collection,
                        stats: engine.collectionStats(for: collection.id),
                        isSelected: settings.selectedCollectionID == collection.id
                    )
                }
            }
            .navigationTitle("20 个小词库")
        }
    }
}

struct CollectionSummaryRow: View {
    let collection: VocabularyCollection
    let stats: VocabularyCollectionStats
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(collection.displayName)
                    .font(.headline)
                if isSelected {
                    Text("当前词库")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.indigo)
                }
                Spacer()
                Text("\(stats.totalWords) 词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: stats.completionRate)
                .tint(.green)

            HStack(spacing: 8) {
                StatusCountLabel(status: .unmastered, count: stats.unmasteredWords)
                StatusCountLabel(status: .reinforce, count: stats.reinforceWords)
                StatusCountLabel(status: .mastered, count: stats.masteredWords)
            }
        }
        .padding(.vertical, 5)
    }
}

struct CollectionDetailView: View {
    let collectionID: Int
    @ObservedObject var engine: StudyEngine
    @ObservedObject var settings: AppSettings
    @State private var searchText = ""
    @State private var filter: LibraryFilter = .all
    @State private var showingStudy = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        settings.selectedCollectionID = collectionID
                        engine.rebuildTodayTask()
                    } label: {
                        Label(
                            settings.selectedCollectionID == collectionID ? "当前词库" : "设为当前词库",
                            systemImage: settings.selectedCollectionID == collectionID ? "checkmark.circle.fill" : "circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(settings.selectedCollectionID == collectionID)

                    Button {
                        engine.rebuildCollectionStudyTask(collectionID: collectionID)
                        showingStudy = true
                    } label: {
                        Label("开始学习", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }

                HStack {
                    Picker("状态", selection: $filter) {
                        ForEach(LibraryFilter.allCases) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    Spacer()
                    Text("\(filteredWords.count) 个")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            List(filteredWords) { word in
                NavigationLink {
                    WordDetailView(entry: word, engine: engine)
                } label: {
                    WordRow(entry: word, engine: engine)
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜索单词或释义")
        .navigationTitle("词库 \(collectionID)")
        .navigationBarTitleDisplayMode(.inline)
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
    }

    private var filteredWords: [WordEntry] {
        engine.filteredWords(collectionID: collectionID, filter: filter, query: searchText)
    }
}

struct WordRow: View {
    let entry: WordEntry
    @ObservedObject var engine: StudyEngine

    var body: some View {
        let progress = engine.progressStore.progress(for: entry)
        let status = engine.displayStatus(for: entry)
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(entry.word)
                    .font(.headline)
                Spacer()
                StatusBadge(status: status)
                if progress.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            Text(entry.primaryMeaning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 12) {
                Text("学习 \(progress.seenCount) 次")
                Text(nextReviewText(progress.nextReviewAt))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func nextReviewText(_ date: Date?) -> String {
        guard let date else { return "暂无复习安排" }
        if date <= .now { return "待复习" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "下次 \(formatter.string(from: date))"
    }
}

struct StatusBadge: View {
    let status: WordDisplayStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.bold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.12), in: Capsule())
    }
}

struct StatusCountLabel: View {
    let status: WordDisplayStatus
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 7, height: 7)
            Text("\(status.displayName) \(count)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

extension WordDisplayStatus {
    var color: Color {
        switch self {
        case .unmastered:
            return .red
        case .reinforce:
            return .yellow
        case .mastered:
            return .green
        }
    }
}
