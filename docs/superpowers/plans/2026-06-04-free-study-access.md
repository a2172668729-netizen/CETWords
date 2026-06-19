# Free Study Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add a free study mode, make learned/favorite word lists easy to open, and stabilize settings-related task rebuilding.

**Architecture:** Keep the existing SwiftUI structure. Add one new `StudySessionMode.free`, one pure policy builder for free study tasks, and small UI entry points that reuse the existing `LibraryView` filters. Fix malformed sheet/toolbar structure in Today and Review before adding new buttons.

**Tech Stack:** Swift 5, SwiftUI, Foundation, existing `swiftc` policy check script.

---

## File Structure

- Modify `CETWords/Models.swift`: add the new `free` study mode title.
- Modify `CETWords/LearningPolicy.swift`: add pure free-study task building.
- Modify `CETWords/StudyEngine.swift`: add `rebuildFreeStudyTask()` and call the new policy builder.
- Modify `CETWords/Views/TodayView.swift`: fix sheet nesting, add free study and list entry buttons.
- Modify `CETWords/Views/ReviewView.swift`: fix sheet nesting and use free study for "继续学习新词".
- Modify `CETWords/Views/StatsView.swift`: make unlearned/learned/favorite rows clear navigation entries.
- Modify `tools/check_learning_policy.swift`: add tests for free study behavior.

## Task 1: Add Free Study Policy Tests

**Files:**
- Modify: `tools/check_learning_policy.swift`
- Test: `tools/check_learning_policy.swift`

- [x] **Step 1: Add failing free-study checks**

Add this block after the existing daily-task checks and before `print("LearningPolicy checks passed")`:

```swift
        let freeTask = LearningPolicy.buildFreeStudyTask(
            dueReviewWords: due,
            weakWords: weak,
            newWords: fresh,
            learnedWords: sampleWords(prefix: "learned", count: 6),
            limit: 14
        )

        assertCondition(freeTask.count == 14, "free study should fill the requested limit when enough words exist")
        assertCondition(freeTask.prefix(8).map(\.word) == fresh.map(\.word), "free study should prefer unlearned words first")
        assertCondition(freeTask.contains(where: { $0.word == "due-1" }), "free study should include due words after new words")
        assertCondition(freeTask.contains(where: { $0.word == "weak-1" }), "free study should include weak words after new words")
```

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
swiftc -parse-as-library -module-cache-path DerivedData/ModuleCache.noindex CETWords/Models.swift CETWords/LearningPolicy.swift tools/check_learning_policy.swift -o /private/tmp/check_learning_policy
```

Expected: compilation fails with `type 'LearningPolicy' has no member 'buildFreeStudyTask'`.

## Task 2: Implement Free Study Mode in Core Logic

**Files:**
- Modify: `CETWords/Models.swift`
- Modify: `CETWords/LearningPolicy.swift`
- Modify: `CETWords/StudyEngine.swift`
- Test: `tools/check_learning_policy.swift`

- [x] **Step 1: Add `free` to `StudySessionMode`**

In `CETWords/Models.swift`, update the enum:

```swift
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
```

- [x] **Step 2: Add pure free-study task builder**

In `CETWords/LearningPolicy.swift`, add this function near the other task builders:

```swift
    static func buildFreeStudyTask(
        dueReviewWords: [WordEntry],
        weakWords: [WordEntry],
        newWords: [WordEntry],
        learnedWords: [WordEntry],
        limit: Int
    ) -> [WordEntry] {
        let target = min(max(limit, 1), 100)
        return stableUnique(Array((newWords + dueReviewWords + weakWords + learnedWords).prefix(target)))
    }
```

- [x] **Step 3: Wire free study into `StudyEngine`**

In `CETWords/StudyEngine.swift`, add:

```swift
    func rebuildFreeStudyTask() {
        rebuildTask(mode: .free)
    }
```

Then update `rebuildTask(mode:)`:

```swift
        reviewOnly = mode == .review || mode == .weak
```

stays unchanged, and add a `case .free`:

```swift
        case .free:
            let learned = scoped.filter { progressStore.progress(for: $0).seenCount > 0 }
            currentTask = LearningPolicy.buildFreeStudyTask(
                dueReviewWords: due,
                weakWords: weakNotDue,
                newWords: new,
                learnedWords: learned,
                limit: max(target, 50)
            )
