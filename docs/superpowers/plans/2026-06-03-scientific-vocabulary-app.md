# Scientific Vocabulary App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the CET vocabulary app from a simple word list and flashcard app into a fuller study app with complete browsing, study plans, spaced review, weak-word practice, quiz modes, progress tracking, and clearer settings.

**Architecture:** Keep the existing SwiftUI app structure and add one pure Foundation policy file for testable scheduling logic. Use `StudyEngine` as the bridge between stored progress, settings, and views. Add a focused quiz view instead of rewriting all screens.

**Tech Stack:** Swift, SwiftUI, Foundation, local txt vocabulary resources, JSON progress file.

---

### Task 1: Study Policy Core

**Files:**
- Create: `CETWords/LearningPolicy.swift`
- Create: `tools/check_learning_policy.swift`
- Modify: `CETWords/StudyEngine.swift`
- Modify: `CETWords.xcodeproj/project.pbxproj`

- [x] **Step 1: Write a failing logic check**

Create `tools/check_learning_policy.swift` that calls `LearningPolicy.nextReviewDate` and `LearningPolicy.buildDailyTask`.

- [ ] **Step 2: Run the check and verify it fails**

Run:

```bash
swiftc CETWords/Models.swift CETWords/LearningPolicy.swift tools/check_learning_policy.swift -o /tmp/check_learning_policy
```

Expected: failure because `LearningPolicy.swift` is not implemented yet.

- [ ] **Step 3: Implement the policy**

Add a plain Swift enum with interval and task-mixing functions.

- [ ] **Step 4: Run the check and verify it passes**

Run:

```bash
swiftc CETWords/Models.swift CETWords/LearningPolicy.swift tools/check_learning_policy.swift -o /tmp/check_learning_policy && /tmp/check_learning_policy
```

Expected: prints `LearningPolicy checks passed`.

### Task 2: Complete Library Browsing

**Files:**
- Modify: `CETWords/StudyEngine.swift`
- Modify: `CETWords/Views/LibraryView.swift`
- Modify: `CETWords/Models.swift`

- [ ] **Step 1: Remove the fixed first-300 result cap**

Return the complete filtered list when there is no search query.

- [ ] **Step 2: Add visible count and stronger filters**

Show filtered count and add a mastered filter.

### Task 3: Mature Study Flow

**Files:**
- Modify: `CETWords/Models.swift`
- Modify: `CETWords/StudyEngine.swift`
- Modify: `CETWords/Views/WordCardView.swift`
- Modify: `CETWords/Views/TodayView.swift`
- Modify: `CETWords/Views/ReviewView.swift`

- [ ] **Step 1: Add study session modes**

Use daily, review, weak, and quiz modes.

- [ ] **Step 2: Use mixed task queues**

Daily study should combine due review, weak words, and new words.

- [ ] **Step 3: Make card feedback explain the next review**

Show what each rating means.

### Task 4: Quiz And Weak-Word Practice

**Files:**
- Create: `CETWords/Views/QuizView.swift`
- Modify: `CETWords/StudyEngine.swift`
- Modify: `CETWords/ContentView.swift`
- Modify: `CETWords.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add multiple-choice recognition**

Show one English word and four Chinese meaning options.

- [ ] **Step 2: Add spelling recall**

Show Chinese meaning and require typing the English word.

- [ ] **Step 3: Rate answers automatically**

Correct answers count as known. Wrong answers count as forgot.

### Task 5: Progress, Streak, And Settings

**Files:**
- Modify: `CETWords/ProgressStore.swift`
- Modify: `CETWords/Models.swift`
- Modify: `CETWords/Views/StatsView.swift`
- Modify: `CETWords/Views/SettingsView.swift`

- [ ] **Step 1: Persist active study days**

Track days where at least one word was completed.

- [ ] **Step 2: Show word-book progress**

Display total, studied, mastered, weak, due, and streak.

- [ ] **Step 3: Add plan controls**

Expose daily target, scope, review priority, and quiz reminder text.

### Task 6: Verification

**Files:**
- All changed Swift files

- [ ] **Step 1: Run logic check**

Run:

```bash
swiftc CETWords/Models.swift CETWords/LearningPolicy.swift tools/check_learning_policy.swift -o /tmp/check_learning_policy && /tmp/check_learning_policy
```

- [ ] **Step 2: Run Xcode build**

Run:

```bash
xcodebuild -project CETWords.xcodeproj -scheme CETWords -configuration Debug -destination 'generic/platform=iOS' build
```

Use a writable derived data path if the default Xcode cache is blocked.
