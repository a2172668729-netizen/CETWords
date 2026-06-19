import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine: StudyEngine
    @ObservedObject var settings: AppSettings
    @ObservedObject var progressStore: ProgressStore
    @State private var showingResetAlert = false
    @State private var backupMessage: String?
    @State private var draftDailyGoal: Int
    @State private var draftCollectionID: Int
    @State private var draftPrioritizeReview: Bool
    @State private var draftShowMeaningAfterFlip: Bool

    init(engine: StudyEngine, settings: AppSettings, progressStore: ProgressStore) {
        self.engine = engine
        self.settings = settings
        self.progressStore = progressStore
        _draftDailyGoal = State(initialValue: settings.dailyNewWordTarget)
        _draftCollectionID = State(initialValue: settings.selectedCollectionID)
        _draftPrioritizeReview = State(initialValue: settings.prioritizeReview)
        _draftShowMeaningAfterFlip = State(initialValue: settings.showMeaningAfterFlip)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("学习设置") {
                    Stepper(value: $draftDailyGoal, in: 5...100, step: 5) {
                        Text("每日新词 \(draftDailyGoal)")
                    }

                    Picker("当前小词库", selection: $draftCollectionID) {
                        ForEach(1...20, id: \.self) { collectionID in
                            Text("词库 \(collectionID)").tag(collectionID)
                        }
                    }

                    Toggle("优先复习", isOn: $draftPrioritizeReview)
                    Toggle("翻卡后显示中文释义", isOn: $draftShowMeaningAfterFlip)

                    Button("应用设置") {
                        settings.apply(
                            dailyNewWordTarget: draftDailyGoal,
                            selectedCollectionID: draftCollectionID,
                            prioritizeReview: draftPrioritizeReview,
                            showMeaningAfterFlip: draftShowMeaningAfterFlip
                        )
                        engine.rebuildTodayTask()
                    }
                }

                Section("学习机制") {
                    Label("今日任务：到期复习、错题强化、新词补位", systemImage: "calendar")
                    Label("测验模式：选择释义和拼写回忆交替出现", systemImage: "checklist")
                    Label("答错：10 分钟后再出现；模糊：明天复习；认识：逐步拉长间隔", systemImage: "clock.arrow.circlepath")
                }

                Section("进度") {
                    Button("导出进度备份") {
                        if let url = progressStore.exportBackup() {
                            backupMessage = "已导出：\(url.lastPathComponent)"
                        } else {
                            backupMessage = progressStore.lastErrorMessage ?? "导出失败"
                        }
                    }

                    Button("重置学习进度", role: .destructive) {
                        showingResetAlert = true
                    }
                }

                Section("词库说明") {
                    Text("四级和六级来源词汇已合并去重，并固定乱序分为 20 个小词库。")
                        .font(.footnote)
                    Text("基于公开整理词库，覆盖常见 CET4/CET6 词汇，非官方授权词库。")
                        .font(.footnote)
                    Text("普通关闭 App 不会丢进度；删除 App 或修改 Bundle Identifier 可能导致本地进度不可见。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let backupMessage {
                    Section {
                        Text(backupMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .onAppear {
                draftDailyGoal = settings.dailyNewWordTarget
                draftCollectionID = settings.selectedCollectionID
                draftPrioritizeReview = settings.prioritizeReview
                draftShowMeaningAfterFlip = settings.showMeaningAfterFlip
            }
            .alert("确认重置进度？", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) {}
                Button("重置", role: .destructive) {
                    progressStore.resetAllProgress()
                    engine.rebuildTodayTask()
                }
            } message: {
                Text("这会清空所有学习记录、收藏和复习安排。")
            }
        }
    }
}
