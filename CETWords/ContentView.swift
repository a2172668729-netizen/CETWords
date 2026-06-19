import SwiftUI

struct ContentView: View {
    @StateObject private var settings: AppSettings
    @StateObject private var progressStore: ProgressStore
    @StateObject private var studyEngine: StudyEngine

    init() {
        let settings = AppSettings()
        let progressStore = ProgressStore()
        _settings = StateObject(wrappedValue: settings)
        _progressStore = StateObject(wrappedValue: progressStore)
        _studyEngine = StateObject(wrappedValue: StudyEngine(progressStore: progressStore, settings: settings))
    }

    var body: some View {
        TabView {
            TodayView(engine: studyEngine, settings: settings)
                .tabItem { Label("今日", systemImage: "sun.max") }

            ReviewView(engine: studyEngine)
                .tabItem { Label("复习", systemImage: "clock.arrow.circlepath") }
                .badge(studyEngine.dueReviewWords.count)

            LibraryView(engine: studyEngine, settings: settings)
                .tabItem { Label("词库", systemImage: "books.vertical") }

            QuizView(engine: studyEngine)
                .tabItem { Label("测验", systemImage: "checklist") }

            StatsView(engine: studyEngine)
                .tabItem { Label("统计", systemImage: "chart.bar") }

            SettingsView(engine: studyEngine, settings: settings, progressStore: progressStore)
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .tint(.indigo)
    }
}