```

- [x] **Step 4: Run the policy check**

Run:

```bash
swiftc -parse-as-library -module-cache-path DerivedData/ModuleCache.noindex CETWords/Models.swift CETWords/LearningPolicy.swift tools/check_learning_policy.swift -o /private/tmp/check_learning_policy
/private/tmp/check_learning_policy
```

Expected: `LearningPolicy checks passed`.

## Task 3: Fix Study Sheet Structure

**Files:**
- Modify: `CETWords/Views/TodayView.swift`
- Modify: `CETWords/Views/ReviewView.swift`

- [x] **Step 1: Fix `TodayView` sheet/toolbar braces**

Replace the two sheet blocks in `TodayView` with:

```swift
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
```

Also remove any extra closing brace after the `TodayView` struct.

- [x] **Step 2: Fix `ReviewView` sheet/toolbar braces**

Replace the two sheet blocks in `ReviewView` with:

```swift
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
```

Also ensure `emptyDescription` remains inside `ReviewView`.

## Task 4: Add Free Study and List Entry Buttons

**Files:**
- Modify: `CETWords/Views/TodayView.swift`
- Modify: `CETWords/Views/ReviewView.swift`
- Modify: `CETWords/Views/StatsView.swift`

- [x] **Step 1: Add Today free-study button**

In `TodayView`, add this button after "开始今日学习":

```swift
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
```

- [x] **Step 2: Add Today list shortcuts**

In the Today screen, add a compact section below the progress panels:

```swift
                    VStack(alignment: .leading, spacing: 10) {
                        Label("单词列表", systemImage: "list.bullet")
                            .font(.headline)

                        NavigationLink {
                            LibraryView(engine: engine, settings: settings, initialFilter: .unlearned)
                        } label: {
                            StatPill(title: "未学", value: "\(stats.unlearnedWords)", tint: .gray)
                        }

                        NavigationLink {
                            LibraryView(engine: engine, settings: settings, initialFilter: .learned)
                        } label: {
                            StatPill(title: "已学", value: "\(stats.studiedWords)", tint: .green)
                        }

                        NavigationLink {
                            LibraryView(engine: engine, settings: settings, initialFilter: .favorite)
                        } label: {
                            StatPill(title: "收藏", value: "\(stats.favoriteWords)", tint: .yellow)
                        }
                    }
                    .buttonStyle(.plain)
                    .panelStyle()
```

- [x] **Step 3: Use free study from Review empty state**

In `ReviewView`, change the "继续学习新词" action:

```swift
                        Button {
                            engine.rebuildFreeStudyTask()
                            showingReview = true
                        } label: {
                            Label("继续自由学习", systemImage: "infinity")
                        }
```

- [x] **Step 4: Make Stats unlearned row navigable**

In `StatsView`, replace the plain unlearned row with:

```swift
                    NavigationLink {
                        LibraryView(engine: engine, settings: engine.settings, initialFilter: .unlearned)
                    } label: {
                        statRow("未学单词", "\(stats.unlearnedWords)", icon: "circle")
                    }
                    .buttonStyle(.plain)
```

Keep the existing learned and favorite navigation rows.

## Task 5: Verify Settings Apply Flow

**Files:**
- Modify only if needed: `CETWords/Views/SettingsView.swift`

- [x] **Step 1: Inspect settings apply flow after sheet fixes**

Confirm `SettingsView` still calls:

```swift
                        settings.apply(
                            dailyNewWordTarget: draftDailyGoal,
                            wordScope: draftScope,
                            prioritizeReview: draftPrioritizeReview,
                            showMeaningAfterFlip: draftShowMeaningAfterFlip
                        )
                        engine.rebuildTodayTask()
```

No code change is needed if this still compiles after the sheet fixes and does not mutate state from a background thread.

- [x] **Step 2: Run source-level checks**

Run:

```bash
swiftc -parse-as-library -module-cache-path DerivedData/ModuleCache.noindex CETWords/Models.swift CETWords/LearningPolicy.swift tools/check_learning_policy.swift -o /private/tmp/check_learning_policy
/private/tmp/check_learning_policy
```

Expected: `LearningPolicy checks passed`.

- [x] **Step 3: Attempt full Xcode build**

Run:

```bash
xcodebuild -project CETWords.xcodeproj -scheme CETWords -destination 'generic/platform=iOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

Expected if local Xcode services are healthy: build succeeds. If it fails with CoreSimulator or asset catalog runtime errors, record that as an environment blocker and include the exact reason in the final report.

## Self-Review

Spec coverage:

- Free study mode is covered by Tasks 1, 2, and 4.
- Today's target semantics are preserved because daily task code remains target-limited and free study is separate.
- Learned/favorite/unlearned entry points are covered by Task 4.
- Settings stability is covered by Tasks 3 and 5.
- Verification is covered by Tasks 1, 2, and 5.

Completion marker scan:

- No unfinished markers are present.
- Each implementation step names the exact file and code shape.

Type consistency:

- `StudySessionMode.free`, `LearningPolicy.buildFreeStudyTask(...)`, and `StudyEngine.rebuildFreeStudyTask()` are named consistently across tasks.
